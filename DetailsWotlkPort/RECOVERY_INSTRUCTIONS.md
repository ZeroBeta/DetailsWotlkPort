# Parser.lua Corruption Recovery Instructions

## Problem
The `parser.lua` file got corrupted during automated editing attempts. Automated repairs kept introducing new corruption.

## Solution: Manual Download

Since we don't have a backup and automated repairs failed, you need to download a clean copy:

### Step 1: Download Clean File
Visit this URL and save the file:
```
https://raw.githubusercontent.com/Kowson/Details-Damage-Meter-for-3.3.5a/master/core/parser.lua
```

**To download:**
1. Right-click the link and choose "Save Link As..."
2. OR open the URL, press Ctrl+S to save
3. Save it as `parser.lua`

### Step 2: Replace Corrupted File
Replace the corrupted file at:
```
/home/zb/Games/ascension-wow/drive_c/Program Files/Ascension Launcher/resources/client/Interface/AddOns/DetailsWotlkPort/core/parser.lua
```

### Step 3: Test In-Game
Load WoW and check if Details addon loads without errors.

## What Went Wrong
- Multiple automated edit attempts caused cascading corruption
- File replacement via curl resulted in empty file (network/permission issue)
- The corruption was too extensive for surgical fixes

## Current State
Your original corrupted `parser.lua` is back in place. The addon will have Lua errors until you replace it with a clean copy.

## Alternative: Fresh Addon Install
If you want to start completely fresh:
1. Delete the entire Details addon folder
2. Download the latest WotLK 3.3.5a version from: https://github.com/Kowson/Details-Damage-Meter-for-3.3.5a
3. Extract to your AddOns folder
