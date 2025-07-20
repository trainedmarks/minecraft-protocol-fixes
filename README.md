# Minecraft Protocol Fixes

This script provides immediate solutions for two common issues in Node.js Minecraft bots. Apply these fixes quickly, without waiting for an official update, and keep your bots running smoothly.

## What Does This Script Address?

**chat.js Fixes**  
- Resolves the error:  
  TypeError: Cannot read properties of undefined (reading 'length')  
  This error can occur during chat operations, such as sending whispers or commands, when the previousMessages array is undefined or empty.
- The script safeguards chat processing to prevent this type of crash.

**keepAlive.js Improvements**  
- Improves connection reliability by adding configurable options: checkTimeoutInterval and sendKeepAliveInterval.
- Implements server-side timeout detection for incoming keep_alive packets.
- Enhances management and cleanup of client-side keep_alive intervals.
- Adds 'use strict'; for better code quality.

## Important Considerations

**Compatibility:**  
This script is designed for Linux-based systems, including environments with a Bash shell. It will also work on Windows Subsystem for Linux (WSL) and macOS.

**Temporary Solution:**  
These fixes are applied directly to your local node_modules folder. Be aware that running npm install, yarn install, or updating dependencies will likely overwrite these changes.

**Automatic Backups:**  
For safety, the script automatically creates backup copies of the original chat.js and keepAlive.js files (with a .bak extension) before making any changes.

## How to Use

1. Save the Script  
   Copy the script into a new file named fix-minecraft-protocol-modules.sh.

2. Place the Script  
   Move this file to the root directory of your Node.js project (where your node_modules folder is located).

3. Make It Executable  
   Open your terminal, navigate to your project’s root directory, and run:  
   chmod +x fix-minecraft-protocol-modules.sh

4. Run the Script  
   From the same directory, execute:  
   ./fix-minecraft-protocol-modules.sh  
   The script will display its progress and confirm successful application of the fixes.

5. Restart Your Application  
   Restart your Node.js application for the changes to take effect.

## Verifying Changes

- For chat.js:  
  Look for .filter(Boolean) after previousMessages.map(...) and within Buffer.concat calls.
- For keepAlive.js:  
  Confirm 'use strict'; is at the top, and check for the addition of checkTimeoutInterval and sendKeepAliveInterval constants. The keep_alive and connection management logic should also be updated.
