local _, GW = ...
local round = GW.round
local lerp = GW.lerp

local blockIndex = 0
local waitForUpdate = false
local updatedThisFrame = false
local blocks = {}
local savedQuests = {}

GW_TRAKCER_TYPE_COLOR = {}
GW_TRAKCER_TYPE_COLOR['QUEST'] ={r=221/255,g=198/255,b=68/255}
GW_TRAKCER_TYPE_COLOR['EVENT'] ={r=240/255,g=121/255,b=37/255}
GW_TRAKCER_TYPE_COLOR['BONUS'] ={r=240/255,g=121/255,b=37/255}
GW_TRAKCER_TYPE_COLOR['SCENARIO'] ={r=171/255,g=37/255,b=240/255}
GW_TRAKCER_TYPE_COLOR['BOSS'] ={r=240/255,g=37/255,b=37/255}
GW_TRAKCER_TYPE_COLOR['ACHIEVEMENT'] ={r=37/255,g=240/255,b=172/255}



function gw_animate_wiggle(self)
    if self.animation==nil then self.animation = 0 end
    if self.doingAnimation == true then return end
    self.doingAnimation = true
    addToAnimation(self:GetName(),0,1,GetTime(),2,function()
       
       
            
        local prog = animations[self:GetName()]['progress']
            
         self.flare:SetRotation(lerp(0,1,prog))
        
        if prog<0.25 then
            self.texture:SetRotation( lerp(0,-0.5,math.sin((prog/0.25) * math.pi * 0.5) ))
            self.flare:SetAlpha(lerp(0,1,math.sin((prog/0.25) * math.pi * 0.5) ))
        end
        if prog>0.25 and prog<0.75 then
             self.texture:SetRotation(lerp(-0.5,0.5, math.sin(((prog - 0.25)/0.5) * math.pi * 0.5)  ))
           
        end
        if prog>0.75 then
            self.texture:SetRotation(lerp(0.5,0, math.sin(((prog - 0.75)/0.25) * math.pi * 0.5)  ))
        end
            
        if prog>0.25 then
         self.flare:SetAlpha(lerp(1,0,((prog - 0.25)/0.75)))
        end
          
    end,nil,function() self.doingAnimation = false end)
    
end


function gwNewQuestAnimation(block)
    block.flare:Show()
    block.flare:SetAlpha(1)
    addToAnimation(block:GetName()..'flare',0,1,GetTime(),1,function(step)
        block:SetWidth(300*step)
        block.flare:SetSize(300*(1 - step),300*(1 - step) )
        block.flare:SetRotation(2*step)
            
        if step>0.75 then
            block.flare:SetAlpha( (step - 0.75)/0.25)     
        end
            
    end, nil, function() 
        block.flare:Hide()    
    end)

end

local function loadQuestButtons()
    local actionButton = nil
    for i = 1, 25 do
        actionButton = CreateFrame('Button','GwQuestItemButton'..i,GwQuestTracker,'GwQuestItemTemplate')
        actionButton.icon:SetTexCoord(0.1,0.9,0.1,0.9)
        actionButton.NormalTexture:SetTexture(nil)
        actionButton:RegisterForClicks("AnyUp")
        actionButton:SetScript('OnShow', QuestObjectiveItem_OnHide)
        actionButton:SetScript('OnHide', QuestObjectiveItem_OnHide)
        actionButton:SetScript('OnEnter', QuestObjectiveItem_OnEnter)
    end
    
    actionButton = CreateFrame('Button','GwBonusItemButton',GwQuestTracker,'GwQuestItemTemplate')
    actionButton.icon:SetTexCoord(0.1,0.9,0.1,0.9)
    actionButton.NormalTexture:SetTexture(nil) 
    actionButton:RegisterForClicks("AnyUp")
    actionButton:SetScript('OnShow', QuestObjectiveItem_OnHide)
    actionButton:SetScript('OnHide', QuestObjectiveItem_OnHide)
    actionButton:SetScript('OnEnter', QuestObjectiveItem_OnEnter)
    
    actionButton = CreateFrame('Button','GwScenarioItemButton',GwQuestTracker,'GwQuestItemTemplate')
    actionButton.icon:SetTexCoord(0.1,0.9,0.1,0.9)
    actionButton.NormalTexture:SetTexture(nil)
    actionButton:RegisterForClicks("AnyUp")
    actionButton:SetScript('OnShow', QuestObjectiveItem_OnHide)
    actionButton:SetScript('OnHide', QuestObjectiveItem_OnHide)
    actionButton:SetScript('OnEnter', QuestObjectiveItem_OnEnter)
end


function gwParseSimpleObjective(text)
    
    local  itemName, numItems, numNeeded = string.match(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
   
    if itemName==nil then
        numItems,numNeeded,itemName = string.match(text, "(%d+)/(%d+) (%S+)");
    end
    local ndString = ''
    
    if numItems~=nil then ndString = numItems end
    
    if numNeeded~=nil then ndString = ndString..'/'..numNeeded end
    
   return string.gsub(text, ndString, '')
    
   
end

function gw_parse_criteria(quantity, totalQuantity,criteriaString)
    
    if quantity~=nil and totalQuantity~=nil and criteriaString~=nil then
       return string.format("%d/%d %s", quantity, totalQuantity, criteriaString);
    end
     
    return criteriaString
end

function GwParseObjectiveString(block, text, objectiveType,quantity)
    
    if objectiveType=='progressbar' then
        block.StatusBar:SetMinMaxValues(0, 100)
        block.StatusBar:SetValue(quantity)
        block.StatusBar:Show()
        block.StatusBar.precentage = true
        return true
    end
    block.StatusBar.precentage = false
    local itemName, numItems, numNeeded = string.match(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
    if numItems==nil then
        numItems,numNeeded,itemName = string.match(text, "(%d+)/(%d+) (%S+)");
    end
    numItems= tonumber(numItems)
    numNeeded= tonumber(numNeeded)
    
    if numItems~=nil and numNeeded~=nil and numNeeded>1 and numItems<numNeeded then

        block.StatusBar:Show()
        block.StatusBar:SetMinMaxValues(0, numNeeded)
        block.StatusBar:SetValue(numItems)
        block.progress = numItems/numNeeded
        return true
    end
    return false
end

function GwFormatObjectiveNumbers(text)

   local  itemName, numItems, numNeeded = string.match(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
   
    if itemName==nil then
        numItems,numNeeded,itemName = string.match(text, "(%d+)/(%d+) ((.*))");
    end
    numItems= tonumber(numItems)
    numNeeded= tonumber(numNeeded)
    
    if numItems~=nil and numNeeded~=nil then

        return GW.comma_value(numItems)..' / '..GW.comma_value(numNeeded)..' '..itemName
    end
    return text
end

local function setBlockColor(block, string)
    block.color = GW_TRAKCER_TYPE_COLOR[string]
end


local function statusBarOnShow(self)
    local f = self:GetParent()
    if not f then return end
    f:SetHeight(50)
    f.statusbarBg:Show()
end
local function statusBarOnHide(self)
    local f = self:GetParent()
    if not f then return end
    f:SetHeight(20)
    f.statusbarBg:Hide()
end
local function statusBarSetValue(self)
    local f = self:GetParent()
    if not f then return end
    local min, max = self:GetMinMaxValues()
    local v = self:GetValue()
    local width = math.max(1, math.min(10, 10 * ((v / max) /0.1)))
    f.StatusBar.Spark:SetPoint('RIGHT', self, 'LEFT', 280 * (v / max), 0)
    f.StatusBar.Spark:SetWidth(width)
    if self.precentage == nil or self.precentage == false then
        self.progress:SetText(v .. ' / ' .. max)
    else
        self.progress:SetText(math.floor((v / max) * 100) .. '%')
    end
end
function gwCreateObjectiveNormal(name, parent)
    local f = CreateFrame('Frame', name, parent, 'GwQuesttrackerObjectiveNormal')
    f.ObjectiveText:SetFont(UNIT_NAME_FONT, 12)
    f.ObjectiveText:SetShadowOffset(-1, 1)
    f.StatusBar.progress:SetFont(UNIT_NAME_FONT, 11)
    f.StatusBar.progress:SetShadowOffset(-1, 1)
    if f.StatusBar.animationOld == nil then
        f.StatusBar.animationOld = 0
    end
    f.StatusBar:SetScript('OnShow', statusBarOnShow)
    f.StatusBar:SetScript('OnHide', statusBarOnHide)
    hooksecurefunc(f.StatusBar, 'SetValue', statusBarSetValue)

    return f
end

function gwCreateTrackerObject(name, parent)
    local f = CreateFrame('Button', name, parent, 'GwQuesttrackerObject')
    f.Header:SetFont(UNIT_NAME_FONT, 14)
    f.SubHeader:SetFont(UNIT_NAME_FONT, 12)
    f.Header:SetShadowOffset(1, -1)
    f.SubHeader:SetShadowOffset(1, -1)
    f:SetScript('OnEnter', function(self)
        self.hover:Show()
        if self.objectiveBlocks == nil then
            self.objectiveBlocks = {}
        end
        for k, v in pairs(self.objectiveBlocks) do
            v.StatusBar.progress:Show()
        end
        addToAnimation(self:GetName() .. 'hover', 0, 1, GetTime(), 0.2, function(step)
            self.hover:SetAlpha(step - 0.3)
            self.hover:SetTexCoord(0, step, 0, 1)
        end)
    end)
    f:SetScript('OnLeave', function(self)
        self.hover:Hide()
        if self.objectiveBlocks == nil then
            self.objectiveBlocks = {}
        end
        for k, v in pairs(self.objectiveBlocks) do
            v.StatusBar.progress:Hide()
        end
        if animations[self:GetName() .. 'hover'] ~= nil then
            animations[self:GetName() .. 'hover']['complete'] = true
        end
    end)
    f.clickHeader:SetScript('OnEnter', function(self)
        self.oldColor = {}
        self.oldColor.r, self.oldColor.g, self.oldColor.b = self:GetParent().Header:GetTextColor()
        self:GetParent().Header:SetTextColor(self.oldColor.r * 2, self.oldColor.g * 2, self.oldColor.b * 2)
    end)
    f.clickHeader:SetScript('OnLeave', function(self)
        if self.oldColor == nil then return end
        self:GetParent().Header:SetTextColor(self.oldColor.r, self.oldColor.g, self.oldColor.b)
    end)
    f.turnin:SetScript('OnShow', function(self)
        self:SetScript('OnUpdate', gw_animate_wiggle)
    end)
    f.turnin:SetScript('OnHide', function(self)
        self:SetScript('OnUpdate', nil)
    end)
    
    return f
end

local function getObjectiveBlock(self,index)
    
   
    if _G[self:GetName()..'GwQuestObjective'..index]~=nil then return _G[self:GetName()..'GwQuestObjective'..index] end
    
    if self.objectiveBlocksNum==nil then self.objectiveBlocksNum = 0 end
    if self.objectiveBlocks==nil then self.objectiveBlocks = {} end
    
    self.objectiveBlocksNum = self.objectiveBlocksNum + 1
    
    local newBlock = gwCreateObjectiveNormal(self:GetName() .. 'GwQuestObjective' .. self.objectiveBlocksNum, self)
    newBlock:SetParent(self)
    self.objectiveBlocks[#self.objectiveBlocks] = newBlock
    if self.objectiveBlocksNum==1 then
        newBlock:SetPoint('TOPRIGHT',self,'TOPRIGHT',0,-25) 
    else
        newBlock:SetPoint('TOPRIGHT',_G[self:GetName()..'GwQuestObjective'..(self.objectiveBlocksNum - 1)],'BOTTOMRIGHT',0,0) 
    end
    
    newBlock.StatusBar:SetStatusBarColor(self.color.r,self.color.g,self.color.b)

    
    return newBlock
end

local function getBlock(blockIndex)
    if _G['GwQuestBlock'..blockIndex]~=nil then return _G['GwQuestBlock'..blockIndex] end
    
    local newBlock = gwCreateTrackerObject('GwQuestBlock' .. blockIndex, GwQuesttrackerContainerQuests)
    newBlock:SetParent(GwQuesttrackerContainerQuests)

    if blockIndex==1 then
        newBlock:SetPoint('TOPRIGHT',GwQuesttrackerContainerQuests,'TOPRIGHT',0,-20) 
    else
        newBlock:SetPoint('TOPRIGHT',_G['GwQuestBlock'..(blockIndex - 1)],'BOTTOMRIGHT',0,0) 
    end
    newBlock.clickHeader:Show() 
    setBlockColor(newBlock,'QUEST')
    newBlock.Header:SetTextColor(newBlock.color.r,newBlock.color.g,newBlock.color.b)
    newBlock.hover:SetVertexColor(newBlock.color.r,newBlock.color.g,newBlock.color.b)
    return newBlock
end

local function addObjective(block,text,finished,objectiveIndex) 
    
    
   if finished==true then return end
    local objectiveBlock = getObjectiveBlock(block,objectiveIndex)
    
    if text  then
       
        objectiveBlock:Show()
        objectiveBlock.ObjectiveText:SetText(text)
        if finished then
            objectiveBlock.ObjectiveText:SetTextColor(0.8,0.8,0.8)
        else
            objectiveBlock.ObjectiveText:SetTextColor(1,1,1)
        end
        
        if objectiveType=='progressbar' or GwParseObjectiveString(objectiveBlock, text) then
            if objectiveType=='progressbar' then
                objectiveBlock.StatusBar:Show()
                objectiveBlock.StatusBar:SetMinMaxValues(0, 100)
                objectiveBlock.StatusBar:SetValue(GetQuestProgressBarPercent(block.questID))
            end
        else
            objectiveBlock.StatusBar:Hide()
        end
        local h = 20
        if objectiveBlock.StatusBar:IsShown() then h = 50 end
        block.height = block.height + h
        block.numObjectives = block.numObjectives + 1
    end
    
end

local function updateQuestObjective(block, numObjectives, isComplete, title)
    local addedObjectives = 1
    local objectiveText = ''
    for objectiveIndex = 1, numObjectives do
        local text, objectiveType, finished = GetQuestLogLeaderBoard(objectiveIndex, block.questLogIndex)
        if not finished then
            addObjective(block, text, finished, addedObjectives)
            addedObjectives = addedObjectives + 1
        end
    end
end

function GwupdateQuestItem(button,questLogIndex)
    
    if InCombatLockdown() then return end
    
    if button==nil then return end
    
    local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex); 
    
    if item==nil then   button:Hide()   return end
    
    
    button:SetID(questLogIndex);

    button:SetAttribute("type",'item')
    button:SetAttribute('item',GetItemInfo(link))

    
    button.charges =  charges;
    button.rangeTimer = -1;
    SetItemButtonTexture(button,  item);
    SetItemButtonCount(button,  charges);
    
	
    QuestObjectiveItem_UpdateCooldown(button);
    button:Show();
    
    
end


local function quest_update_POI(questID,questLogIndex)
    
	
     PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON  );

	if ( IsQuestWatched(questLogIndex) ) then
		if ( IsShiftKeyDown() ) then
			QuestObjectiveTracker_UntrackQuest(nil, questID);
			return;
		end
	else
		AddQuestWatch(questLogIndex, true);
	end
	SetSuperTrackedQuestID(questID);
	WorldMapFrame_OnUserChangedSuperTrackedQuest(questID);
end


local function updateQuest(block, questWatchId)
    block.height = 25
    block.numObjectives = 0
    block.turnin:Hide()
    
    local questID, title, questLogIndex, numObjectives, requiredMoney, isComplete, startEvent,  isAutoComplete, failureTime, timeElapsed, questType, isTask, isStory, isOnMap, hasLocalPOI = GetQuestWatchInfo(questWatchId);

    if questID then
        
        if savedQuests[questID]==nil then
            
            gwNewQuestAnimation(block)
        
            savedQuests[questID] = true
        end
        
        block.questID = questID
        block.questLogIndex = questLogIndex
        
        block.Header:SetText(title)

        --Quest item
       
        GwupdateQuestItem(_G['GwQuestItemButton'..questWatchId],questLogIndex)
        
 

        if isComplete and isComplete < 0 then
            isComplete = false
			questFailed = true
        elseif numObjectives == 0 and GetMoney() >= requiredMoney and not startEvent then
            isComplete = true
        end
                
        updateQuestObjective(block, numObjectives, isComplete, title)
               
        if requiredMoney~=nil and requiredMoney > GetMoney() then
           addObjective(block, GetMoneyString(GetMoney()) .. " / " .. GetMoneyString(requiredMoney), finished, block.numObjectives + 1)
        end
        
        if isComplete then
            if isAutoComplete then
                addObjective(block, QUEST_WATCH_CLICK_TO_COMPLETE, false, block.numObjectives + 1)
                block.turnin:Show()
                block.turnin:SetScript('OnClick', function() ShowQuestComplete(questLogIndex) end)
            else
                local completionText = GetQuestLogCompletionText(questLogIndex);
            
                if ( completionText ) then
                    addObjective(block, completionText, false, block.numObjectives +1 ) 
                else
                    addObjective(block, QUEST_WATCH_QUEST_READY, false, block.numObjectives + 1)
                end
            end
            
        end
        
        block.clickHeader:SetScript('OnClick', function() quest_update_POI(questID,questLogIndex) end)
        block:SetScript('OnClick', function() 
                QuestLogPopupDetailFrame_Show(questLogIndex);
        end)
             
    end
    if block.objectiveBlocks==nil then block.objectiveBlocks = {} end
    
    for  i=block.numObjectives + 1, 20 do
        if _G[block:GetName()..'GwQuestObjective'..i]~=nil then
            _G[block:GetName()..'GwQuestObjective'..i]:Hide()
        end
    end
    block.height = block.height + 5 
    block:SetHeight(block.height)
    
end

local function updateQuestItemPositions(index, height)
    
    if _G['GwQuestItemButton'..index]==nil then return end
    
    if InCombatLockdown() then return end
    
    height = height + GwQuesttrackerContainerScenario:GetHeight() + 25
    height = height + GwQuesttrackerContainerAchievement:GetHeight() 
    
    if GwObjectivesNotification:IsShown() then height = height + 70 end
    
    _G['GwQuestItemButton'..index]:SetPoint('TOPLEFT',GwQuestTracker,'TOPRIGHT',-330, -height)
    
    
end

local function updateExtraQuestItemPositions()
 
    if GwBonusItemButton==nil or GwScenarioItemButton==nil then return end
    
    if InCombatLockdown() then return end

    local height = 0

    if GwObjectivesNotification:IsShown() then height = height + 70 end
    
    GwScenarioItemButton:SetPoint('TOPLEFT',GwQuestTracker,'TOPRIGHT',-330, -height)
    
    height = height + GwQuesttrackerContainerScenario:GetHeight() + GwQuesttrackerContainerQuests:GetHeight() + GwQuesttrackerContainerAchievement:GetHeight() + GwQuesttrackerContainerAchievement:GetHeight()
    
    GwBonusItemButton:SetPoint('TOPLEFT',GwQuestTracker,'TOPRIGHT',-330, -height + -25)
end



local function updateQuestLogLayout(intent, ...)
    local savedHeight = 1
    GwQuestHeader:Hide()
    
    local numQuests = GetNumQuestWatches()
    if GwQuesttrackerContainerQuests.collapsed==true then
        GwQuestHeader:Show()
        numQuests = 0
        savedHeight = 20
    end
    
    for i = 1, numQuests do    
        if i==1 then savedHeight = 20 end
        GwQuestHeader:Show()
        local block = getBlock(i)
        if block==nil then return end
        updateQuest(block, i)
        block:Show()
        updateQuestItemPositions(i,savedHeight)
        
        savedHeight =savedHeight + block.height
       
    end
    GwQuesttrackerContainerQuests:SetHeight(savedHeight)
    for i=numQuests + 1,25 do
        if _G['GwQuestBlock'..i]~=nil then
           _G['GwQuestBlock'..i]:Hide() 
            GwupdateQuestItem(_G['GwQuestItemButton'..i],0) 
        end
    end
    
    gwQuestTrackerLayoutChanged()
    
end

function gwRequestQustlogUpdate()
    updateQuestLogLayout()
end

function gwQuestTrackerLayoutChanged()
    updateExtraQuestItemPositions()
    GwQuestTrackerScroll:SetSize(400,GwQuesttrackerContainerBonusObjectives:GetHeight() + GwQuesttrackerContainerQuests:GetHeight())
end

function gwTrackerOnEvent(self, event, ...)
    updateQuestLogLayout(...)
end

function gw_tracker_onUpdate(self)
    if GwQuestTracker.trot < GetTime() then                
        local state = GwObjectivesNotification.shouldDisplay
            
        GwQuestTracker.trot = GetTime() + 1
        gwSetObjectiveNotification() 
           
        if state ~= GwObjectivesNotification.shouldDisplay then
            state = GwObjectivesNotification.shouldDisplay
            gwNotificationStateChanged(state)
        end
    end
end
local function bonusBarOnEnter(self)
    GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT', 0, 0)
    GameTooltip:ClearLines()
    GameTooltip:SetText(round(self.progress * 100, 0) .. '%')
    GameTooltip:Show()
end
local function bonusBarOnLeave(self)
    GameTooltip:Hide()
end
function gw_load_questTracker()    
    ObjectiveTrackerFrame:Hide()
    ObjectiveTrackerFrame:SetScript('OnShow', function() ObjectiveTrackerFrame:Hide() end) 
    
    local fTracker = CreateFrame('Frame', 'GwQuestTracker', UIParent, 'GwQuestTracker')
    
    local fTraScr = CreateFrame('ScrollFrame', 'GwQuestTrackerScroll', fTracker, 'GwQuestTrackerScroll')
    fTraScr:SetScript('OnMouseWheel', function(self, delta)
        delta = -delta * 15
        local s = math.max(0, self:GetVerticalScroll() + delta)
        self:SetVerticalScroll(s)
    end)

    local fScroll = CreateFrame('Frame', 'GwQuestTrackerScrollChild', fTraScr, 'GwQuestTracker')
    
    local fNotify = CreateFrame('Frame', 'GwObjectivesNotification', fTracker, 'GwObjectivesNotification')
    fNotify.animatingState = false
    fNotify.animating = false
    fNotify.title:SetFont(UNIT_NAME_FONT, 14)
    fNotify.title:SetShadowOffset(1, -1)
    fNotify.desc:SetFont(UNIT_NAME_FONT, 12)
    fNotify.desc:SetShadowOffset(1, -1)    
    fNotify.bonusbar.bar:SetOrientation('VERTICAL')
    fNotify.bonusbar.bar:SetMinMaxValues(0, 1)
    fNotify.bonusbar.bar:SetValue(0.5)
    fNotify.bonusbar:SetScript('OnEnter', bonusBarOnEnter)
    fNotify.bonusbar:SetScript('OnLeave', bonusBarOnLeave)
    fNotify.compass:SetScript('OnShow', gwNewQuestAnimation)
    
    local fBoss = CreateFrame('Frame', 'GwQuesttrackerContainerBossFrames', fTracker, 'GwQuesttrackerContainer') 
    local fScen = CreateFrame('Frame', 'GwQuesttrackerContainerScenario', fTracker, 'GwQuesttrackerContainer') 
    local fAchv = CreateFrame('Frame', 'GwQuesttrackerContainerAchievement', fTracker, 'GwQuesttrackerContainer')     
    local fQuest = CreateFrame('Frame', 'GwQuesttrackerContainerQuests', fScroll, 'GwQuesttrackerContainer') 
    local fBonus = CreateFrame('Frame', 'GwQuesttrackerContainerBonusObjectives', fScroll, 'GwQuesttrackerContainer')
    fAchv:SetParent(fScroll)
    fQuest:SetParent(fScroll)
    fBonus:SetParent(fScroll)
    
    if gwGetSetting('MINIMAP_ENABLED') then
        fTracker:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT')
        fTracker:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT')
    else
        fTracker:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT')
        fTracker:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT')
    end
    
    fNotify:SetPoint('TOPRIGHT', fTracker, 'TOPRIGHT')
    fBoss:SetPoint('TOPRIGHT', fNotify, 'BOTTOMRIGHT')
    fScen:SetPoint('TOPRIGHT', fBoss,'BOTTOMRIGHT')
    
    fTraScr:SetPoint('TOPRIGHT', fScen, 'BOTTOMRIGHT')
    fTraScr:SetPoint('BOTTOMRIGHT', fTracker, 'BOTTOMRIGHT')
    
    fScroll:SetPoint('TOPRIGHT', fTraScr, 'TOPRIGHT')
    fAchv:SetPoint('TOPRIGHT', fScroll, 'TOPRIGHT')
    fQuest:SetPoint('TOPRIGHT', fAchv, 'BOTTOMRIGHT')
    fBonus:SetPoint('TOPRIGHT', fQuest, 'BOTTOMRIGHT')
    
    fScroll:SetSize(400, 2)
    fTraScr:SetScrollChild(fScroll)

    fQuest:SetScript('OnEvent', gwTrackerOnEvent)
    fQuest:RegisterEvent('QUEST_LOG_UPDATE')
    fQuest:RegisterEvent('QUEST_ITEM_UPDATE')
	fQuest:RegisterEvent('QUEST_REMOVED')
	fQuest:RegisterEvent('QUESTLINE_UPDATE')
	fQuest:RegisterEvent('TASK_PROGRESS_UPDATE')
    fQuest:RegisterEvent('QUEST_WATCH_LIST_CHANGED')
	fQuest:RegisterEvent('QUEST_AUTOCOMPLETE')
	fQuest:RegisterEvent('QUEST_ACCEPTED')
    fQuest:RegisterEvent('QUEST_GREETING')
	fQuest:RegisterEvent('QUEST_DETAIL')
	fQuest:RegisterEvent('QUEST_PROGRESS')
	fQuest:RegisterEvent('QUEST_COMPLETE')
	fQuest:RegisterEvent('QUEST_FINISHED')
	fQuest:RegisterEvent('QUEST_POI_UPDATE')
	fQuest:RegisterEvent('PLAYER_MONEY')
	fQuest:RegisterEvent('SUPER_TRACKED_QUEST_CHANGED')
    
    local header = CreateFrame('Button', 'GwQuestHeader', fQuest, 'GwQuestTrackerHeader')
    header.icon:SetTexCoord(0, 1, 0.25, 0.5)
    header.title:SetFont(UNIT_NAME_FONT, 14)
    header.title:SetShadowOffset(1, -1)
    header.title:SetText(GwLocalization['TRACKER_QUEST_TITLE'])
    
    header:SetScript('OnClick', function(self)
        local p = self:GetParent()
        if p.collapsed == nil or p.collapsed == false then
            p.collapsed = true
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        else
            p.collapsed = false
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end    
        updateQuestLogLayout('COLLAPSE')
    end)
    header.title:SetTextColor(GW_TRAKCER_TYPE_COLOR['QUEST'].r, GW_TRAKCER_TYPE_COLOR['QUEST'].g, GW_TRAKCER_TYPE_COLOR['QUEST'].b)
   
    loadQuestButtons()
    updateQuestLogLayout('LOAD')
    
    gw_register_bossFrames()
    gw_register_scenarioFrame()
    gw_register_achievement()
    gw_register_bonusObjectiveFrame()
    
    fNotify.shouldDisplay = false
    fTracker.trot = GetTime() + 2
    fTracker:SetScript('OnUpdate', gw_tracker_onUpdate)
end
