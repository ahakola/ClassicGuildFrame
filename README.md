# Classic Guild Frame

Restores the look and functionality of the old GuildUI by changing the look of the new CommunitiesUI with the added bonus of the `Chat`.

* Looks should be pretty close to the original GuildUI. Few minor changes and different element sizes here and there.
   * Currently `Roster` is the only tab that isn't styled like the GuildUI's, because that one would be hard to do. I might take a look at it someday later.
* You can select which tabs you want to Enable/Disable, incase you don't ever want to go to some of the tabs and don't mind to see them gone.
* You can select to which tab the addon opens instead of the game's default `Chat`
   * Addon will open to the Default-tab the first time of your game session when you open your CommunitiesUI. After that the addon opens to the last open tab.
   * If you enable `Always open to Default Tab` then the addon will open to your Default-tab every time you open the CommunitiesUI.
* You can have the `Chat`-tab glow if you have unread messages in your communities.

## ABOUT TAINTS
Unlike the previous versions with either custom UI (v1.0) or replaced ShowUIPanel-function (v1.1), this new version (v1.2) is built completely by reusing Blizzard's own `Blizzard_Communities` elements and is **mostly** taint-free. So far there has been only one taint found on setting guild notes to players, but if you run into any errors, please let me know.

### SetNote-taint
At the moment there isn't fix for this because I don't know what part of my addon causes this taint. So if you want to set/change guild notes, you have to disable this addon or ask someone else to change the notes. If you know what causes or how to fix this taint, please let me know.

In game version 8.2 taintlog level 2 gives following information:

```
9/10 17:36:44.562  Interface\FrameXML\StaticPopup.lua:5042 StaticPopup_OnClick()
9/10 17:36:44.562  An action was blocked because of taint from ClassicGuildFrame - SetNote()
9/10 17:36:44.562      Interface\FrameXML\StaticPopup.lua:2783 OnAccept()
9/10 17:36:44.562      Interface\FrameXML\StaticPopup.lua:5074 StaticPopup_OnClick()
9/10 17:36:44.562      StaticPopup1Button1:OnClick()
```

## Translations
You can help translate the addon by heading to the Curseforge's [Translation tool](https://www.curseforge.com/wow/addons/classic-guild-frame/localization) and PM me to let me know there are new translations (the new Curseforge-site makes it really hard to keep track of what has been done to the translations).

* Russian: **Hubbotu**

## Errors, feature requests etc.
Post them to the Curseforge's [Issue tracker](https://www.curseforge.com/wow/addons/classic-guild-frame/issues) and try to include as much info as possible related to your issue. You can use ingame command `/console scriptErrors 1` to turn Lua-errors on.

## Known Bugs
Bugs listed here are known, but I don't have know-how on how to fix them. Please don't report these to the issue tracker, but if you know how to fix these, don't hesitate to contact me.

- If you use ElvUI and use the default-setting of letting ElvUI skin CommunitiesUI, the `News`-tab won't have backdrop and the `Info`-tab will have the News-backdrop hovering on the side of the CommunitiesFrame. This is because the ElvUI skin's News-backdrop is attached to the `Info`-container of the CommunitiesUI instead of the `News`-container itself.