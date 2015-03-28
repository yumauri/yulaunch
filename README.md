# What

This is tool, which allows you to start external program by clicking on the link with non standard protocol.

For example, start Putty or console SSH client after clicking on link ssh://127.0.0.1/, or start VNC viewer after clicking on link vnc://127.0.0.1/

Actually, some programs can handle urls by themselves. Above-mentioned Putty can open telnet connection, if you give it link like [telnet://127.0.0.1/](telnet://127.0.0.1/), but at the same moment it can't open ssh connection for link [ssh://127.0.0.1/](ssh://127.0.0.1/)

May be that is because you can meet telnet:// links somewhere in the Internet and Putty had been adjusted to being used with them, but it is hardly possible to meet links to ssh, just because there is no such standard protocol ssh://

# Why

You can use it, for example, for your internal web page with list of your servers.

Or, in my case, I've written a couple of UserJS scripts to use with internal user support's web application, where I could see all servers, that belongs to client, and with this tool I could open ssh and vnc connections to them very fast.

# Documentation

[Opera quick guide](https://github.com/yumauri/yulaunch/blob/wiki/OperaQuickGuide.md)
[Configuration file description](https://github.com/yumauri/yulaunch/blob/wiki/ConfigurationFile.md)
[Program description](https://github.com/yumauri/yulaunch/blob/wiki/ProgramDescription.md)
