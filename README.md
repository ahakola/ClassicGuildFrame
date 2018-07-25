# Classic Guild Frame

Restores the look and functionality of the old GuildUI, but adds minimized Chat from the new CommunitiesUI.

## !! TAINT WARNING !!
#### Why is this addon causing taints?
In the current state, this addon uses Blizzard's `DropDownMenu` templates, which are still after all these years, one of the biggest sources of taints in the game. Unfortunately they aren't the only source of taints in this addon, so I didn't bother using Libs to prevent the taints happening, because I didn't find the other source(s) and the end result would be still the same.
#### If you happen to find other source(s) of taints in this addon, I'm more than happy to patch it and get rid of the Blizzard's `DropDownMenu` and replace them with Libs.
#### Even with taints this addon works 99,99% of the time; the only thing the taints prevent is `creating`, `editing` and `removing` subchannels in the Guild and Communities Chat-system.