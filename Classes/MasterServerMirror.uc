//=============================================================================
// MasterServerMirror.uc
// Copyright (C) 2022 0xC0ncord <concord@fuwafuwatime.moe>
//
// This program is free software; you can redistribute and/or modify
// it under the terms of the Open Unreal Mod License version 1.1.
//=============================================================================

class MasterServerMirror extends Actor
    config(MasterServerMirror);

var() config array<MasterServerLink.tMasterServerEntry> MasterServerList;

function BeginPlay()
{
    local int i, x;
    local bool bFound;
    local MasterServerMirrorUplink A;

    while(i < MasterServerList.Length)
    {
        // remove duplicates from our own list
        x = i + 1;
        while(x < MasterServerList.Length)
        {
            if(MasterServerList[i] == MasterServerList[x])
                MasterServerList.Remove(x, 1);
            else
                x++;
        }

        // remove entries that exist in the real uplink
        bFound = false;
        for(x = 0; x < class'MasterServerLink'.default.MasterServerList.Length; x++)
        {
            if(MasterServerList[i] == class'MasterServerLink'.default.MasterServerList[x])
            {
                bFound = true;
                MasterServerList.Remove(i, 1);
                break;
            }
        }

        if(!bFound)
            i++;
    }

    // spawn an uplink for every master server we should mirror to
    for(i = 0; i < MasterServerList.Length; i++)
    {
        Log("Creating master server uplink for" @ MasterServerList[i].Address $ ":" $ MasterServerList[i].Port, 'MasterServerMirror');
        A = Spawn(class'MasterServerMirrorUplink');
        A.ServerEntry = MasterServerList[i];
        A.Reconnect();
    }

    Destroy();
}

defaultproperties
{
    MasterServerList(0)=(Address="ut2004master1.epicgames.com",Port=28902)
    RemoteRole=ROLE_None
    bHidden=True
    DrawType=DT_None
}
