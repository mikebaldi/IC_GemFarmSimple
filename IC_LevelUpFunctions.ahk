;a group of functions for leveling up and specializing champions
global lufScriptVer := "v1.0, 9/25/21"

;object we will use to store our defines
global HeroDefines := {}
;object we will use to store our specialization settings
global SpecSettings := {}
;Return

/*=======================================================================================================
Functions for building defines and settings and the necessary GUI for leveling and specializing champions
=======================================================================================================*/

/*
    A function to build an object storing various defines related to each champion to be used in various level up functions
    This function reads from cached_defs.JSON

    Requires #include JSON.ahk
    Requires global HeroDefines := {}

    Accepts optional first parameter to limit the maximum champion id to be parsed, MaxChampID
    Accepts optional second paramter to change file path of install directory

    May not work with non steam platforms if the install has different file paths to cached_definitions.json
*/
BuildHeroDefines(MaxChampID := 87, GameInstallDir := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\")
{
    ;create a JSON object from cached defs to build our own defines and GUI
    ;GameInstallDir := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
    CachedDefs := GameInstallDir "IdleDragons_Data\StreamingAssets\downloaded_files\cached_definitions.json"

    FileRead, oData, %CachedDefs%
    if ErrorLevel
        MsgBox Couldn't open CachedDefs

    CachedDefsParsed := JSON.parse(oData)
    ;release oData
    oData := ""

    ;object we will use to store our defines
    HeroDefines := {}

    ;pull useful data from hero defines and save it in our object
    for k, v in CachedDefsParsed["hero_defines"]
    {
        if (v["id"] <= MaxChampID)
        {
            HeroDefines[v["id"]] := {}
            HeroDefines[v["id"]]["Name"] := v["name"]
            HeroDefines[v["id"]]["ChampID"] := v["id"]
            HeroDefines[v["id"]]["ChampSeat"] := v["seat_id"]
            HeroDefines[v["id"]]["BaseCost"] := v["base_cost"]
            HeroDefines[v["id"]]["CostCurve"] := v["cost_curves"][1]
            HeroDefines[v["id"]]["MaxLvl"] := 0
            HeroDefines[v["id"]]["SpecDefines"] := {}
            ;HeroDefines[v["id"]]["SpecDefines"]["TotalSpecOptions"] := 0
        }
    }

    ;pull spec and max level data from defines
    for k, v in CachedDefsParsed["upgrade_defines"]
    {
        ;there are some 9999 upgrades for some reason, we wan't to exclude those too
        if (v["hero_id"] <= MaxChampID AND v["required_level"] < 9999)
        {
            if (v["specialization_name"])
            {
                ;this loop will create a new object to store spec data if it doesn't exist and count total number of spec choices at a given level requirement
                ;no champs with more than three spec choices, when one is added with a fourth this may need to be changed to loop, 4
                i := 1
                loop, 3
                {
                    if (!IsObject(HeroDefines[v["hero_id"]]["SpecDefines"][i]))
                    {
                        ;HeroDefines[v["hero_id"]]["SpecDefines"]["TotalSpecOptions"] := i
                        HeroDefines[v["hero_id"]]["SpecDefines"][i] := {}
                        HeroDefines[v["hero_id"]]["SpecDefines"][i]["RequiredLvl"] := v["required_level"]
                        HeroDefines[v["hero_id"]]["SpecDefines"][i]["Choices"] := 1
                        var := HeroDefines[v["hero_id"]]["SpecDefines"][i]["Choices"]
                        HeroDefines[v["hero_id"]]["SpecDefines"][i][var] := v["specialization_name"]
                        ;not using gold coast so removing for now, next level is tied to gold coast.
                        ;HeroDefines[v["hero_id"]]["SpecDefines"][i]["GoldCost"] := 0
                        ;setting this high and we will increment it down later
                        ;HeroDefines[v["hero_id"]]["SpecDefines"][i]["NextLvl"] := 99999
                        HeroDefines[v["hero_id"]]["SpecDefines"][i]["UpgradeCount"] := i
                        Break
                    }
                    else if (HeroDefines[v["hero_id"]]["SpecDefines"][i]["RequiredLvl"] == v["required_level"])
                    {
                        HeroDefines[v["hero_id"]]["SpecDefines"][i]["Choices"] := HeroDefines[v["hero_id"]]["SpecDefines"][i]["Choices"] + 1
                        var := HeroDefines[v["hero_id"]]["SpecDefines"][i]["Choices"]
                        HeroDefines[v["hero_id"]]["SpecDefines"][i][var] := v["specialization_name"]
                        Break
                    }
                    ++i
                }
            }
            ;increase max level each time an upgrade with higher level requirements is found
            if (HeroDefines[v["hero_id"]]["MaxLvl"] < v["required_level"])
            {
                HeroDefines[v["hero_id"]]["MaxLvl"] := v["required_level"]
            }
        }
    }
/*  not used, but keeping here just in case things change.
    ;estimate gold cost of spec upgrade, we had to separate this into two for loops since the upgrades are not sequentially ordered in cached defs
    for k, v in CachedDefsParsed["upgrade_defines"]
    {
        ;there are some 9999 upgrades for some reason, we wan't to exclude those too
        if (v["hero_id"] <= MaxChampID AND v["required_level"] < 9999)
        {
            TotalSpecOptions := HeroDefines[v["hero_id"]]["SpecDefines"]["TotalSpecOptions"]
            i := 1
            loop, %TotalSpecOptions%
            {
                if (v["required_level"] > HeroDefines[v["hero_id"]]["SpecDefines"][i]["RequiredLvl"] AND v["required_level"] < HeroDefines[v["hero_id"]]["SpecDefines"][i]["NextLvl"])
                {
                    HeroDefines[v["hero_id"]]["SpecDefines"][i]["NextLvl"] := v["required_level"]
                }
                ++i
            }
        }
    }
*/

    ;count upgrades at each specialization, we had to separate this into two for loops since the upgrades are not sequentially ordered in cached defs
    for k, v in CachedDefsParsed["upgrade_defines"]
    {
        ;there are some 9999 upgrades for some reason, we wan't to exclude those too
        if (v["hero_id"] <= MaxChampID AND v["required_level"] < 9999)
        {
            TotalSpecOptions := HeroDefines[v["hero_id"]]["SpecDefines"].Count() ;["TotalSpecOptions"]
            i := 1
            loop, %TotalSpecOptions%
            {
                ;make sure to not count specialization upgrades
                j := 1
                k := 1
                loop, %TotalSpecOptions%
                {
                    if (v["required_level"] == HeroDefines[v["hero_id"]]["SpecDefines"][j]["RequiredLvl"])
                    {
                        k := 0
                        break
                    }
                    ++j
                }
                if (v["required_level"] < HeroDefines[v["hero_id"]]["SpecDefines"][i]["RequiredLvl"] AND k == 1)
                {
                    HeroDefines[v["hero_id"]]["SpecDefines"][i]["UpgradeCount"] := HeroDefines[v["hero_id"]]["SpecDefines"][i]["UpgradeCount"] + 1
                }
                ++i
            }
        }
    }

    ;use geometric series formula to estimate gold cost to upgrade
/* Not used, but keeping here just in case things change.
    for k, v in HeroDefines
    {
        TotalSpecOptions := v["SpecDefines"]["TotalSpecOptions"]
        i := 1
        loop, %TotalSpecOptions%
        {
            HeroDefines[v["ChampID"]]["SpecDefines"][i]["GoldCost"] := CalcUpgradeGoldCost(v["BaseCost"], v["CostCurve"], v["SpecDefines"][i]["RequiredLvl"], v["SpecDefines"][i]["NextLvl"])
            ++i
        }
    }
*/
    ;release objects
    CachedDefsParsed := ""
    Return
}

;function that uses geometric series formula to calculate the cost of upgrading from the current champion level to the target champion level
;requires parameters for champion base cost, cost curve, current level, and target level
CalcUpgradeGoldCost(BaseCost, CostCurve, CurrentLvl, TargetLvl)
{
    if (CurrentLvl < 1)
    {
        CurrentLvl := 1
    }
    a := BaseCost
    z := (1 - CostCurve)
    x := CostCurve**(CurrentLvl - 1)
    y := CostCurve**(TargetLvl - 1)
    Return ((a/z) * (x - y))
}

/*
    A GUI to view, build, and modify specialization settings
    requires:
    global HeroDefines := {} ;fully defined
    global SpecSettings := {} ;this can be empty

    To build HeroDefines, you can use the following two lines of code:
    BuildHeroDefines(87) ;modify 87 to highest champID, so to exclude unreleased champions
    WriteObjectToJSON("HeroDefines.JSON", HeroDefines)

    Once built this way, defines can be loaded with the following line of code:
    HeroDefines := LoadObjectFromJSON("HeroDefines.JSON")

    To show the GUI call function ShowSpecSettingsGUI()
*/ 
BuildSpecSettingsGUI()
{
    global
    Gui, SpecSettingsGUI:New
    Gui, SpecSettingsGUI:+Resize -MaximizeBox
    Gui, SpecSettingsGUI:Font, q5
    Gui, SpecSettingsGUI:Add, Button, x554 y25 w60 gSaveClickedSpecSettingsGUI, Save
    Gui, SpecSettingsGUI:Add, Button, x554 y+25 w60 gCloseClickedSpecSettingsGUI, Close
    Gui, SpecSettingsGUI:Add, Tab3, x5 y5 w539, Seat 1|Seat 2|Seat 3|Seat 4|Seat 5|Seat 6|Seat 7|Seat 8|Seat 9|Seat 10|Seat 11|Seat 12|
    Seat := 1
    loop, 12
    {
        Gui, Tab, Seat %Seat%
        Gui, SpecSettingsGUI:Font, w700 s11
        Gui, SpecSettingsGUI:Add, Text, x15 y35, Seat %Seat% Champions:
        Gui, SpecSettingsGUI:Font, w400 s9
        for k, v in HeroDefines
        {
            if (v["ChampSeat"] = Seat)
            {
                Name := v["Name"]
                ChampID := v["ChampID"]
                Gui, SpecSettingsGUI:Font, w700
                Gui, SpecSettingsGUI:Add, Text, x15 y+10, Name: %Name%    `ID: %ChampID%
                Gui, SpecSettingsGUI:Font, w400

                TotalSpecOptions := v["SpecDefines"].Count() ;["TotalSpecOptions"]
                i := 1
                Loop, %TotalSpecOptions%
                {
                    Choices := v["SpecDefines"][i]["Choices"]
                    RequiredLvl := v["SpecDefines"][i]["RequiredLvl"]
                    Choice := SpecSettings[ChampID][RequiredLvl]["Choice"]
                    if (!Choice)
                    {
                        Choice := 1
                    }
                    var := ""
                    j := 1
                    loop, %Choices%
                    {
                        var := var v["SpecDefines"][i][j]
                        var := var "|"
                        ++j
                    }
                    Gui, SpecSettingsGUI:Add, DropDownList, x15 y+5 vNewChamp%ChampID%Spec%i%Drop Choose%Choice% AltSubmit, %var%
                    var := v["SpecDefines"][i][Choice]
                    Gui, SpecSettingsGUI:Add, Text, x15 y+5 vChamp%ChampID%Spec%i%Txt w350, Saved Choice: %var%
                    ++i
                }
            }
        }
        ++Seat
    }
    Return
}

;call this function to display GUI built in function above
ShowSpecSettingsGUI()
{
    Gui, SpecSettingsGUI:Show
    Return
}

;close spec settings GUI
CloseClickedSpecSettingsGUI()
{
    Gui, SpecSettingsGUI:Hide
    Return
}


;save button function from GUI built as part of BuildSpecSettingsGUI()
;Requires function WriteObjectToJSON()
SaveClickedSpecSettingsGUI()
{
    global
    Gui, SpecSettingsGUI:Submit, NoHide
    For k, v in HeroDefines
    {
        TotalSpecOptions := v["SpecDefines"].Count() ;["TotalSpecOptions"]
        ChampID := v["ChampID"]
        SpecSettings[ChampID] := {}
        SpecSettings[ChampID]["ChampID"] := ChampID
        i := 1
        Loop, %TotalSpecOptions%
        {
            RequiredLvl := v["SpecDefines"][i]["RequiredLvl"]
            Choices := v["SpecDefines"][i]["Choices"]
            SpecSettings[ChampID][RequiredLvl] := {}
            SpecSettings[ChampID][RequiredLvl]["Choice"] := NewChamp%ChampID%Spec%i%Drop
            SpecSettings[ChampID][RequiredLvl]["RequiredLvl"] := RequiredLvl
            Choice := SpecSettings[ChampID][RequiredLvl]["Choice"]
            var := v["SpecDefines"][i][Choice]
            GuiControl, SpecSettingsGUI:, Champ%ChampID%Spec%i%Txt, Saved Choice: %var%
            ++i
        }
    }
    Return
}

/*===============================
Functions for leveling a champion
===============================*/

/* 
    A function that will level up and specialize a champion based on their bench seat and ID
    Requires parameter ChampSeat, ChampID, and ByRef ChampLvl
    Requires parameter sleepMS - recommended start value is 250, but longer values may be needed if updated memory reads are not being noticed
    Requires #include classMemory.ahk and call functions OpenProcess() and ModuleBaseAddress() are called each time client is restarted
    Requires #include IC_GeneralFunctions.ahk
    Requiges global objects HeroDefines and SpecSettings

    To build HeroDefines and SpecSettings use the following four lines of code:
    BuildHeroDefines(87) ;modify 87 to highest champID, so to exclude unreleased champions
    WriteObjectToJSON("HeroDefines.JSON", HeroDefines)
    BuildSpecSettingsGUI()
    ShowSpecSettingsGUI()

    Once built, defines and settings can be loaded with the following two lines of code:
    HeroDefines := LoadObjectFromJSON("HeroDefines.JSON")
    SpecSettings := LoadObjectFromJSON("SpecSettings.JSON")

    The function attempts to level champ by bench seat via the DirectedInputs() function
    The function checks if the given lvl corresponds to a specialization and calls SpecializeChamp() function if so
*/
LevelUpByID(ChampSeat, ChampID, ByRef ChampLvl, sleepMS)
{
    DirectedInput("{F" . ChampSeat . "}")
    ;wait for memory to update
    Sleep, sleepMS
    ChampLvl := memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int")
    ;check if current level is a specialization level
    if (SpecSettings[ChampID][ChampLvl]["RequiredLvl"] == ChampLvl)
    {
        SpecializeChamp(ChampID, ChampLvl, ChampSeat, sleepMS)
        ChampLvl := memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int")
        Return
    }
    Return
}

/*
    A function to level up a champion by ID to a specified level with the option to specialize the champion
    Requires parameters Champ ID, TargetLvl, specBool, sleepMS
    sleepMS is passed to LevelUpByID() function
    TargetLvl defined as 0 will use MaxLvl from HeroDefines
    specBool is a bool: 0 to manually click specialization, 1 to let Modron pick specialization
    Function will change specBool to 0 if champion has been leveled past the final specialization
    Requires #include classMemory.ahk and call functions OpenProcess() and ModuleBaseAddress() are called each time client is restarted
    Requires #include IC_GeneralFunctions.ahk
    Requiges global objects HeroDefines and SpecSettings

    To build HeroDefines and SpecSettings use the following four lines of code:
    BuildHeroDefines(87) ;modify 87 to highest champID, so to exclude unreleased champions
    WriteObjectToJSON("HeroDefines.JSON", HeroDefines)
    BuildSpecSettingsGUI()
    ShowSpecSettingsGUI()

    Once built, defines and settings can be loaded with the following two lines of code:
    HeroDefines := LoadObjectFromJSON("HeroDefines.JSON")
    SpecSettings := LoadObjectFromJSON("SpecSettings.JSON")
*/
LevelToTargetByID(ChampID, TargetLvl, specBool, sleepMS)
{
    ChampSeat := HeroDefines[ChampID]["ChampSeat"]
    if (!TargetLvl)
    {
        TargetLvl := HeroDefines[ChampID]["MaxLvl"]
    }
    ChampLvl := memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int")
    while (specBool == 0 AND TargetLvl > memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int"))
    {
        LevelUpByID(ChampSeat, ChampID, ChampLvl, sleepMS)
        ChampLvl := memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int")
        specBool := IsSpecialized(ChampID)     
    }
    while (TargetLvl > memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int"))
    {
        DirectedInput("{F" . ChampSeat . "}")
        ChampLvl := memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int")
    }
    Return
}

/*=====================================================================
Functions for specializing a champion or checking specialization status
=====================================================================*/

/*
    Function to specialize a champ
    Requires Parameters ChampID and ChampLvl
    Requires parameter ChampSeat, ChampLvl, ChampSeat
    Requires parameter sleepMS - recommended start value is 250, but longer values may be needed if updated memory reads are not being noticed
    Requires #include classMemory.ahk and call functions OpenProcess() and ModuleBaseAddress() are called each time client is restarted
    Requiges global objects HeroDefines and SpecSettings

    To build HeroDefines and SpecSettings use the following four lines of code:
    BuildHeroDefines(87) ;modify 87 to highest champID, so to exclude unreleased champions
    WriteObjectToJSON("HeroDefines.JSON", HeroDefines)
    BuildSpecSettingsGUI()
    ShowSpecSettingsGUI()

    Once built, defines and settings can be loaded with the following two lines of code:
    HeroDefines := LoadObjectFromJSON("HeroDefines.JSON")
    SpecSettings := LoadObjectFromJSON("SpecSettings.JSON")

    After attempting to specialize the champ, the script will compare upgrade count in memory to defines to confirm if specialization occured.
    Returns 1 on success, returns 0 on failure
*/
SpecializeChamp(ChampID, ChampLvl, ChampSeat, sleepMS)
{
    ScreenCenterX := ( memory.ReadMem( memory.currentScreenWidth, "Int" ) / 2)
    ScreenCenterY := ( memory.ReadMem( memory.currentScreenHeight, "Int" ) / 2)
    yClick := ScreenCenterY + 225
    ButtonWidth := 70
    ButtonSpacing := 180
    ;Get total number of specialization choices for this level
    for k, v in HeroDefines[ChampID]["SpecDefines"]
    {
        if (v["RequiredLvl"] == ChampLvl)
        {
            Choices := v["Choices"]
            GoldCost := v["GoldCost"]
            UpgradeCount := v["UpgradeCount"]
        }
    }
    Choice := SpecSettings[ChampID][ChampLvl]["Choice"]
    TotalWidth := (ButtonWidth * Choices) + (ButtonSpacing * (Choices - 1))
    xFirstButton := ScreenCenterX - (TotalWidth / 2)
    xClick := xFirstButton + 35 + (250 * (Choice - 1))
    StartTime := A_TickCount
    ElapsedTime := 0
    While (UpgradeCount > memory.ReadMem( memory.ChampUpgradeCountByID[ ChampID ], "Int" ) AND ElapsedTime < 5000)
    {
        WinActivate, ahk_exe IdleDragons.exe
        MouseClick, Left, xClick, yClick, 1
        ;let the click register
        Sleep, sleepMS
        UpdateElapsedTime(StartTime)
    }
    if (UpgradeCount <= memory.ReadMem( memory.ChampUpgradeCountByID[ ChampID ], "Int" ))
    {
        ;successfully specialized
        Return 1
    }
    else
    {
        ;failed specializing
        Return 0
    }
}

/* 
    A function that checks if a champion is fully specialized
    Requires parameters ChampID
    Requiges global objects HeroDefines and SpecSettings

    To build HeroDefines and SpecSettings use the following four lines of code:
    BuildHeroDefines(87) ;modify 87 to highest champID, so to exclude unreleased champions
    WriteObjectToJSON("HeroDefines.JSON", HeroDefines)
    BuildSpecSettingsGUI()
    ShowSpecSettingsGUI()

    Once built, defines and settings can be loaded with the following two lines of code:
    HeroDefines := LoadObjectFromJSON("HeroDefines.JSON")
    SpecSettings := LoadObjectFromJSON("SpecSettings.JSON")

    Compares upgrade count in memory to upgrade count in defines.
*/
IsSpecialized(ChampID)
{
    i := 0
    for k, v in HeroDefines[ChampID]["SpecDefines"]
    {
        if (v["UpgradeCount"] <= memory.ReadMem( memory.ChampUpgradeCountByID[ ChampID ], "Int" ) AND v["UpgradeCount"])
        {
            ++i
        }
    }
    if (i == (HeroDefines[ChampID]["SpecDefines"].Count()))
    {
        Return 1
    }
    Return 0
}

/*
    A formation to confirm if a specialization was selected, returns 1 if so or if not a specialization level, returns 0 if not selected
*/
SpecializationSelected(ChampID)
{
    ChampLvl := memory.ReadMem( memory.ChampLevelByID[ ChampID ], "Int")
    for k, v in HeroDefines[ChampID]["SpecDefines"]
    {
        if (v["RequiredLvl"] == ChampLvl)
        {
            if (memory.ReadMem( memory.ChampUpgradeCountByID[ ChampID ], "Int" ) >= v["UpgradeCount"])
            {
                Return 1
            }
            else
            {
                Return 0
            }
            Break
        }
    }
    Return 1
}

/*===================================================
Functions for finding and loading formation save data
===================================================*/

/*
    A function that looks at specified saved formation and returns an array of champions saved in that formation. Returns -1 on failure.
    Optional Paramater Favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)
    when parameter ignoreEmptySlots is set to 1 or greater, empty slots (-1) will not be added to the array

    Requires #include classMemory.ahk and call functions OpenProcess() and ModuleBaseAddress() are called each time client is restarted
*/
GetFavoriteSavedFormation(favorite := 1, ignoreEmptySlots := 0)
{
    ;reads memory for the number of saved formations
    formationSavesSize := memory.ReadMem( memory.FormationSavesV2_size, "Int" )
    ;cycle through saved formations to find save slot of Favorite
    formationSaveSlot := -1
    i := 0
    loop, %formationSavesSize%
    {
        if ( memory.ReadMem( memory.FormationSavesV2Favorite[ i ], "Int" ) == favorite)
        {
            formationSaveSlot := i
            Break
        }
        ++i
    }
    if (formationSaveSlot == -1)
    {
        Return formationSaveSlot
    }
    else
    {
        Return CompileSavedFormationArray( formationSaveSlot, 1 )
    }
}

CompileSavedFormationArray( saveItem, ignoreEmptySlots )
{
    _size := memory.ReadMem( memory.FormationSavesV2Formation_size[ slot ], "Int" )
    Formation := {}
    i := 0
    loop, %_size%
    {
        champID := memory.ReadMem( memory.FormationSavesV2FormationChampID[ saveItem, i ], "Int" )
        if ( !ignoreEmptySlots )
        {
            Formation.Push( champID )
        }
        else if ( champID != -1 )
        {
            Formation.Push( champID )
        }
        ++i
    }
    return Formation
}

/*
    A function that looks for a saved formation matching a name. Returns -1 on failure.
    Optional Paramater name, string

    Requires #include classMemory.ahk and call functions OpenProcess() and ModuleBaseAddress() are called each time client is restarted
*/
GetSavedFormationSlotByName(name)
{
    ;reads memory for the number of saved formations
    formationSavesSize := memory.ReadMem( memory.FormationSavesV2_size, "Int" )
    ;cycle through saved formations to find save slot of Favorite
    formationSaveSlot := -1
    i := 0
    loop, %formationSavesSize%
    {
        if (memory.ReadMem( memory.FormationSavesV2Name[ i ], "String" ) == name)
        {
            formationSaveSlot := i
            Break
        }
        ++i
    }
    Return formationSaveSlot
}

/*
    A function that looks for a saved formation matching a favorite. Returns -1 on failure.
    Optional Paramater Favorite, 0 = not a favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)

    Requires #include classMemory.ahk and call functions OpenProcess() and ModuleBaseAddress() are called each time client is restarted
*/
GetSavedFormationSlotByFavorite(favorite := 1)
{
    ;reads memory for the number of saved formations
    formationSavesSize := memory.ReadMem( memory.FormationSavesV2_size, "Int" )
    ;cycle through saved formations to find save slot of Favorite
    formationSaveSlot := -1
    i := 0
    loop, %formationSavesSize%
    {
        if ( memory.ReadMem( memory.FormationSavesV2Favorite[ item ], "Int" ) == favorite)
        {
            formationSaveSlot := i
            Break
        }
        ++i
    }
    Return formationSaveSlot
}

/*
    A function that levels each champion in a saved formation to max, one champ at a time.
    Optional Paramater Favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)
    specBool and sleepMS are passed
*/
LevelSavedFormationMax(favorite := 1, specBool := 0, sleepMS := 250)
{
    formation := GetFavoriteSavedFormation(favorite)
    for k, v in formation
    {
        if (v != -1)
        {
            LevelToTargetByID(v, 0, specBool, sleepMS)
        }
    }
}