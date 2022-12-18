//=============================================================================
// MasterServerMirrorUplink.uc
// Copyright (C) 2022 0xC0ncord <concord@fuwafuwatime.moe>
//
// This program is free software; you can redistribute and/or modify
// it under the terms of the Open Unreal Mod License version 1.1.
//=============================================================================

class MasterServerMirrorUplink extends MasterServerUplink;

var tMasterServerEntry ServerEntry;

event GetMasterServer(out string OutAddress, out int OutPort)
{
	LastMSIndex = MaxInt; // do not remove master servers from the globalconfig
    OutAddress = ServerEntry.Address;
    OutPort    = ServerEntry.Port;
}

function BeginPlay(); // stub

defaultproperties
{
}
