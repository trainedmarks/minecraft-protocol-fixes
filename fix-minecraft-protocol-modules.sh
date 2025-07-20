#!/bin/bash

# Defines the base path for node_modules as the current directory where the script is run.
PROJECT_ROOT=$(pwd)

# Defines full paths to the target files within node_modules.
CHAT_JS_PATH="${PROJECT_ROOT}/node_modules/minecraft-protocol/src/client/chat.js"
KEEP_ALIVE_JS_PATH="${PROJECT_ROOT}/node_modules/minecraft-protocol/src/client/keepAlive.js"

# Defines paths for backup copies.
CHAT_JS_BACKUP_PATH="${CHAT_JS_PATH}.bak"
KEEP_ALIVE_JS_BACKUP_PATH="${KEEP_ALIVE_JS_PATH}.bak"

echo "Starting automated fixes for minecraft-protocol files."
echo "Running from: ${PROJECT_ROOT}"
echo "--------------------------------------------------------"

# --- Fix chat.js ---
echo "Attempting to fix chat.js..."

# Checks if chat.js exists before proceeding.
if [ ! -f "$CHAT_JS_PATH" ]; then
  echo "Error: chat.js not found at '${CHAT_JS_PATH}'. Skipping fix for chat.js."
else
  echo "Backing up chat.js to: ${CHAT_JS_BACKUP_PATH}"
  # Creates a backup of the original chat.js file.
  cp "$CHAT_JS_PATH" "$CHAT_JS_BACKUP_PATH"

  echo "Applying fix for Buffer.concat in updateAndValidateSession (chat.js)..."
  # Applies the filter(Boolean) fix to line 63 in chat.js.
  sed -i '63s/\.map(msg => msg.signature || client._signatureCache[msg.id]))/\.map(msg => msg.signature || client._signatureCache[msg.id]).filter(Boolean))/g' "$CHAT_JS_PATH"

  echo "Applying fix for Buffer.concat in client.signMessage (chat.js)..."
  # Applies the filter(Boolean) fix within the client.signMessage function.
  sed -i '/Buffer.concat(acknowledgements)]/s/Buffer.concat(acknowledgements)]/Buffer.concat(acknowledgements.filter(Boolean))]/g' "$CHAT_JS_PATH"

  echo "Verifying changes in chat.js:"
  # Verifies the applied changes by searching for 'filter(Boolean)'.
  grep -C 5 "filter(Boolean)" "$CHAT_JS_PATH" || echo "No 'filter(Boolean)' found in chat.js. Check for errors."
  echo "chat.js fix complete."
fi

echo "--------------------------------------------------------"

# --- Fix keepAlive.js ---
echo "Attempting to fix keepAlive.js..."

# Checks if keepAlive.js exists before proceeding.
if [ ! -f "$KEEP_ALIVE_JS_PATH" ]; then
  echo "Error: keepAlive.js not found at '${KEEP_ALIVE_JS_PATH}'. Skipping fix for keepAlive.js."
else
  echo "Backing up keepAlive.js to: ${KEEP_ALIVE_JS_BACKUP_PATH}"
  # Creates a backup of the original keepAlive.js file.
  cp "$KEEP_ALIVE_JS_PATH" "$KEEP_ALIVE_JS_BACKUP_PATH"

  echo "Applying keepAlive.js improvements..."
  # Inserts 'use strict' at the top if not already present.
  if ! head -n 1 "$KEEP_ALIVE_JS_PATH" | grep -q "'use strict';" ; then
    sed -i '1i\'\''use strict'\';''\n' "$KEEP_ALIVE_JS_PATH"
  fi

  # Inserts default options for checkTimeoutInterval and sendKeepAliveInterval.
  sed -i "/const keepAliveEnabled = options.keepAlive == null ? true : options.keepAlive;/a \ \n  // The duration after which the client will be considered timed out\n  // if no keep_alive packet is received from the server.\n  const checkTimeoutInterval = options.checkTimeoutInterval || 30 * 1000; // Default: 30 seconds\n\n  // The interval at which the client will send keep_alive packets to the server.\n  // This should be less than checkTimeoutInterval to ensure the client\n  // proactively keeps the connection alive from its side.\n  const sendKeepAliveInterval = options.sendKeepAliveInterval || 15 * 1000; // Default: 15 seconds" "$KEEP_ALIVE_JS_PATH"

  # Modifies the 'keep_alive' listener for incoming timeout handling.
  sed -i '/client.on('"'"'keep_alive'"'"', (packet) => {/ {
    N
    s/client.on('"'"'keep_alive'"'"', (packet) => {\n    // Respond immediately to the server'\''s keep_alive packet with the same ID/client.on('"'"'keep_alive'"'"', (packet) => {\n    // Clear any existing timeout, as a keep_alive was just received\n    if (incomingKeepAliveTimeout) {\n      clearTimeout(incomingKeepAliveTimeout);\n    }\n\n    // Set a new timeout. If this expires, the server is unresponsive.\n    incomingKeepAliveTimeout = setTimeout(() => {\n      client.emit('"'"'error'"'"', new Error(\`Client timed out: No keep_alive received from server within \$\{checkTimeoutInterval\}ms.\`));\n      client.end('"'"'keepAliveTimeout'"'"'); // Disconnect the client\n    }, checkTimeoutInterval);\n\n    // Respond immediately to the server'\''s keep_alive packet with the same ID/
  }' "$KEEP_ALIVE_JS_PATH"

  # Modifies client.on('connect') to clear and set outgoing interval.
  sed -i "/client.on('connect', () => {/ {
    N
    s/client.on('connect', () => {\n    // Set a new interval to periodically send keep_alive packets/client.on('connect', () => {\n    // Clear any previous interval to avoid multiple intervals running\n    if (outgoingKeepAliveInterval) {\n      clearInterval(outgoingKeepAliveInterval);\n    }\n    // Set a new interval to periodically send keep_alive packets/
  }" "$KEEP_ALIVE_JS_PATH"

  # Adds cleanup for timers on 'end' or 'error' events.
  sed -i "/client.on('error', clearKeepAliveTimers);/a \ \n  const clearKeepAliveTimers = () => {\n    if (incomingKeepAliveTimeout) {\n      clearTimeout(incomingKeepAliveTimeout);\n      incomingKeepAliveTimeout = null;\n    }\n    if (outgoingKeepAliveInterval) {\n      clearInterval(outgoingKeepAliveInterval);\n      outgoingKeepAliveInterval = null;\n    }\n    // console.log('[KeepAlive] Timers cleared.'); // For debugging\n  };\n\n  client.on('end', clearKeepAliveTimers);" "$KEEP_ALIVE_JS_PATH"

  # Initializes timeout variables.
  sed -i '/const sendKeepAliveInterval = options.sendKeepAliveInterval || 15 \* 1000; \/\/ Default: 15 seconds;/a \ \n  let incomingKeepAliveTimeout = null; // Manages timeout for server'\''s keep_alive\n  let outgoingKeepAliveInterval = null; // Manages interval for sending client'\''s keep_alive' "$KEEP_ALIVE_JS_PATH"

  echo "Verifying changes in keepAlive.js:"
  # Verifies the applied changes in keepAlive.js.
  grep -C 5 "incomingKeepAliveTimeout" "$KEEP_ALIVE_JS_PATH" || echo "No 'incomingKeepAliveTimeout' found. Check keepAlive.js for errors."
  grep -C 5 "outgoingKeepAliveInterval" "$KEEP_ALIVE_JS_PATH" || echo "No 'outgoingKeepAliveInterval' found. Check keepAlive.js for errors."
  echo "keepAlive.js fix complete."
fi

echo "--------------------------------------------------------"
echo "All automated fix attempts complete."
echo "Please restart your Node.js application to apply the changes."
