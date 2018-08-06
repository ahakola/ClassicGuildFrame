# Classic Guild Frame

Restores the look and functionality of the old GuildUI, but adds minimized Chat from the new CommunitiesUI.

## ABOUT TAINTS
Unlike the previous versions with custom UI, this new version uses Blizzard's own `Blizzard_GuildUI` and `Blizzard_Communities` and **should** be taint-free. In my own tests, everything worked and I couldn't find any taints, but if you run into any taints or other errors, please let me know.
The drawbacks of this new hooking method are the playing both frame showing and closing -sounds at the same time when you change from `Chat` to any other tab or vice versa and I had to get rid of the `Always open to Default Tab` -option, because it was getting too hard for me to wrap my head around the logic at the time of rewriting this addon. If you find a good solution to this, I'm more than happy to reimplement the feature. IMHO these are acceptable losses for getting rid of the taints.