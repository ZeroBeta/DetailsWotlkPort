# SIMPLE FIX: Download Clean Parser File

## The Problem
Your `parser.lua` file is corrupted from my failed edit attempts.

## The Solution (2 minutes)

### Option 1: Download Just parser.lua (Fastest)
1. Open this link in your web browser:
   **https://github.com/Tercioo/Details-Damage-Meter**
   
2. Navigate to: `core/parser.lua`

3. Click "Raw" button (top right of the file view)

4. Press `Ctrl+S` to save the file

5. Save it as `parser.lua` and replace the file at:
   ```
   /home/zb/Games/ascension-wow/drive_c/Program Files/Ascension Launcher/resources/client/Interface/AddOns/DetailsWotlkPort/core/parser.lua
   ```

### Option 2: Fresh Install (Recommended - 5 minutes)
1. Delete your entire `Details` addon folder

2. Download the latest release from:
   **https://github.com/Tercioo/Details-Damage-Meter/releases**
   
3. Extract the ZIP to your AddOns folder

4. Done!

## Why I Can't Do It
- Automated downloads created empty files
- GitHub raw file URLs returning 404 errors
- Browser automation not available on your system

## Test
After replacing the file, start WoW. Details should load without Lua errors.

---
**Note:** The original file had ~8200 lines. If your download shows significantly different, it might be the wrong version.
