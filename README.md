# Classic Guild Frame

Restores the look and functionality of the old GuildUI, but adds minimized Chat from the new CommunitiesUI.

## !! TAINT WARNING !!
### Even with taints this addon works 99,99% of the time; the only thing the taints prevent is `creating`, `editing` and `removing` subchannels in the Guild and Communities Chat-system.
#### **Why is this happening?** In the current state this addon uses Blizzards DropDownMenu which is after all these years probably the biggest source of taints. Unfortunately they aren't the only source of taints in this addon so I didn't bother using Libs to prevent the taints happening. If you happen to find other sources of taints in this addon, I'm more than happy to patch it and replace the DropDownMenus with taint free Lib-versions.
