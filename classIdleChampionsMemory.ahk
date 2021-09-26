;=======================================================================
;Class for reading particular fields of memory in the game Idle Chamions
;=======================================================================

/*SAMPLE USAGE
;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include classMemory.ahk
memory := new _classIdleChampionsMemoryReader
size := memory.ReadMem( memory.FormationSavesV2_size, "Int" )
name := memory.ReadMem( memory.FormationSavesV2Name[ 0 ], "String" )
favorite := memory.ReadMem( memory.FormationSavesV2Favorite[ 0 ], "Int" )
champID := memory.ReadMem( memory.FormationSavesV2FormationChampID[ 0, 0 ], "Int")
Msgbox, size: %size% item 0 name: %name% item 0 fav: %favorite% item 0 slot 0 champID: %ChampID% 

TO DO:
Create method to check data type is valid.
Create method to test memory fields.
*/

class _classIdleChampionsMemoryReader
{
    __New()
    {
        this.OpenProcess()
        this.ModuleBaseAddress()
        return this
    }
    ;method used to read memory, requires the field and data type (see properties below)
    ReadMem( field, dataType )
    {
        if ( this.checkDataType( dataType ) )
        {
            ;do stuff for invalid data types
        }
        if ( dataType != "String" )
        {
            return this.idle.read( this.moduleBaseAddress, dataType , field* )
        }
        else
        {
            return this.idle.readstring( this.moduleBaseAddress, length := 0, encoding := "UTF-16", field* )
        }
    }
    ;must be called each time the game restarts
    OpenProcess()
    {
        this.idle := new _ClassMemory( "ahk_exe IdleDragons.exe", "", this.hProcessCopy )
        return
    }
    ;must be called each time the game restarts
    ModuleBaseAddress()
    {
        this.moduleBaseAddress := this.idle.getModuleBaseAddress( "mono-2.0-bdwgc.dll" )+0x003A0574
        return
    }

    getVersion()
    {
        return "v1.0, 9/25/21"
    }

    ;========================================
    ;Memory Fields Related to Formation Saves
    ;========================================
    ;dataType == "Int"
    FormationSavesV2_size[]
    {
        get
        {
            offsetArray := this.FormationSavesV2
            offsetArray.Push( 0xC )
            return offsetArray
        }
    }
    ;dataType == "Int"
    FormationSavesV2Favorite[ item ]
    {
        get
        {
            offsetArray := this.FormationSavesV2List
            ;[ Item[ item ], Favorite ]
            offsetArray.Push( this.getListItemOffset( item, 0 ), 0x24 )
            ;offsetArray.Push( 0x10, 0x24)
            return offsetArray
        }
    }
    ;dataType == "String", length == 0, encoding == "UTF-16"
    FormationSavesV2Name[ item ]
    {
        get
        {
            offsetArray := this.FormationSavesV2List
            ;[ Item[ item ], Name, Value ]
            offsetArray.Push( this.getListItemOffset( item, 0 ), 0x18, 0xC )
            return offsetArray
        }
    }
    ;dataType == "Int"
    FormationSavesV2Formation_size[ item ]
    {
        get
        {
            offsetArray := this.FormationSavesV2List
            ;[ Item[ item ], Formation, _size ]
            offsetArray.Push( this.getListItemOffset( item, 0 ), 0xC, 0xC )
            return offsetArray
        }
    }
    ;dataType == "Int"
    FormationSavesV2FormationChampID[ item, formationSlot ]
    {
        get
        {
            offsetArray := this.FormationSavesV2List
            ;[ Item[ item ], Formation, _items, Item[ formationSlot ] ]
            offsetArray.Push( this.getListItemOffset( item, 0 ), 0xC, 0x8, this.getListItemOffset( formationSlot, 0 ) )
            return offsetArray
        }
    }
    ;===================
    ;user related fields
    ;===================
    ;dataType == "Int"
    userID[]
    {
        get
        {
            offsetArray := this.GameUser
            ;[ ID ]
            offsetArray.Push( 0x30 )
            return offsetArray
        }
    }
    ;dataType == "String", length == 0, encoding == "UTF-16"
    userHash[]
    {
        get
        {
            offsetArray := this.GameUser
            ;[ Hash, Value ]
            offsetArray.Push( 0x10, 0xC )
            return offsetArray
        }
    }
    ;===================
    ;hero related fields
    ;===================
    ;"Int"
    ChampLevelByID[ champID ]
    {
        get
        {
            offsetArray := this.heroesList
            ;[ Item[ champID - 1 ], _level ]
            offsetArray.Push( this.getListItemOffset( champID, 1 ), 0x1A8 )
            return offsetArray
        }
    }
    
    ;"Int"
    ChampUpgradeCountByID[ ChampID ]
    {
        get
        {
            offsetArray := this.heroesList
            ;[ Item[ champID - 1 ], purchasedUpgradeIDs, _count ]
            offsetArray.Push( this.getListItemOffset( champID, 1 ), 0x110, 0x18 )
            return offsetArray
        }
    }
    ;=====================
    ;screen related fields
    ;=====================
    ;"Int"
    currentScreenWidth[]
    {
        get
        {
            offsetArray := this.Screen
            offsetArray.Push( 0x1FC )
            return offsetArray
        }
    }
    ;"Int"
    currentScreenHeight[]
    {
        get
        {
            offsetArray := this.Screen
            offsetArray.Push( 0x200 )
            return offsetArray
        }
    }
    ;=================================
    ;ActiveCampaignData related fields
    ;=================================
    ;"Int"
    currentObjectiveID[]
    {
        get
        {
            offsetArray := this.ActiveCampaignData
            ;[ currentObjective, ID ]
            offsetArray.Push( 0xC, 0x8 )
            return offsetArray
        }
    }
    ;"Int"
    currentZone[]
    {
        get
        {
            offsetArray := this.currentArea
            ;[ level ]
            offsetArray.Push( 0x28 )
            return offsetArray
        }
    }
    ;"Int"
    highestZone[]
    {
        get
        {
            offsetArray := this.ActiveCampaignData
            ;[ highestAvailableAreaID ]
            offsetArray.Push( 0x4C )
            return offsetArray
        }
    }
    ;===================
    ;data related fields
    ;===================
    ;"Int"
    gems[]
    {
        get
        {
            offsetArray := this.userData
            ;[ redRubies ]
            offsetArray.Push( 0x130 )
            return offsetArray
        }
    }
    ;"Int"
    gemsSpent[]
    {
        get
        {
            offsetArray := this.userData
            ;[ redRubiesSpent ]
            offsetArray.Push( 0x134 )
            return offsetArray
        }
    }
    ;=============================
    ;general hodge podge of fields
    ;=============================
    ;"Char"
    Transitioning[]
    {
        get
        {
            offsetArray := this.areaTransitioner
            offsetArray.Push( 0x1C )
            return offsetArray
        }
    }
    ;"Char"
    Resetting[]
    {
        get
        {
            offsetArray := this.ResetHandler
            offsetArray.Push( 0x1C )
            return offsetArray
        }
    }
    ;"Char"
    GameStarted[]
    {
        get
        {
            offsetArray := this.Game
            offsetArray.Push( 0x7C )
            return offsetArray
        }
    }
    ;"Int"
    monstersSpawnedThisArea[]
    {
        get
        {
            offsetArray := this.area
            ;[ basicMonstersSpawnedThisArea ]
            offsetArray.Push( 0x148)
            return offsetArray
        }
    }

    ;=======================
    ;offline progress fields
    ;=======================
    ;"Char"
    finishedOfflineProgressWindow[]
    {
        get
        {
            offsetArray := this.offlineProgressHandler
            offsetArray.Push( 0xFA )
            return offsetArray
        }
    }
    ;"Int"
    monstersSpawnedThisAreaOP[]
    {
        get
        {
            offsetArray := this.offlineProgressHandler
            ;[ monstersSpawnedThisArea ]
            offsetArray.Push( 0x98 )
            return offsetArray
        }
    }

    ;==================================================
    ;Memory Pointers - Formatted to mimic the structure
    ;==================================================
    ;'top most' pointer, rest match names in the structure built by CE
    Game[]
    {
        get
        {
            ;offsetArray := ["test1", "test2"]
            return [0x658, 0xA0]
        }
    }

        GameUser[]
        {
            get
            {
                offsetArray := this.Game
                offsetArray.Push( 0x54 )
                return offsetArray
            }
        }
    
        ChampionsGameInstance[]
        {
            get
            {
                offsetArray := this.Game
                ;[ gameInstances, _items, Item[0] ]
                offsetArray.Push( 0x58, 0x8, 0x10 )
                return offsetArray
            }
        }

            Screen[]
            {
                get
                {
                    offsetArray := this.ChampionsGameInstance
                    offsetArray.Push( 0x8 )
                    return offsetArray
                }
            }

            Controller[]
            {
                get
                {
                    offsetArray := this.ChampionsGameInstance
                    offsetArray.Push( 0xC )
                    return offsetArray
                }
            }

                area[]
                {
                    get
                    {
                        offsetArray := this.Controller
                        offsetArray.Push( 0xC )
                        return offsetArray
                    }
                }

                areaTransitioner[]
                {
                    get
                    {
                        offsetArray := this.Controller
                        offsetArray.Push( 0x20 )
                        return offsetArray
                    }
                }

                    userData[]
                    {
                        get
                        {
                            offsetArray := this.Controller
                            offsetArray.Push( 0x50 )
                            return offsetArray
                        }
                    }

                        HeroHandler[]
                        {
                            get
                            {
                                offsetArray := this.userData
                                offsetArray.Push( 0x8 )
                                return offsetArray
                            }
                        }

                            heroesList[]
                            {
                                get
                                {
                                    offsetArray := this.HeroHandler
                                    ;[ heroes, _items ]
                                    offsetArray.Push( 0xC, 0x8 )
                                    return offsetArray
                                }
                            }

            ActiveCampaignData[]
            {
                get
                {
                    offsetArray := this.ChampionsGameInstance
                    offsetArray.Push( 0x10 )
                    return offsetArray
                }
            }

                currentArea[]
                {
                    get
                    {
                        offsetArray := this.ActiveCampaignData
                        offsetArray.Push( 0x14 )
                        return offsetArray
                    }
                }

            ResetHandler[]
            {
                get
                {
                    offsetArray := this.ChampionsGameInstance
                    offsetArray.Push( 0x1C )
                    return offsetArray
                }
            }

            FormationSaveHandler[]
            {
                get
                {
                    offsetArray := this.ChampionsGameInstance
                    offsetArray.Push( 0x30 )
                    return offsetArray
                }
            }

                FormationSavesV2[]
                {
                    get
                    {
                        offsetArray := this.FormationSaveHandler
                        offsetArray.Push( 0x18 )
                        return offsetArray
                    }
                }

                    FormationSavesV2List[]
                    {
                        get
                        {
                            offsetArray := this.FormationSavesV2
                            ;[ _items ]
                            offsetArray.Push( 0x8 )
                            return offsetArray
                        }
                    }

                    FormationSavesV2Formation[]
                    {
                        get
                        {
                            return 0xC
                        }
                    }

                        FormationSavesV2FormationList[]
                        {
                            get
                            {
                                offsetArray := this.FormationSavesV2Formation
                                ;[ _items ]
                                offsetArray.Push( 0x8 )
                                return offsetArray
                            }
                        }

            offlineProgressHandler[]
            {
                get
                {
                    offsetArray := this.ChampionsGameInstance
                    offsetArray.Push( 0x40 )
                    return offsetArray
                }
            }

    ;==============
    ;Helper Methods
    ;==============
    ;used for getting offset of an item in a list when list starts at 0, used for most lists
    getListItemOffset( listItem, listStartValue )
    {
        listItem -= listStartValue
        return 0x10 + ( listItem * 0x4 )
    }
    ;used to check data type
    checkDatayType( dataType )
    {
        return 0
    }
}
