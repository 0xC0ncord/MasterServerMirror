MasterServerMirror
==================
MasterServerMirror is a server actor for Unreal Tournament 2004 servers that creates additional master server uplinks as configured by the server administrator.
Its primary purpose is to allow servers who have switched their primary master server to [OpenSpy](https://github.com/chc/openspy-core-v2) to continue to be listed in Epic's official master server until it is shut down on January 24th, 2023.

Installation
------------
Download the [latest release](https://github.com/0xC0ncord/MasterServerMirror/releases/latest) and install it to your server's `System/` directory. Then, to activate the mod, do the following:
1. Add the server actor to your `ServerActors`:
```
ServerActors=MasterServerMirror.MasterServerMirror
```
2. Edit the master server list, if desired, in `MasterServerMirror.ini`.
The default configuration is sufficient to list the server in Epic's official master server and no further action is required.
If you have not switched your server to use OpenSpy, you should do that first.
Alternatively, you can configure MasterServerMirror to mirror to OpenSpy, although this configuration is not recommended.
The configuration for the `MasterServerList` follows the same format as `IpDrv.MasterServerLink` in `UT2004.ini`.
More than one master server may be specified, and the server actor will take care of creating an uplink for each one.
```ini
[MasterServerMirror.MasterServerMirror]
MasterServerList=(Address="ut2004master1.epicgames.com",Port=28902)
```
Note that you do not need to add `MasterServerMirror` to your `ServerPackages` as the mod is only required on the server.

If done correctly you should see multiple master server uplinks at server startup:
```
Resolving utmaster.openspy.net...
Creating master server uplink for ut2004master1.epicgames.com:28902
Resolving ...
Resolving ut2004master1.epicgames.com...
MasterServerUplink: Resolved utmaster.openspy.net as 157.245.212.59.
MasterServerUplink: Resolved ut2004master1.epicgames.com as 3.218.5.215.
MasterServerUplink: Connection to utmaster.openspy.net established.
MasterServerUplink: Connection to ut2004master1.epicgames.com established.
Approval APPROVED
Master server assigned our MatchID: 1234
Approval APPROVED
Master server requests heartbeat 0 with code 3716
Master server requests heartbeat 1 with code 3716
Master server assigned our MatchID: 0
```

License
-------
MasterServerMirror is licensed under the Open Unreal Mod License version 1.1. See [LICENSE](LICENSE) for details.

Credits
-------
- the OpenSpy team for their amazing work on the OpenSpy UT2k3/UT2k4 master server!
- Me, `0xC0ncord` aka `TonyTheSlayer` for the initial conception and creation of this mod.
