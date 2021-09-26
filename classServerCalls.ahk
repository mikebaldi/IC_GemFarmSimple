;=================================
;Class(es) for making server calls
;=================================

;to do: create method(s) for buying and opening chests between runs.
;to do: work on memory functions and incorporate into user data classes for when userDetails fails to build or for stat tracking on memory reads.
;have to figure out how we want memory functions to work first.

;user data classes for creating an object to store... user data
;I broke them in two as I see this first one being useful for non servercall use, end of run stats for example.
;so these probably need to move to another file.
class _classUserStats
{
    __New( userDetails )
    {
        this.setKeysUserStats( userDetails )
        userDetails := ""
        return this
    }

    setKeysUserStats( userDetails )
    {
        if( IsObject( userDetails ) )
        {
            this.silverChestsOpened := userDetails.details.stats.chests_opened_type_1
            this.silverChests := userDetails.details.chests.1
            this.goldChestsOpened := userDetails.details.stats.chests_opened_type_2
            this.goldChests := userDetails.details.chests.2
            this.gemsSpent := userDetails.details.red_rubies_spent
            this.gems := userDetails.details.red_rubies
        }
        ;I think I want to eventually have this read memory, but for now 0 is better than null... maybe.
        Else
        {
            this.silverChestsOpened := 0
            this.silverChests := 0
            this.goldChestsOpened := 0
            this.goldChests := 0
            this.gemsSpent := 0
            this.gems := 0
        }
        userDetails := ""
        return
    }

    ;==================================================================
    ;supposedly this is standard of accessing is better than object.key
    ;==================================================================
    getSilverChestsOpened()
    {
        return this.silverChestsOpened
    }

    getSilverChests()
    {
        return this.silverChests
    }

    getGoldChestsOpened()
    {
        return this.goldChestsOpened
    }

    getGoldChests()
    {
        return this.goldChests
    }

    getGemsSpent()
    {
        return this.gemsSpent
    }

    getGems()
    {
        return this.gems
    }

    ;=======================================================================
    ;multiple get methods to subtract another object created with this class
    ;=======================================================================
    getDiffSilverChestsOpened( start )
    {
        if ( IsObject( start ) )
        return this.getSilverChestsOpened() - start.getSilverChestsOpened()
        else
        return "Incorrect parameters passed"
    }

    getDiffSilverChests( start )
    {
        if ( IsObject( start ) )
        return this.getSilverChests() - start.getSilverChests()
        else
        return "Incorrect parameters passed"
    }

    getDiffGoldChestsOpened( start )
    {
        if ( IsObject( start ) )
        return this.getGoldChestsOpened() - start.getGoldChestsOpened()
        else
        return "Incorrect parameters passed"
    }

    getDiffGoldChests( start )
    {
        if ( IsObject( start ) )
        return this.getGoldChests() - start.getGoldChests()
        else
        return "Incorrect parameters passed"
    }

    getDiffGemsSpent( start )
    {
        if ( IsObject( start ) )
        return this.getGemsSpent() - start.getGemsSpent()
        else
        return "Incorrect parameters passed"
    }

    getDiffGems( start )
    {
        if ( IsObject( start ) )
        return this.getGems() - start.getGems()
        else
        return "Incorrect parameters passed"
    }
}

class _classUserData extends _classUserStats
{
    __New( userDetails )
    {
        this.setKeysUserData( userDetails )
        userDetails := ""
        return this
    }

    setKeysUserData( userDetails )
    {
        this.setKeysUserStats( userDetails )
        if( IsObject( userDetails ) )
        {
            this.instanceID := userDetails.details.instance_id
            this.activeInstanceID := userDetails.details.active_game_instance_id
            for k, v in userDetails.details.game_instances
            {
                if (v.game_instance_id == this.activeInstanceID) 
                {
                    this.currentAdventure := v.current_adventure_id
                }
            } 
        }
        ;place holder until figure out how to define these when failed get user details call
        else
        {
            this.instanceID := 0
            this.activeInstanceID := 0
            this.currentAdventure := 0
        }
        userDetails := ""
        return
    }

    ;==================================================================
    ;supposedly this is standard of accessing is better than object.key
    ;==================================================================
    getInstanceID()
    {
        return this.instanceID
    }

    getActiveInstanceID()
    {
        return this.activeInstanceID
    }

    getCurrentAdventure()
    {
        return this.currentAdventure
    }
}

/*
A class to make servercalls, primarily buying or opening chests. Can also load into an adventure if not currently in one.
Parameters:
userID - your unique userID
userHash - your userHash
advToLoad - A valid adventure id to load into when calling LoadAdventure() without a parameter. Postiive integer. Negative or values over 999 will default to Cursed Forest Free Play.
*/
class _classServerCalls
{
    __New( userID, userHash, advToLoad )
    {
        this.userID := userID
        this.userHash := userHash
        if (advToLoad < 1 )
        {
            advToLoad := 30
        }
        else if ( advToLoad > 999 )
        {
            advToLoad := 30
        }
        this.adventureToLoad := advToLoad
        this.dummyData := "&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999"
        userDetails := this.callUserDetails()
        ;this is probably not needed in here. is only here as part of copy of functionality of old server call functions.
        this.userDataStart := new _classUserDataDifferentiable( userDetails )
        this.userData := new _classUserData( userDetails )
        userDetails := ""
        return this
    }

    getVersion()
    {
        return "v1.0, 9/22/21"
    }

    ;============================================================
    ;Various server call functions that should be pretty obvious.
    ;============================================================
    ;Except this one, it is used internally and shouldn't be called directly.
    ServerCall( callName, parameters ) 
    {
        URLtoCall := "http://ps6.idlechampions.com/~idledragons/post.php?call=" callName parameters
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( "10000", "10000", "10000", "10000" )
        Try {
            WR.Open( "POST", URLtoCall, false )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
        }
        return data
    }

    callUserDetails() 
    {
        getUserParams := this.dummyData "&include_free_play_objectives=true&instance_key=1&user_id=" this.userID "&hash=" this.userHash
        rawDetails := this.ServerCall( "getuserdetails", getUserParams )
        Try
        {
            userDetails := JSON.parse(rawDetails)
        }
        Catch
        {
            return "Failed to fetch user details and build JSON object."
        }
        return userDetails
    }

    callLoadAdventure( adventureToLoad ) 
    {
        advParams := this.dummyData "&patron_tier=0&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.userData.instanceID 
            . "&game_instance_id=" this.userData.activeInstanceID "&adventure_id=" adventureToLoad "&patron_id=0"
        this.ServerCall( "setcurrentobjective", advParams )
        return
    }

    callBuyChests( chestID, chests )
    {
        if ( chests > 100 )
        chests := 100
        else if ( chests < 1 )
        return
        chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.userData.instanceID "&chest_type_id=" chestID "&count=" chests
        this.ServerCall( "buysoftcurrencychest", chestParams )
        return
    }

    callOpenChests( chestID, chests )
    {
        if ( chests > 99 )
        chests := 99
        else if ( chests < 1 )
        return
        chestParams := "&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" this.userID "&hash=" this.userHash 
            . "&instance_id=" this.userData.instanceID "&chest_type_id=" chestid "&game_instance_id=" this.userData.activeInstanceID "&count=" chests
        this.ServerCall( "opengenericchest", chestParams )
        return
    }

    /*
    A method to buy or open silver or gold chests based on parameters passed.
    Parameters:
    minGems - integer, minimum amount of gems to keep in reserver and not spend
    openSilvers - integer, max 99, open silver chests when greater than this amount
    openGolds - integer, max 99, open gold chests when greater than this amount
    buySilvers - integer, max 100, buy silver chests when more than enough gems
    buyGolds - integer, max 100, buy gold chests when more than enough gems
    timer - integer, number of miliseconds to spend in this method
    Return Values:
    If callUserDetails fails, will return a string noting so.
    On success opening or buying, will return string noting so.
    On success, but not enough chests to open or gems to buy, will return string noting so.
    */
    ;considering moving all these parameters, except maybe timer, to new. to avoid all these if and elseif checks
    BuyOrOpenChests( minGems, openSilvers, openGolds, buySilvers, buyGolds, timer )
    {
        startTime := A_TickCount
        userDetails := this.callUserDetails()
        if ( !IsObject( userDetails ) )
        return "Failed to fetch or build user details."
        if ( openSilvers < 0 )
        {
            openSilvers := 0
        }
        else if ( openSilvers > 99 )
        {
            openSilvers := 99
        }
        if ( openGolds < 0 )
        {
            openGolds := 0
        }
        else if ( openGolds > 99 )
        {
            openGolds := 99
        }
        if ( buySilvers < 0 )
        {
            buySilvers := 0
        }
        else if ( buySilvers > 100 )
        {
            buySilvers := 100
        }
        if ( buyGolds < 0 )
        {
            buyGolds := 0
        }
        else if ( buyGolds > 100 )
        {
            buyGolds := 100
        }
        this.userData.setKeysUserData( userDetails )
        var := ""
        if ( openSilvers AND this.userData.getSilverChests() > openSilvers AND ( timer > A_TickCount - startTime ) )
        {
            this.callOpenChests( 1, openSilvers )
            var .= " Opened " . openSilvers . " silver chests."
        }
        if ( openGolds AND this.userData.getGoldChests() > openGolds AND ( timer > A_TickCount - startTime ) )
        {
            this.callOpenChests( 2, openGolds )
            var .= " Opened " . openGolds . " gold chests."
        }
        gems := this.userData.getGems() - minGems
        cost := buySilvers * 50
        if ( buySilvers AND gems > cost AND ( timer > A_TickCount - startTime ) )
        {
            this.callBuyChests( 1, buySilvers )
            var .= " Bought " . buySilvers . " silver chests."
            gems -= cost
        }
        cost := buyGolds * 500
        if ( buyGolds AND gems > cost AND ( timer > A_TickCount - startTime ) )
        {
            this.callBuyChests( 2, buyGolds )
            var .= " Bought " . buyGolds . " gold chests."
        }
        if ( var == "")
        {
            return "No chests opened or purchased."
        }
        else
        return var
    }

    ;A method to check if the party is on the world map. Necessary state to use callLoadAdventure()
    IsOnWorldMap()
    {
        userDetails := this.callUserDetails()
        if ( !IsObject( userDetails ) )
        return "Failed to fetch or build user details."
        this.userData.setKeysUserData( userDetails )
        if ( this.userData.getCurrentAdventure() == -1 )
        return 1
        else
        return 0
    }
}