# Classic Guild Frame

Restores the look and functionality of the old GuildUI, but adds minimized Chat from the new CommunitiesUI.

## !! TAINT WARNING !!
#### Why is this addon causing taints?
Blizzard's own implementation of Lua ingame isn't perfect and using these functions and templates can cause some weird chains of events resulting in taints for no obvious reason. I already replaced all the `UIDropDownMenu`-related calls and templates with library to eliminate those taints, but they weren't the only source of taints.
#### If you happen to find the remaining source(s) of taints in this addon, I'm more than happy to patch it!
#### Even with taints this addon works 99,99% of the time; the only thing the taints prevent is `creating`, `editing` and `removing` subchannels in the Guild and Communities Chat-system.