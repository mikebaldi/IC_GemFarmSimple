### Warning:
This script reads system memory. I do not know CNE's stance on reading system memory used by the game, so use at your own risk. Pointers may break on any given update and I may no longer decide to update them.

# Instructions for GemFarmSimple.AHK:
1. Read and familiarize yourself with all topics covered in Maviin's FAQ: https://docs.google.com/document/d/1ek-66HsOT3VABWdBNh-5iMOSd7UP5ssTRjgS4xkO1To/edit#
2. Download and install AutoHotkey: https://www.autohotkey.com/
3. Download `GemFarmSimpleI.AHK`, `IC_MemoryFunctions.AHK`, `IC_ServerCallFunctions.AHK`, `IC_GeneralFunctions.AHK`, `IC_LevelUpFunctions.AHK`, `json.AHK`, and `classMemory.AHK` to the same folder.
    * Occasionally, I may upload different versions of IC_MemoryFunctions.AHK for different versions of IC. Any Memory Function file with `_v###` has not been tested with the script by me and only tested for accurate memory reads. The file will need to be renamed, deleting the `_v###` portion.
4. Scan all downloaded files with trusted antivirus software.
5. Right click GemFarmSimple.AHK and select run script.
6. If this is your first time running the script, click the `Change or View Install Path` button on the settings tab of the GUI and confirm it is correct or update accordingly.
7. If this is your first time running the script, a new champion you want to use in the script is released, or a soft cap increase was released then click the `Build Defines` button. In the field on the GUI window that pops up, enter the champion ID of the most recent champion released. If you are unsure of the champion ID, use https://idle.kleho.ru/hero/ or http://idlechampions.soulreaver.usermd.net/champions.html 
8. With the correct ID entered, click the `Build and Close` button. Note, building the defines can take some time, please be patient.
9. If this is your first time running the script or you have built new defines then click the `Select Specializations` button. Choose your specialization choice for each champion or confirm they are correct then click the `Save` button, confirm your selections are correct, and then click the `Close` button. Note, building the specialization settings GUI can take some time, please be patient.
10. On the settings tab ov the GUI enter or confirm your settings are correct and then click the `Save Settings` button. This will also save the defines and specialization settings you built as part of previous steps, allowing you to skip steps 6 through 9 on subsquent uses of the script, except as noted above. See below for Settings Documentation. Note: this will create a new file in the script directory: GemFarmSimpleUserSettings.JSON. This file will be loaded automatically the next time the script is run.
11. In the in game settings, uncheck **'Disable F1-F12 Leveling'** and if using seat 12 champion then make sure to change Steam's settings for screenshots.
12. Load into a Free Play Adventure, assign your speed gem farming team to formation save slot 1 (the one accessed with button 'q'), only assign three familiars to the field with none to be used anywhere else, and click the `Run` button.
13. Click the `X` button in the upper right corner to close and exit the script.

## Recommended Additional Steps:
Review AutoHotkey tutorials and documentation.

## Notes:
1. This script is for the Steam PC version of the game.
2. This script will take control of the mouse to make clicks for specializations and for resetting an adventure.

# Settings Documentation:

## Bench Seats used in saved formation 1:
Check the boxes corresponding to champion seats used in your speed gem farming team. Make sure this speed gem farming team is saved to formation slot 1, the one accessed with button '1'. Make sure the only familiars used in this saved formation are three on the field. You can use less than three familiars, but three will provide the optimal speed.

## Reset adventure after this zone:
Set this number to where your familiars no longer kill in one click.

## Reset is unable to progress after this much time (seconds):
After the entered amount of time has passed, the script will assume something wrong has happened and attempt to restart the adventure. This should be at least 30 seconds higher than the slowest level you can complete.

# How the Script works:
1. The script confirms Idle Champions is still running. If it detects the game is not running then it will restart it.
2. The script inputs the following keys: click level up, right arrow key (to make sure to keep progressing), and q (to make sure the correct formation is being used).
3. The script attempts to level up a champion and select the correct specialization if necessary. It will cycle through the champion bench seats selected as part of the settings.
4. The script will attempt to detect if a boss zone was cleared to input g twice and skip the boss bag animation. 
5. The script will check if you have passed your reset zone or if you have not progressed within the set amount of time. If the script has detected that it is time to reset the adventure then it will input the r key to bring up the end adventure dialog box, attempt to click the complete button, pause for a couple seconds, close the game so that it can make a server call to restart into a new adventure, open the game, wait to detect the game has loaded, and then restart this loop.
