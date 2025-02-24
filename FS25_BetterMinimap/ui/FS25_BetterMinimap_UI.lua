--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25: SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 22.02.2025
-- @Version: 1.0.0.0

local myName = "FS25_BetterMinimap_UI"

FS25_BetterMinimap_UI = {}
local FS25_BetterMinimap_UI_mt = Class(FS25_BetterMinimap_UI, ScreenElement)

function FS25_BetterMinimap_UI:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ConfigGui_mt;
    end ;
    local self = ScreenElement:new(target, custom_mt);
    self.returnScreenName = "";
    return self;
end

function FS25_BetterMinimap_UI:onOpen()
    FS25_BetterMinimap_UI:superClass().onOpen(self);

    self.isVisible:setIsChecked(FS25_BetterMinimap.settings.visible);
    self.help:setIsChecked(FS25_BetterMinimap.settings.help_min);
    self.activeFreq:setState(FS25_BetterMinimap.settings.frequency, false);
    self.activeSizemode:setState(FS25_BetterMinimap.settings.sizeMode, false);
    self.isTransparent:setIsChecked(FS25_BetterMinimap.settings.transparent);
    self.transMode:setState(FS25_BetterMinimap.settings.transMode, false);
end

function FS25_BetterMinimap_UI:onClose()
    FS25_BetterMinimap_UI:superClass().onClose(self);
end;

function FS25_BetterMinimap_UI:onClickBack()
    FS25_BetterMinimap_UI:superClass().onClickBack(self);
end;

function FS25_BetterMinimap_UI:onClickOk()
    FS25_BetterMinimap_UI:superClass().onClickOk(self);

    FS25_BetterMinimap.settings.visible = self.isVisible:getIsChecked();
    FS25_BetterMinimap.settings.help_min = self.help:getIsChecked();
    FS25_BetterMinimap.settings.frequency = self.activeFreq:getState();
    FS25_BetterMinimap.settings.sizeMode = self.activeSizemode:getState();
    FS25_BetterMinimap.settings.transparent = self.isTransparent:getIsChecked();
    FS25_BetterMinimap.settings.transMode = self.transMode:getState();

    -- mapUpdate
    FS25_BetterMinimap.settings.mapUpdate = true;
    -- saveToXML
    FS25_BetterMinimap.settings.saveSettings = true;
    -- close dialog
    self:onClickBack();
end;

function FS25_BetterMinimap_UI:setHelpBoxText(text)
    self.ingameMenuHelpBoxText:setText(text);
    self.ingameMenuHelpBox:setVisible(text ~= "");
end;

function FS25_BetterMinimap_UI:onFocusElement(element)
    if (element.toolTip ~= nil) then
        self:setHelpBoxText(element.toolTip);
    end ;
end;

function FS25_BetterMinimap_UI:onLeaveElement(element)
    self:setHelpBoxText("");
end;

--- Events ---
function FS25_BetterMinimap_UI:onToggleVisible(element)
    self.isVisible = element;
end;

function FS25_BetterMinimap_UI:onToggleHelp(element)
    self.help = element;
end;

function FS25_BetterMinimap_UI:onChangeFrequency(element)
    self.activeFreq = element;
    local freq = {};
    for i = 1, table.getn(BM.const.frequency), 1 do
        freq[i] = tostring(BM.const.frequency[i]) .. "s";
    end
    element:setTexts(freq);
end;

function FS25_BetterMinimap_UI:onChangeSizemode(element)
    self.activeSizemode = element;
    local sm = {};
    for i = 1, table.getn(BM.const.mapNames), 1 do
        sm[i] = tostring(BM.const.mapNames[i]);
    end
    element:setTexts(sm);
end;

function FS25_BetterMinimap_UI:onToggleTransparent(element)
    self.isTransparent = element;
end;

function FS25_BetterMinimap_UI:onChangeTransMode(element)
    self.transMode = element;
    local tm = {};
    for i = 1, table.getn(BM.const.transparent), 1 do
        tm[i] = tostring(BM.const.transparent[i]);
    end
    element:setTexts(tm);
end;

