;Modron Automation Gem Farming Script
;by mikebaldi1980
;put together with the help from many different people. thanks for all the help.
global ScriptVer := "v1.0, 9/25/21"

#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%
CoordMode, Mouse, Client

;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include classMemory.ahk

;class for parsing JSON to objects and stringifying objects to JSON
#include JSON.ahk

;pointer addresses, offsets, and functions for reading specific locations of memory
#include classIdleChampionsMemory.ahk
global memory := new _classIdleChampionsMemoryReader

;server call functions and variables
#include classServerCalls.ahk

;general functions
#include IC_GeneralFunctions.ahk

;leve up functions, has g labels which seem to auto run and need Return to avoid
#include IC_LevelUpFunctions.ahk



;load user settings
global UserSettings := {}
UserSettings := LoadObjectFromJSON("GemFarmSimpleUserSettings.JSON")
if (!IsObject(UserSettings))
{
    MsgBox, User settings failed to load, starting script with defaults. ;, change or View Install path before doing anything else.
    UserSettings := {}
    UserSettings["TargetZone"] := 30
    UserSettings["ResetTime"] := 60
    UserSettings["InstallPath"] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
}
else
{
    if (!UserSettings["TargetZone"])
    {
        MsgBox, Reset adventure after this zone setting failed to load, starting script with default.
        UserSettings["TargetZone"] := 30
    }
    if (!UserSettings["InstallPath"])
    {
        MsgBox, Install path setting failed to load, starting script with default.
        UserSettings["InstallPath"] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
    }
    if (!UserSettings["ResetTime"])
    {
        MsgBox, Reset if unable to progress after this much time failed to load, starting script with default.
        UserSettings["ResetTime"] := 60
    }
}
;load hero defines
HeroDefines := UserSettings["HeroDefines"]
if (!IsObject(HeroDefines))
{
    MsgBox, Hero Defines failed to load, build before running the script or selecting specializations.
    UserSettings["HeroDefines"] := {}
    HeroDefines := {}
}
;check if specialization settings exist in user settings
SpecSettings := UserSettings["SpecSettings"]
if (!IsObject(SpecSettings))
{
    MsgBox, User specialization settings failed to load, select specializations before running the script.
    UserSettings["SpecSettings"] := {}
    SpecSettings := {}
}

;build GUI
Gui, MyWindow:New
Gui, MyWindow:+Resize -MaximizeBox
Gui, MyWindow:Font, q5
;buttons
Gui, MyWindow:Add, Button, x415 y25 w60 gSave_Settings, Save Settings
Gui, MyWindow:Add, Button, x415 y+15 w60 gBuild_Defines, Build Defines
Gui, MyWindow:Add, Button, x415 y+15 w60 gSpec_Settings, Select Specializations
Gui, MyWindow:Add, Button, x415 y+15 w60 gRun_Clicked, `Run
;tabs
Gui, MyWindow:Add, Tab3, x5 y5 w400, Settings|Stats|Version ;|Memory Reads|
;build out settings tab
Gui, Tab, Settings
;bench seats to be used
Gui, MyWindow:Font, w700 cRed
Gui, MyWindow:Add, Text, x15 y35, Load your gem farm team to formation save slot 1 (q).
Gui, MyWindow:Font, cDefault w400
;Setting: target zone to reset adventure
if (!UserSettings["TargetZone"])
{
    UserSettings["TargetZone"] := 30
}
Gui, MyWindow:Add, Edit, vNewTargetZone x15 y+10 w50, % UserSettings["TargetZone"]
Gui, MyWindow:Add, Text, x+5, Reset adventure after this zone
;Setting: amount of time stuck without progress before script resets adventure
if (!UserSettings["ResetTime"])
{
    UserSettings["ResetTime"] := 60
}
Gui, MyWindow:Add, Edit, vNewResetTime x15 y+10 w50, % UserSettings["ResetTime"]
Gui, MyWindow:Add, Text, x+5, Reset if unable to progress after this much time (seconds)
;Setting: change install path
Gui, MyWindow:Add, Button, x15 y+20 gChangeInstallLocation_Clicked, Change or View Install Path
;save warning text
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+20 vSaveNeededID w375,
Gui, MyWindow:Font, w400
;build stats tab
Gui, Tab, Stats
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y33, Stats updated continuously (mostly):
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, Current Zone Time: 
Gui, MyWindow:Add, Text, vCurrentZoneTimeID x+2 w200, Not Started
Gui, MyWindow:Add, Text, x15 y+2, Current `Run `Time:
Gui, MyWindow:Add, Text, vCurrentRunTimeID x+2 w50,
Gui, MyWindow:Add, Text, x15 y+2, Total `Run `Time:
Gui, MyWindow:Add, Text, vTotalRunTimeID x+2 w50,
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+10, Stats updated once per run:
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, `Run `Count:
Gui, MyWindow:Add, Text, vRunCountID x+2 w50,
Gui, MyWindow:Add, Text, x15 y+2, Previous `Run `Time:
Gui, MyWindow:Add, Text, vPrevRunTimeID x+2 w50,
Gui, MyWindow:Add, Text, x15 y+2, Avg. `Run `Time:
Gui, MyWindow:Add, Text, vAvgRunTimeID x+2 w50,
Gui, MyWindow:Font, cGreen w700
Gui, MyWINdow:Add, Text, x15 y+10, Total Gems:
Gui, MyWindow:Add, Text, vGemsTotalID x+2 w50,
Gui, MyWINdow:Add, Text, x15 y+2, Gems per hour:
Gui, MyWindow:Add, Text, vGemsPhrID x+2 w200,
Gui, MyWindow:Font, cDefault w400
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y+10, `Loop: 
Gui, MyWindow:Add, Text, vLoopID x+10 w375, Not Started
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+2, `Loop Time: 
Gui, MyWindow:Add, Text, vElapsedTimeID x+2 w200, Not Started
;Gui, MyWindow:Add, Text, x15 y+12, Chest Return: 
;Gui, MyWindow:Add, Text, vChestID x+2 w375 r4,
;build info tab
Gui, Tab, Version
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y33, Gem Farm Simple
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+10, Script Version: %ScriptVer%
var := memory.getVersion()
Gui, MyWindow:Add, Text, x15 y+10, Memory File Version: %var%
Gui, MyWindow:Add, Text, x15 y+10, General Function File Version: %gfScriptVer%
Gui, MyWindow:Add, Text, x15 y+10 vServerCallVersionID, Servercall Function File Version: updates after first server call
Gui, MyWindow:Add, Text, x15 y+10, Level Up Function File Version: %lufScriptVer%
;build memory tab
/*
Gui, Tab, Memory
Gui, MyWindow:Font, w700
Gui, MyWindow:Add, Text, x15 y33, Memory Reads: 
Gui, MyWindow:Font, w400
Gui, MyWindow:Add, Text, x15 y+2, If these values all remain blank, memory file may be out of date.
Gui, MyWindow:Add, Text, x15 y+2, All reads have a time stamp with the format: <memory value> HH:MM:SS.SSS

Gui, MyWindow:Add, Text, x15 y+5, ReadCurrentZone: 
Gui, MyWindow:Add, Text, vReadCurrentZoneID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadHighestZone: 
Gui, MyWindow:Add, Text, vReadHighestZoneID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadTransitioning: 
Gui, MyWindow:Add, Text, vReadTransitioningID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadCurrentObjID: 
Gui, MyWindow:Add, Text, vReadCurrentObjIDID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadUserID: 
Gui, MyWindow:Add, Text, vReadUserIDID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadUserHash: 
Gui, MyWindow:Add, Text, vReadUserHashID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadChampLvlbyID: 
Gui, MyWindow:Add, Text, vReadChampLvlbyIDID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadGems: 
Gui, MyWindow:Add, Text, vReadGemsID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadGemsSpent: 
Gui, MyWindow:Add, Text, vReadGemsSpentID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadScreenHeight: 
Gui, MyWindow:Add, Text, vReadScreenHeightID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadScreenWidth: 
Gui, MyWindow:Add, Text, vReadScreenWidthID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadResetting: 
Gui, MyWindow:Add, Text, vReadResettingID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadGameStarted: 
Gui, MyWindow:Add, Text, vReadGameStartedID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadFinishedOfflineProgressWindow: 
Gui, MyWindow:Add, Text, vReadFinishedOfflineProgressWindowID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadMonstersSpawnedThisAreaOL: 
Gui, MyWindow:Add, Text, vReadMonstersSpawnedThisAreaOLID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadMonstersSpawned: 
Gui, MyWindow:Add, Text, vReadMonstersSpawnedID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadChampUpgradeCountByID: 
Gui, MyWindow:Add, Text, vReadChampUpgradeCountByIDID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadFormationSavesSize: 
Gui, MyWindow:Add, Text, vReadFormationSavesSizeID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadFormationFavoriteIDBySlot: 
Gui, MyWindow:Add, Text, vReadFormationFavoriteIDBySlotID x+2 w200,

Gui, MyWindow:Add, Text, x15 y+5, ReadFormationSaveBySlot: 
Gui, MyWindow:Add, Text, vReadFormationSaveBySlotID x+2 w250,
*/
;show gui
Gui, MyWindow:Show

global tCurrentZone := ""
;global paused := 0

+`::
Pause
;if (!paused)
;{
;    GuiControl, MyWindow:, LoopID, Script paused.
;    GuiControl, MyWindow:, SaveNeededID, Script paused.
;    paused := 1
;}
;Else
;{
;    GuiControl, MyWindow:, LoopID, Script unpaused.
;    GuiControl, MyWindow:, SaveNeededID, Script unpaused.
;    paused := 0
;}
tCurrentZone := A_TickCount
return

;save settings button clicked
Save_Settings()
{
    global
    Gui, MyWindow:Submit, NoHide
    UserSettings["TargetZone"] := NewTargetZone
    UserSettings["ResetTime"] := NewResetTime
    if (IsObject(SpecSettings))
    {
        UserSettings["SpecSettings"] := SpecSettings
    }
    if (IsObject(HeroDefines))
    {
        UserSettings["HeroDefines"] := HeroDefines
    }
    WriteObjectToJSON("GemFarmSimpleUserSettings.JSON", UserSettings)
    GuiControl, MyWindow:, SaveNeededID, Settings saved!
    Return
}
;open specialization settings gui
Spec_Settings()
{
    BuildSpecSettingsGUI()
    ShowSpecSettingsGUI()
    GuiControl, MyWindow:, SaveNeededID, Specialization settings may have changed, please save.
    Return
}
;run gem farm
Run_Clicked()
{
    GuiControl, MyWindow:, SaveNeededID, While script is running, pause (SHIFT+``) to change settings.
    GemFarm()
    Return
}
;x button clicked
MyWindowGuiClose() 
{
    MsgBox 4,, Are you sure you want to `exit?
    IfMsgBox Yes
    ExitApp
    IfMsgBox No
    Return True
}
;install path gui button clicked
ChangeInstallLocation_Clicked()
{
    BuildInstallGUI()
    Gui, InstallGUI:Show
    Return
}
;GUI to change install path
BuildInstallGUI()
{
    global
    Gui, InstallGUI:New
    ;check if user settings defined, if not use default
    if (!UserSettings["InstallPath"])
    {
        UserSettings["InstallPath"] := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
    }
    Gui, InstallGUI:Add, Edit, vNewInstallPath x15 y+10 w300 r5, % UserSettings["InstallPath"]
    Gui, InstallGUI:Add, Button, x15 y+25 gInstallOK_Clicked, Change and `Close
    Gui, InstallGUI:Add, Button, x+100 gInstallCancel_Clicked, `Cancel
    Return
}
;button for the install path GUI, cancel
InstallCancel_Clicked()
{
    GuiControl, InstallGUI:, NewInstallPath, % UserSettings["InstallPath"]
    Gui, InstallGUI:Hide
    Return
}
;button for the install path GUI, confirmation change
InstallOK_Clicked()
{
    global
    Gui, InstallGUI:Submit, NoHide
    UserSettings["InstallPath"] := NewInstallPath
    Gui, InstallGUI:Hide
    GuiControl, MyWindow:, SaveNeededID, Install path may have changed, please save.
    Return
}
;x button clicked
InstallGUIGuiClose() 
{
    MsgBox 4,, Close without saving?
    IfMsgBox Yes
    {
        GuiControl, InstallGUI:, NewInstallPath, % UserSettings["InstallPath"]
        Gui, InstallGUI:Hide
    }
    IfMsgBox No
    Return True
}
;build defines button clicked
Build_Defines()
{
    BuildHeroDefinesGUI()
    Gui, BuildHeroDefinesGUI:Show
    Return
}
;GUI to build HeroDefines
BuildHeroDefinesGUI()
{
    global
    Gui, BuildHeroDefinesGUI:New
    ;check if user settings defined, if not use default
    CurrentMaxChampID := HeroDefines.Length()
    if (CurrentMaxChampID = "")
    {
        CurrentMaxChampID := 0
    }
    Gui, BuildHeroDefinesGUI:Add, Text, x15 y15, Current hero defines highest champion ID: %CurrentMaxChampID%
    Gui, BuildHeroDefinesGUI:Add, Edit, vNewMaxChampID x15 y+10 w50, % CurrentMaxChampID
    Gui, BuildHeroDefinesGUI:Add, Text, x15 y+10 vHeroDefsBuildingID w200,
    Gui, BuildHeroDefinesGUI:Add, Button, x15 y+25 gHeroDefsOK_Clicked, Build and `Close
    Gui, BuildHeroDefinesGUI:Add, Button, x+100 gHeroDefsCancel_Clicked, `Cancel
    Return
}
;button for the install path GUI, cancel
HeroDefsCancel_Clicked()
{
    Gui, BuildHeroDefinesGUI:Hide
    Return
}
;button to build new hero defs
HeroDefsOK_Clicked()
{
    global
    Gui, BuildHeroDefinesGUI:Submit, NoHide
    GuiControl, BuildHeroDefinesGUI:, HeroDefsBuildingID, Building new hero defines, please wait.
    BuildHeroDefines(NewMaxChampID, UserSettings["InstallPath"])
    Gui, BuildHeroDefinesGUI:Hide
    GuiControl, MyWindow:, SaveNeededID, Hero defines may have been updated, please save.
    Return
}
;x button clicked
BuildHeroDefinesGUIGuiClose() 
{
    MsgBox 4,, Close without saving?
    IfMsgBox Yes
    {
        Gui, BuildHeroDefinesGUI:Hide
    }
    IfMsgBox No
    Return True
}

GemFarm()
{
    GuiControl, MyWindow:, LoopID, Loading game data to script.
    GuiControl, MyWindow:, ElapsedTimeID,
    ;open process to read memory
    memory.OpenProcess()
    ;get module base address to use for memory reads
    memory.ModuleBaseAddress()
    ;memory := new _classIdleChampionsMemoryReader
    ;read adventure id for script to load into on resets or errors. check the value is reasonable
    advtoload := memory.ReadMem( memory.currentObjectiveID, "Int" )
    if (advtoload == "")
    {
        MsgBox, Failed to read Adventure ID, check memory function file is up to date. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    else if (advtoload == -1)
    {
        MsgBox, You appear to be on the world map, load into a valid adventure. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    else if (advtoload <= 0)
    {
        MsgBox, Unknown error reading Adventure ID. Value read: %advtoload%. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    ;read current zone. check the value is reasonable.
    CurrentZone := memory.ReadMem( memory.currentZone, "Int" )
    if (CurrentZone == "")
    {
        MsgBox, Failed to read current zone, check memory function file is up to date. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    else if (CurrentZone <= 0)
    {
        MsgBox, Unknown error reading current zone. Value read: %CurrentZone%. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    ;variable used to check if progress has halted.
    PrevZone := CurrentZone
    ;read user id for script to use to make server calls. check the value is reasonable.
    UserID := memory.ReadMem( memory.userID, "Int" )
    if (UserID == "")
    {
        MsgBox, Failed to read user ID, check memory function file is up to date. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    ;read user hash for script to make server calls. check the value is reasonable.
    UserHash := memory.ReadMem( memory.userHash, "String" )
    if (UserHash == "")
    {
        MsgBox, Failed to read user hash, check memory function file is up to date. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    ;read formation save data and cull empty slots
    gemFarmFormationSaveSlot := GetSavedFormationSlotByFavorite(1)
    gemFarmFormation := {}
    gemFarmFormation := GetFavoriteSavedFormation(1, 1)
    if ( gemFarmFormation.Count() < 1 )
    {
        MsgBox, Failed to read formation from save slot 1, check memory function file is up to date. Ending script.
        GuiControl, MyWindow:, SaveNeededID, Script ended.
        Return
    }
    gemsStart := memory.ReadMem( memory.gems, "Int" )
    gemsSpentStart := memory.ReadMem( memory.gemsSpent, "Int" )
    ;variable used to check how long without progress
    tCurrentZone := A_TickCount
    ;variable used to track time on current run
    tCurrentRun := A_TickCount
    ;variable used to track time for all runs
    tTotalRun := A_TickCount
    ;variables to store champ id and lvl
    ChampID := ""
    ChampLvl := ""
    ;variable to count runs
    runCount := 0
    ;first key in gemFarmFormation
    formationKey := 1
    Loop
    {
        ;check IC is running
        LoadIC()
        GuiControl, MyWindow:, LoopID, Main Loop
        ;level click damage, load formation, and send right
        DirectedInput("``{Right}q")
        ;check if champion is specialized and level them accordingly
        if (!IsSpecialized(gemFarmFormation[formationKey]))
        {
            LevelUpByID(HeroDefines[gemFarmFormation[formationKey]]["ChampSeat"], gemFarmFormation[formationKey], ChampLvl, 250)
            if (SpecializationSelected(gemFarmFormation[formationKey]))
            {
                ++formationKey
            }
        }
        else
        {
            DirectedInput("{F" . HeroDefines[gemFarmFormation[formationKey]]["ChampSeat"] . "}")
            ++formationKey
        }
        ;check if gem farm key increment has gone past count
        if (formationKey > gemFarmFormation.Count())
        {
            formationKey := 1
        }
        ;speed up boss bag pick up
        DoubleG()
        ;update current zone timer
        CurrentZone := memory.ReadMem( memory.currentZone, "Int" )
        if (CurrentZone > PrevZone)
        {
            PrevZone := CurrentZone
            tCurrentZone := A_TickCount
        }
        ElapsedTime := Round((A_TickCount - tCurrentZone) / 1000, 2)
        GuiControl, MyWindow:, CurrentZoneTimeID, % ElapsedTime
        ;check if it is time to reset adventure.
        if (ElapsedTime > UserSettings["ResetTime"] OR CurrentZone > UserSettings["TargetZone"])
        {
            GuiControl, MyWindow:, LoopID, Ending Adventure
            EndAdventure()
            ;sleep so end adventure internal IC method can run.
            Sleep, 2000
            GuiControl, MyWindow:, LoopID, Closing IC
            CloseIC()
            GuiControl, MyWindow:, LoopID, Using server call to load into a new adventure.
            if ( !IsObject( ServerCall ) )
            {
                ServerCall := new _classServerCalls( UserID, UserHash, advtoload )
            }
            ;test for buying and opening chests will probably remove.
            ;GuiControl, MyWindow:, ChestID, Testing BuyOrOpenChests
            ;var := ServerCall.BuyOrOpenChests( 2000, 99, 99, 100, 0, 15000 )
            ;GuiControl, MyWindow:, ChestID, %var%
            if ( ServerCall.IsOnWorldMap() )
            {
                ServerCall.callLoadAdventure( advtoload )
                var := ServerCall.getVersion()
                GuiControl, MyWindow:, ServerCallVersionID, Servercall Function File Version: %var%
            }
            GuiControl, MyWindow:, LoopID, Restarting IC
            LoadIC()
            ;reset variables associated with checking if stuck on current zone too long.
            CurrentZone := memory.ReadMem( memory.currentZone, "Int" )
            PrevZone := CurrentZone
            tCurrentZone := A_TickCount
            ++runCount
            UpdateStats(tCurrentRun, tTotalRun, runCount, gemsStart, gemsSpentStart)
            CurrentZone := memory.ReadMem( memory.currentZone, "Int" )
        }
        UpdateTimers(tCurrentRun, tTotalRun)
    }
}

LoadIC()
{
    ;GuiControl, MyWindow:, LoopID, Safety Check.
    while (SafetyCheck(UserSettings["InstallPath"]))
    {
        GuiControl, MyWindow:, LoopID, Loading Game
        if (!GameLoaded())
        {
            GuiControl, MyWindow:, LoopID, Failed to load game, restarting.
            CloseIC()
        }
    }
}

UpdateTimers(tCurrentRun, tTotalRun)
{
    ElapsedTime := Round((A_TickCount - tCurrentRun) / 60000, 2)
    GuiControl, MyWindow:, CurrentRunTimeID, % ElapsedTime
    ElapsedTime := Round((A_TickCount - tTotalRun) / 3600000, 2)
    GuiControl, MyWindow:, TotalRunTimeID, % ElapsedTime
    Return
}

UpdateStats(ByRef tCurrentRun, tTotalRun, runCount, gemsStart, gemsSpentStart)
{
    GuiControl, MyWindow:, RunCountID, % runCount
    ElapsedTime := Round((A_TickCount - tCurrentRun) / 60000, 2)
    GuiControl, MyWindow:, PrevRunTimeID, % ElapsedTime
    ElapsedTime := Round((A_TickCount - tTotalRun) / (60000 * runCount), 2)
    GuiControl, MyWindow:, AvgRunTimeID, % ElapsedTime
    gems := memory.ReadMem( memory.gems, "Int" ) - gemsStart + memory.ReadMem( memory.gemsSpent, "Int" ) - gemsSpentStart
    GuiControl, MyWindow:, GemsTotalID, % gems
    ElapsedTime := (A_TickCount - tTotalRun) / 3600000
    gph := Round((gems/ElapsedTime), 2)
    GuiControl, MyWindow:, GemsPhrID, % gph
    tCurrentRun := A_TickCount
}