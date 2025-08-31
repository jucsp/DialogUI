---@diagnostic disable: undefined-global
MAX_NUM_QUESTS = 32;
MAX_NUM_ITEMS = 10;
MAX_REQUIRED_ITEMS = 6;
QUEST_DESCRIPTION_GRADIENT_LENGTH = 30;
QUEST_DESCRIPTION_GRADIENT_CPS = 40;
QUESTINFO_FADE_IN = 1;

-- DialogUI Configuration System (initialized here for early availability)
if not DialogUI_Config then
    DialogUI_Config = {
        scale = 1.0,        -- Frame scale (0.5 - 2.0)
        alpha = 1.0,        -- Frame transparency (0.1 - 1.0)
        fontSize = 1.0      -- Font size multiplier (0.5 - 2.0)
    };
end

local COLORS = {
    -- ColorKey = {r, g, b}

    DarkBrown = {0.19, 0.17, 0.13},
    LightBrown = {0.50, 0.36, 0.24},
    Ivory = {0.87, 0.86, 0.75}
};

function SetFontColor(fontObject, key)
    local color = COLORS[key];
    fontObject:SetTextColor(color[1], color[2], color[3]);
end

function DQuestFrame_OnLoad()
    this:RegisterEvent("QUEST_GREETING");
    this:RegisterEvent("QUEST_DETAIL");
    this:RegisterEvent("QUEST_PROGRESS");
    this:RegisterEvent("QUEST_COMPLETE");
    this:RegisterEvent("QUEST_FINISHED");
    this:RegisterEvent("QUEST_ITEM_UPDATE");
    this:RegisterEvent("VARIABLES_LOADED");
    
    -- Enable dragging for the quest frame - simplified approach
    this:SetMovable(true);
    this:EnableMouse(true);
    this:EnableKeyboard(true);
    
    -- Hook original quest frame functions to prevent them from showing
    DialogUI_HookOriginalQuestFunctions();
    
    -- TEMPORARILY DISABLED: Register frame with UI Panel system to handle ESC key
    -- UIPanelWindows["DQuestFrame"] = {area = "center", pushable = 0, whileDead = 1};
end

-- Functions to save and load frame position (unified for all DialogUI frames)
function DialogUI_SavePosition()
    if not DialogUIFramePosition then
        DialogUIFramePosition = {};
    end
    
    -- Save position from whichever frame is currently being moved
    local frame = this or DQuestFrame or DGossipFrame;
    if not frame then return; end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint();
    DialogUIFramePosition.point = point;
    DialogUIFramePosition.relativePoint = relativePoint;
    DialogUIFramePosition.xOfs = xOfs;
    DialogUIFramePosition.yOfs = yOfs;
    
    -- Also update the old variable for backward compatibility
    DQuestFramePosition = DialogUIFramePosition;
end

function DialogUI_LoadPosition(frame)
    -- Check both new and old variable names for backward compatibility
    local position = DialogUIFramePosition or DQuestFramePosition;
    
    if position and position.point and frame then
        frame:ClearAllPoints();
        frame:SetPoint(
            position.point, 
            UIParent, 
            position.relativePoint or position.point, 
            position.xOfs or 0, 
            position.yOfs or -104
        );
    end
end

function DialogUI_ApplyPositionToAllFrames()
    -- Apply the saved position to all DialogUI frames
    if DQuestFrame then
        DialogUI_LoadPosition(DQuestFrame);
    end
    if DGossipFrame then
        DialogUI_LoadPosition(DGossipFrame);
    end
end

-- Legacy functions for backward compatibility
function DQuestFrame_SavePosition()
    DialogUI_SavePosition();
end

function DQuestFrame_LoadPosition()
    DialogUI_LoadPosition(DQuestFrame);
end

-- Functions to handle frame movement (unified system)
function DQuestFrame_OnMouseDown()
    -- Simple and direct approach for WoW vanilla
    if (arg1 == "LeftButton") then
        this:StartMoving();
    end
end

function DQuestFrame_OnMouseUp()
    this:StopMovingOrSizing();
    -- Save the new position using the unified system
    DialogUI_SavePosition();
    -- Immediately apply the new position to the gossip frame if it exists
    if DGossipFrame then
        DialogUI_LoadPosition(DGossipFrame);
    end
end

function HideDefaultFrames()
    -- Don't call QuestFrame:Hide() - just move it off-screen and make it invisible
    -- This allows it to keep functioning but prevents visual conflicts
    if QuestFrame then
        QuestFrame:SetAlpha(0);
        QuestFrame:ClearAllPoints();
        QuestFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    
    -- Hide all original quest panels visually but let them function
    if QuestFrameGreetingPanel then
        QuestFrameGreetingPanel:SetAlpha(0);
        QuestFrameGreetingPanel:ClearAllPoints();
        QuestFrameGreetingPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestFrameDetailPanel then
        QuestFrameDetailPanel:SetAlpha(0);
        QuestFrameDetailPanel:ClearAllPoints();
        QuestFrameDetailPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestFrameProgressPanel then
        QuestFrameProgressPanel:SetAlpha(0);
        QuestFrameProgressPanel:ClearAllPoints();
        QuestFrameProgressPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestFrameRewardPanel then
        QuestFrameRewardPanel:SetAlpha(0);
        QuestFrameRewardPanel:ClearAllPoints();
        QuestFrameRewardPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestNpcNameFrame then
        QuestNpcNameFrame:SetAlpha(0);
    end
    if QuestFramePortrait then
        QuestFramePortrait:SetTexture();
        QuestFramePortrait:SetAlpha(0);
    end
    
    -- Hide the original buttons visually but let them function
    if QuestFrameCloseButton then
        QuestFrameCloseButton:SetAlpha(0);
    end
    if QuestFrameGoodbyeButton then
        QuestFrameGoodbyeButton:SetAlpha(0);
    end
    if QuestFrameAcceptButton then
        QuestFrameAcceptButton:SetAlpha(0);
    end
    if QuestFrameDeclineButton then
        QuestFrameDeclineButton:SetAlpha(0);
    end
    if QuestFrameCompleteButton then
        QuestFrameCompleteButton:SetAlpha(0);
    end
    if QuestFrameCompleteQuestButton then
        QuestFrameCompleteQuestButton:SetAlpha(0);
    end
end

-- Function to ensure original frames stay hidden while our frame is visible
function DialogUI_EnsureOriginalQuestHidden()
    -- Make the main quest frame invisible but functional
    if QuestFrame then
        QuestFrame:SetAlpha(0);
        QuestFrame:ClearAllPoints();
        QuestFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    
    -- Make all original quest panels invisible but functional
    if QuestFrameGreetingPanel then
        QuestFrameGreetingPanel:SetAlpha(0);
        QuestFrameGreetingPanel:ClearAllPoints();
        QuestFrameGreetingPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestFrameDetailPanel then
        QuestFrameDetailPanel:SetAlpha(0);
        QuestFrameDetailPanel:ClearAllPoints();
        QuestFrameDetailPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestFrameProgressPanel then
        QuestFrameProgressPanel:SetAlpha(0);
        QuestFrameProgressPanel:ClearAllPoints();
        QuestFrameProgressPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestFrameRewardPanel then
        QuestFrameRewardPanel:SetAlpha(0);
        QuestFrameRewardPanel:ClearAllPoints();
        QuestFrameRewardPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
    end
    if QuestNpcNameFrame then
        QuestNpcNameFrame:SetAlpha(0);
    end
    if QuestFramePortrait then
        QuestFramePortrait:SetTexture();
        QuestFramePortrait:SetAlpha(0);
    end
    
    -- Make the original buttons invisible but functional
    if QuestFrameCloseButton then
        QuestFrameCloseButton:SetAlpha(0);
    end
    if QuestFrameGoodbyeButton then
        QuestFrameGoodbyeButton:SetAlpha(0);
    end
    if QuestFrameAcceptButton then
        QuestFrameAcceptButton:SetAlpha(0);
    end
    if QuestFrameDeclineButton then
        QuestFrameDeclineButton:SetAlpha(0);
    end
    if QuestFrameCompleteButton then
        QuestFrameCompleteButton:SetAlpha(0);
    end
    if QuestFrameCompleteQuestButton then
        QuestFrameCompleteQuestButton:SetAlpha(0);
    end
end

-- Function to hook original WoW quest functions to prevent them from showing  
function DialogUI_HookOriginalQuestFunctions()
    -- Hook CloseWindows to handle ESC for our frame
    if not DialogUI_OriginalCloseWindows then
        DialogUI_OriginalCloseWindows = CloseWindows;
        CloseWindows = function()
            -- If our quest frame is visible, close it
            if DQuestFrame and DQuestFrame:IsVisible() then
                HideUIPanel(DQuestFrame);
                return 1; -- Return 1 to indicate we handled a window
            end
            -- Otherwise, call the original function
            return DialogUI_OriginalCloseWindows();
        end;
    end
    
    -- Hook QuestFrame:Show() to hide it immediately after it shows (but let it function)
    if QuestFrame and QuestFrame.Show and not QuestFrame.DialogUI_OriginalShow then
        QuestFrame.DialogUI_OriginalShow = QuestFrame.Show;
        QuestFrame.Show = function(self)
            -- Let the original function run (needed for functionality)
            local result = QuestFrame.DialogUI_OriginalShow(self);
            -- But immediately make it invisible and move it off-screen
            self:SetAlpha(0);
            self:ClearAllPoints();
            self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
            return result;
        end;
    end
    
    -- Hook individual panel Show functions to make them invisible immediately after showing
    if QuestFrameGreetingPanel and QuestFrameGreetingPanel.Show and not QuestFrameGreetingPanel.DialogUI_OriginalShow then
        QuestFrameGreetingPanel.DialogUI_OriginalShow = QuestFrameGreetingPanel.Show;
        QuestFrameGreetingPanel.Show = function(self)
            local result = QuestFrameGreetingPanel.DialogUI_OriginalShow(self);
            self:SetAlpha(0); -- Make invisible but keep functional
            return result;
        end;
    end
    
    if QuestFrameDetailPanel and QuestFrameDetailPanel.Show and not QuestFrameDetailPanel.DialogUI_OriginalShow then
        QuestFrameDetailPanel.DialogUI_OriginalShow = QuestFrameDetailPanel.Show;
        QuestFrameDetailPanel.Show = function(self)
            local result = QuestFrameDetailPanel.DialogUI_OriginalShow(self);
            self:SetAlpha(0); -- Make invisible but keep functional
            return result;
        end;
    end
    
    if QuestFrameProgressPanel and QuestFrameProgressPanel.Show and not QuestFrameProgressPanel.DialogUI_OriginalShow then
        QuestFrameProgressPanel.DialogUI_OriginalShow = QuestFrameProgressPanel.Show;
        QuestFrameProgressPanel.Show = function(self)
            local result = QuestFrameProgressPanel.DialogUI_OriginalShow(self);
            self:SetAlpha(0); -- Make invisible but keep functional
            return result;
        end;
    end
    
    if QuestFrameRewardPanel and QuestFrameRewardPanel.Show and not QuestFrameRewardPanel.DialogUI_OriginalShow then
        QuestFrameRewardPanel.DialogUI_OriginalShow = QuestFrameRewardPanel.Show;
        QuestFrameRewardPanel.Show = function(self)
            local result = QuestFrameRewardPanel.DialogUI_OriginalShow(self);
            self:SetAlpha(0); -- Make invisible but keep functional
            return result;
        end;
    end
end

function DQuestFrame_OnEvent(event)
    if (event == "VARIABLES_LOADED") then
        -- Load saved position when variables are loaded and apply to all frames
        DialogUI_ApplyPositionToAllFrames();
        -- Load configuration settings
        DialogUI_LoadConfig();
        -- Initialize Dynamic Camera module
        if DynamicCamera then
            DynamicCamera:Initialize();
        end
        return;
    end
    if (event == "QUEST_FINISHED") then
        -- Notify Dynamic Camera module that quest is finished
        if DynamicCamera and DynamicCamera.OnQuestFinished then
            DynamicCamera:OnQuestFinished();
        end
        HideUIPanel(DQuestFrame);
        return;
    end
    if ((event == "QUEST_ITEM_UPDATE") and not DQuestFrame:IsVisible()) then
        return;
    end

    -- Aggressively hide original frames before showing our frame
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();
    
    DQuestFrame_SetPortrait();
    ShowUIPanel(DQuestFrame);
    if (not DQuestFrame:IsVisible()) then
        CloseQuest();
        return;
    end
    
    -- Hide original frames again after showing our frame
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();
    
    if (event == "QUEST_GREETING") then
        DQuestFrameGreetingPanel:Hide();
        DQuestFrameGreetingPanel:Show();
        
        -- Ensure original frames stay hidden
        HideDefaultFrames();
        DialogUI_EnsureOriginalQuestHidden();
        
        -- Notify Dynamic Camera module
        if DynamicCamera and DynamicCamera.OnQuestDetail then
            DynamicCamera:OnQuestDetail();
        end
    elseif (event == "QUEST_DETAIL") then
        DQuestFrameDetailPanel:Hide();
        DQuestFrameDetailPanel:Show();
        
        -- Ensure original frames stay hidden
        HideDefaultFrames();
        DialogUI_EnsureOriginalQuestHidden();
        
        -- Notify Dynamic Camera module
        if DynamicCamera and DynamicCamera.OnQuestDetail then
            DynamicCamera:OnQuestDetail();
        end
    elseif (event == "QUEST_PROGRESS") then
        DQuestFrameProgressPanel:Hide();
        DQuestFrameProgressPanel:Show();
        
        -- Ensure original frames stay hidden
        HideDefaultFrames();
        DialogUI_EnsureOriginalQuestHidden();
        
        -- Notify Dynamic Camera module
        if DynamicCamera and DynamicCamera.OnQuestDetail then
            DynamicCamera:OnQuestDetail();
        end
    elseif (event == "QUEST_COMPLETE") then
        DQuestFrameRewardPanel:Hide();
        DQuestFrameRewardPanel:Show();
        
        -- Ensure original frames stay hidden
        HideDefaultFrames();
        DialogUI_EnsureOriginalQuestHidden();
        
        -- Notify Dynamic Camera module
        if DynamicCamera and DynamicCamera.OnQuestDetail then
            DynamicCamera:OnQuestDetail();
        end
    elseif (event == "QUEST_ITEM_UPDATE") then
        if (DQuestFrameDetailPanel:IsVisible()) then
            DQuestFrameItems_Update("DQuestDetail");
            DQuestDetailScrollFrame:UpdateScrollChildRect();
            DQuestDetailScrollFrameScrollBar:SetValue(0);
        elseif (DQuestFrameProgressPanel:IsVisible()) then
            DQuestFrameProgressItems_Update()
            DQuestProgressScrollFrame:UpdateScrollChildRect();
            DQuestProgressScrollFrameScrollBar:SetValue(0);
        elseif (DQuestFrameRewardPanel:IsVisible()) then
            DQuestFrameItems_Update("DQuestReward");
            DQuestRewardScrollFrame:UpdateScrollChildRect();
            DQuestRewardScrollFrameScrollBar:SetValue(0);
        end
    end
end

function DQuestFrame_SetPortrait()
    DQuestFrameNpcNameText:SetText(UnitName("npc"));
    if (UnitExists("npc")) then
        SetPortraitTexture(DQuestFramePortrait, "npc");
    else
        DQuestFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
    end
end

function DQuestFrameRewardPanel_OnShow()
    DQuestFrameDetailPanel:Hide();
    DQuestFrameGreetingPanel:Hide();
    DQuestFrameProgressPanel:Hide();
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();
    DQuestFrameNpcNameText:SetText(GetTitleText());
    DQuestRewardText:SetText(GetRewardText());
    SetFontColor(DQuestFrameNpcNameText, "DarkBrown");
    SetFontColor(DQuestRewardTitleText, "DarkBrown");
    SetFontColor(DQuestRewardText, "DarkBrown");
    DQuestFrameItems_Update("DQuestReward");
    DQuestRewardScrollFrame:UpdateScrollChildRect();
    DQuestRewardScrollFrameScrollBar:SetValue(0);
    if (QUEST_FADING_DISABLE == "0") then
        DQuestRewardScrollChildFrame:SetAlpha(0);
        UIFrameFadeIn(DQuestRewardScrollChildFrame, QUESTINFO_FADE_IN);
    end
    -- Final check to ensure original frames are hidden
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();
end

function DQuestRewardCancelButton_OnClick()
    DeclineQuest();
    PlaySound("igQuestCancel");
end

function DQuestRewardCompleteButton_OnClick()
    if (DQuestFrameRewardPanel.itemChoice == 0 and GetNumQuestChoices() > 0) then
        QuestChooseRewardError();
    else
        GetQuestReward(DQuestFrameRewardPanel.itemChoice);
        PlaySound("igQuestListComplete");
    end
end

function DQuestProgressCompleteButton_OnClick()
    CompleteQuest();
    PlaySound("igQuestListComplete");
end

function DQuestGoodbyeButton_OnClick()
    DeclineQuest();
    PlaySound("igQuestCancel");
end

function DQuestItem_OnClick()
    if (IsControlKeyDown()) then
        if (this.rewardType ~= "spell") then
            DressUpItemLink(GetQuestItemLink(this.type, this:GetID()));
        end
    elseif (IsShiftKeyDown()) then
        if (ChatFrameEditBox:IsVisible() and this.rewardType ~= "spell") then
            ChatFrameEditBox:Insert(GetQuestItemLink(this.type, this:GetID()));
        end
    end
end

function DQuestRewardItem_OnClick()
    if (IsControlKeyDown()) then
        if (this.rewardType ~= "spell") then
            DressUpItemLink(GetQuestItemLink(this.type, this:GetID()));
        end
    elseif (IsShiftKeyDown()) then
        if (ChatFrameEditBox:IsVisible()) then
            ChatFrameEditBox:Insert(GetQuestItemLink(this.type, this:GetID()));
        end
    elseif (this.type == "choice") then
        DQuestRewardItemHighlight:SetPoint("TOPLEFT", this, "TOPLEFT", -2, 5);
        DQuestRewardItemHighlight:Show();
        DQuestFrameRewardPanel.itemChoice = this:GetID();
    end
end

function DQuestFrameProgressPanel_OnShow()
    DQuestFrameRewardPanel:Hide();
    DQuestFrameDetailPanel:Hide();
    DQuestFrameGreetingPanel:Hide();
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();
    DQuestFrameNpcNameText:SetText(GetTitleText());
    DQuestProgressText:SetText(GetProgressText());
    SetFontColor(DQuestFrameNpcNameText, "DarkBrown");
    SetFontColor(DQuestProgressText, "DarkBrown");
    if (IsQuestCompletable()) then
        DQuestFrameCompleteButton:Enable();
    else
        DQuestFrameCompleteButton:Disable();
    end
    DQuestFrameProgressItems_Update();
    if (QUEST_FADING_DISABLE == "0") then
        DQuestProgressScrollChildFrame:SetAlpha(0);
        UIFrameFadeIn(DQuestProgressScrollChildFrame, QUESTINFO_FADE_IN);
    end
end

function DQuestFrameProgressItems_Update()
    local numRequiredItems = GetNumQuestItems();
    local questItemName = "DQuestProgressItem";
    if (numRequiredItems > 0 or GetQuestMoneyToGet() > 0) then
        DQuestProgressRequiredItemsText:Show();

        -- If there's money required then anchor and display it
        if (GetQuestMoneyToGet() > 0) then
            MoneyFrame_Update("DQuestProgressRequiredMoneyFrame", GetQuestMoneyToGet());

            if (GetQuestMoneyToGet() > GetMoney()) then
                -- Not enough money
                DQuestProgressRequiredMoneyText:SetTextColor(0, 0, 0);
                SetMoneyFrameColor("DQuestProgressRequiredMoneyFrame", 1.0, 0.1, 0.1);
            else
                DQuestProgressRequiredMoneyText:SetTextColor(0.2, 0.2, 0.2);
                SetMoneyFrameColor("DQuestProgressRequiredMoneyFrame", 1.0, 1.0, 1.0);
            end
            DQuestProgressRequiredMoneyText:Show();
            DQuestProgressRequiredMoneyFrame:Show();

            -- Reanchor required item
            getglobal(questItemName .. 1):SetPoint("TOPLEFT", "DQuestProgressRequiredMoneyText", "BOTTOMLEFT", 0, -10);
        else
            DQuestProgressRequiredMoneyText:Hide();
            DQuestProgressRequiredMoneyFrame:Hide();

            getglobal(questItemName .. 1):SetPoint("TOPLEFT", "DQuestProgressRequiredItemsText", "BOTTOMLEFT", -3, -5);
        end

        for i = 1, numRequiredItems, 1 do
            local requiredItem = getglobal(questItemName .. i);
            requiredItem.type = "required";
            local name, texture, numItems = GetQuestItemInfo(requiredItem.type, i);
            SetItemButtonCount(requiredItem, numItems);
            SetItemButtonTexture(requiredItem, texture);
            requiredItem:Show();
            getglobal(questItemName .. i .. "Name"):SetText(name);

        end
    else
        DQuestProgressRequiredMoneyText:Hide();
        DQuestProgressRequiredMoneyFrame:Hide();
        DQuestProgressRequiredItemsText:Hide();
    end
    for i = numRequiredItems + 1, MAX_REQUIRED_ITEMS, 1 do
        getglobal(questItemName .. i):Hide();
    end
    DQuestProgressScrollFrame:UpdateScrollChildRect();
    DQuestProgressScrollFrameScrollBar:SetValue(0);
end

function DQuestFrameGreetingPanel_OnShow()
    DQuestFrameRewardPanel:Hide();
    DQuestFrameProgressPanel:Hide();
    DQuestFrameDetailPanel:Hide();
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();

    if (QUEST_FADING_DISABLE == "0") then
        DQuestGreetingScrollChildFrame:SetAlpha(0);
        UIFrameFadeIn(DQuestGreetingScrollChildFrame, QUESTINFO_FADE_IN);
    end

    DGreetingText:SetText(GetGreetingText());
    SetFontColor(DGreetingText, "DarkBrown");
    SetFontColor(DCurrentQuestsText, "DarkBrown");
    SetFontColor(DAvailableQuestsText, "DarkBrown");
    
    local numActiveQuests = GetNumActiveQuests();
    local numAvailableQuests = GetNumAvailableQuests();
    local buttonIndex = 1; -- Counter for numbering buttons 1-9
    
    if (numActiveQuests == 0) then
        DCurrentQuestsText:Hide();
    else
        DCurrentQuestsText:SetPoint("TOPLEFT", "DGreetingText", "BOTTOMLEFT", 0, -10);
        DCurrentQuestsText:Show();
        DQuestTitleButton1:SetPoint("TOPLEFT", "DCurrentQuestsText", "BOTTOMLEFT", -10, -5);
        for i = 1, numActiveQuests, 1 do
            local questTitleButton = getglobal("DQuestTitleButton" .. i);
            -- Add number prefix (1-9) to the quest title
            local questTitle = GetActiveTitle(i);
            if (buttonIndex <= 9) then
                questTitleButton:SetText(buttonIndex .. ". " .. questTitle);
            else
                questTitleButton:SetText(questTitle);
            end
            questTitleButton:SetHeight(questTitleButton:GetTextHeight() + 20);
            questTitleButton:SetID(i);
            questTitleButton.isActive = 1;
            questTitleButton:Show();
            if (i > 1) then
                questTitleButton:SetPoint("TOPLEFT", "DQuestTitleButton" .. (i - 1), "BOTTOMLEFT", 0, 0)
            end
            buttonIndex = buttonIndex + 1;
        end
    end
    
    if (numAvailableQuests == 0) then
        DAvailableQuestsText:Hide();
    else
        if (numActiveQuests > 0) then
            DQuestGreetingFrameHorizontalBreak:SetPoint("TOPLEFT", "DQuestTitleButton" .. numActiveQuests, "BOTTOMLEFT",
                22, -10);
            DQuestGreetingFrameHorizontalBreak:Show();
            DAvailableQuestsText:SetPoint("TOPLEFT", "DQuestGreetingFrameHorizontalBreak", "BOTTOMLEFT", -12, -10);
        else
            DAvailableQuestsText:SetPoint("TOPLEFT", "DGreetingText", "BOTTOMLEFT", 0, -10);
        end
        DAvailableQuestsText:Show();
        getglobal("DQuestTitleButton" .. (numActiveQuests + 1)):SetPoint("TOPLEFT", "DAvailableQuestsText", "BOTTOMLEFT",
            -10, -5);
        for i = (numActiveQuests + 1), (numActiveQuests + numAvailableQuests), 1 do
            local questTitleButton = getglobal("DQuestTitleButton" .. i);
            -- Add number prefix (1-9) to the quest title
            local questTitle = GetAvailableTitle(i - numActiveQuests);
            if (buttonIndex <= 9) then
                questTitleButton:SetText(buttonIndex .. ". " .. questTitle);
            else
                questTitleButton:SetText(questTitle);
            end
            questTitleButton:SetHeight(questTitleButton:GetTextHeight() + 20);
            questTitleButton:SetID(i - numActiveQuests);
            questTitleButton.isActive = 0;
            questTitleButton:Show();
            if (i > numActiveQuests + 1) then
                questTitleButton:SetPoint("TOPLEFT", "DQuestTitleButton" .. (i - 1), "BOTTOMLEFT", 0, 0)
            end
            buttonIndex = buttonIndex + 1;
        end
    end
    
    for i = (numActiveQuests + numAvailableQuests + 1), MAX_NUM_QUESTS, 1 do
        getglobal("DQuestTitleButton" .. i):Hide();
    end
    
    -- Enable keyboard capture for this frame
    DQuestFrame:EnableKeyboard(true);
    DQuestFrame:SetScript("OnKeyDown", DQuestFrame_OnKeyDown);
end

function DQuestFrame_OnKeyDown()
    local key = arg1;
    
    -- Handle ESC key to close
    if key == "ESCAPE" then
        HideUIPanel(DQuestFrame);
        return
    end

    -- Handle spacebar press to select first option
 -- Handle spacebar press
 if (key == "SPACE") then
    -- Check which panel is currently visible and trigger appropriate action
    if (DQuestFrameDetailPanel:IsVisible()) then
        -- Quest Detail panel - Accept quest
        DQuestDetailAcceptButton_OnClick();
        return;
    elseif (DQuestFrameRewardPanel:IsVisible()) then
        -- Quest Reward panel - Complete quest
        DQuestRewardCompleteButton_OnClick();
        return;
    elseif (DQuestFrameProgressPanel:IsVisible()) then
        -- Quest Progress panel - Complete quest
        DQuestProgressCompleteButton_OnClick();
        return;
    else
        -- Greeting panel - Select first quest
        local numActiveQuests = GetNumActiveQuests();
        local numAvailableQuests = GetNumAvailableQuests();
        
        -- Check if there are any quests available
        if (numActiveQuests > 0 or numAvailableQuests > 0) then
            -- Click the first quest button
            local firstButton = getglobal("DQuestTitleButton1");
            if (firstButton and firstButton:IsVisible()) then
                firstButton:Click();
            end
        end
    end
end
    
    -- Handle number keys 1-9 for direct quest selection
    if (key >= "1" and key <= "9") then
        local buttonNum = tonumber(key);
        local numActiveQuests = GetNumActiveQuests();
        local numAvailableQuests = GetNumAvailableQuests();
        local totalQuests = numActiveQuests + numAvailableQuests;
        
        if (buttonNum <= totalQuests) then
            local questButton = getglobal("DQuestTitleButton" .. buttonNum);
            if (questButton and questButton:IsVisible()) then
                questButton:Click();
            end
        end
    end
end


function DQuestFrame_OnShow()
    PlaySound("igQuestListOpen");
    -- Ensure the frame can receive keyboard input
    DQuestFrame:EnableKeyboard(true);
    -- Set focus to the frame so it receives ESC key events
    DQuestFrame:SetFocus();
    -- Apply current transparency settings
    if DialogUI_ApplyAlpha then
        DialogUI_ApplyAlpha();
    end
    
    -- Aggressively hide original frames when our frame shows
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden();
    
    -- Set up an OnUpdate handler to continuously hide original frames while visible
    DQuestFrame:SetScript("OnUpdate", function()
        -- Only run the check every few frames to avoid performance issues
        if not this.hideCheckCounter then
            this.hideCheckCounter = 0;
        end
        this.hideCheckCounter = this.hideCheckCounter + 1;
        
        if this.hideCheckCounter >= 10 then -- Check every 10 frames
            this.hideCheckCounter = 0;
            
            -- Continuously ensure original frames stay invisible but functional
            if QuestFrame then
                QuestFrame:SetAlpha(0);
                QuestFrame:ClearAllPoints();
                QuestFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000);
            end
            if QuestFrameGreetingPanel then
                QuestFrameGreetingPanel:SetAlpha(0);
            end
            if QuestFrameDetailPanel then
                QuestFrameDetailPanel:SetAlpha(0);
            end
            if QuestFrameProgressPanel then
                QuestFrameProgressPanel:SetAlpha(0);
            end
            if QuestFrameRewardPanel then
                QuestFrameRewardPanel:SetAlpha(0);
            end
        end
    end);
end

function DQuestFrame_OnHide()
    -- Clear the OnUpdate handler when frame is hidden
    DQuestFrame:SetScript("OnUpdate", nil);
    
    DQuestFrameGreetingPanel:Hide();
    DQuestFrameDetailPanel:Hide();
    DQuestFrameRewardPanel:Hide();
    DQuestFrameProgressPanel:Hide();
    
    -- Notify Dynamic Camera module that quest interaction ended
    if DynamicCamera and DynamicCamera.OnQuestFinished then
        DynamicCamera:OnQuestFinished();
    end
    
    CloseQuest();
    PlaySound("igQuestListClose");
    
    -- Save position when the frame closes
    DialogUI_SavePosition();
end

function DQuestTitleButton_OnClick()
    if (this.isActive == 1) then
        SelectActiveQuest(this:GetID());
    else
        SelectAvailableQuest(this:GetID());
    end
    PlaySound("igQuestListSelect");
end

function DQuestMoneyFrame_OnLoad()
    MoneyFrame_OnLoad();
    MoneyFrame_SetType("STATIC");
end

function DQuestFrameItems_Update(questState)


    if (DQuestFrameRewardPanel) then
        DQuestFrameRewardPanel.itemChoice = 0;
    end
    if (DQuestRewardItemHighlight) then
        DQuestRewardItemHighlight:Hide();
    end

    local isQuestLog = 0;
    local numQuestRewards;
    local numQuestChoices;
    local numQuestSpellRewards = 0;
    local money;
    local spacerFrame;
    if (isQuestLog == 0) then
        numQuestRewards = GetNumQuestRewards();
        numQuestChoices = GetNumQuestChoices();
        if (GetRewardSpell()) then
            numQuestSpellRewards = 1;
        end
        money = GetRewardMoney();
        spacerFrame = DQuestSpacerFrame;
    end

    local totalRewards = numQuestRewards + numQuestChoices + numQuestSpellRewards;
    local questItemName = questState .. "Item";
    local questItemReceiveText = getglobal(questState .. "ItemReceiveText");
    if (totalRewards == 0 and money == 0) then
        getglobal(questState .. "RewardTitleText"):Hide();
    else
        getglobal(questState .. "RewardTitleText"):Show();
        SetFontColor(getglobal(questState .. "RewardTitleText"), "DarkBrown");
        QuestFrame_SetAsLastShown(getglobal(questState .. "RewardTitleText"), spacerFrame);
    end
    if (money == 0) then
        getglobal(questState .. "MoneyFrame"):Hide();
    else
        getglobal(questState .. "MoneyFrame"):Show();
        QuestFrame_SetAsLastShown(getglobal(questState .. "MoneyFrame"), spacerFrame);
        MoneyFrame_Update(questState .. "MoneyFrame", money);
    end

    -- Hide unused rewards
    for i = totalRewards + 1, MAX_NUM_ITEMS, 1 do
        getglobal(questItemName .. i):Hide();
    end

    local questItem, name, texture, isTradeskillSpell, quality, isUsable, numItems = 1;
    local rewardsCount = 0;

    -- Setup choosable rewards
    if (numQuestChoices > 0) then
        local itemChooseText = getglobal(questState .. "ItemChooseText");
        itemChooseText:Show();
        SetFontColor(itemChooseText, "DarkBrown");
        QuestFrame_SetAsLastShown(itemChooseText, spacerFrame);

        local index;
        local baseIndex = rewardsCount;
        for i = 1, numQuestChoices, 1 do
            index = i + baseIndex;
            questItem = getglobal(questItemName .. index);
            questItem.type = "choice";
            numItems = 1;
            if (isQuestLog == 0) then
                name, texture, numItems, quality, isUsable = GetQuestItemInfo(questItem.type, i);
            end
            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.rewardType = "item"
            QuestFrame_SetAsLastShown(questItem, spacerFrame);
            getglobal(questItemName .. index .. "Name"):SetText(name);
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            if (isUsable) then
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
                SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
            end
            -- Changes how the reward columns are positioned
            if (i > 1) then
                if (mod(i, 2) == 1) then
                    questItem:SetPoint("TOPLEFT", questItemName .. (index - 2), "BOTTOMLEFT", 0,-20);
                else
                    questItem:SetPoint("TOPLEFT", questItemName .. (index - 1), "TOPRIGHT", 50, 0);
                end
            else
                questItem:SetPoint("TOPLEFT", itemChooseText, "BOTTOMLEFT", -3, -5);
            end
            rewardsCount = rewardsCount + 1;
        end
    else
        getglobal(questState .. "ItemChooseText"):Hide();
    end

    -- Setup spell rewards
    if (numQuestSpellRewards > 0) then
        local learnSpellText = getglobal(questState .. "SpellLearnText");
        learnSpellText:Show();
        SetFontColor(learnSpellText, "DarkBrown");
        QuestFrame_SetAsLastShown(learnSpellText, spacerFrame);

        -- Anchor learnSpellText if there were choosable rewards
        if (rewardsCount > 0) then
            learnSpellText:SetPoint("TOPLEFT", questItemName .. rewardsCount, "BOTTOMLEFT", 3, -5);
        else
            learnSpellText:SetPoint("TOPLEFT", questState .. "RewardTitleText", "BOTTOMLEFT", 0, -5);
        end

        if (isQuestLog == 1) then
            texture, name, isTradeskillSpell = GetQuestLogRewardSpell();
        else
            texture, name, isTradeskillSpell = GetRewardSpell();
        end

        if (isTradeskillSpell) then
            learnSpellText:SetText(REWARD_TRADESKILL_SPELL);
        else
            learnSpellText:SetText(REWARD_SPELL);
        end

        rewardsCount = rewardsCount + 1;
        questItem = getglobal(questItemName .. rewardsCount);
        questItem:Show();
        -- For the tooltip
        questItem.rewardType = "spell";
        SetItemButtonCount(questItem, 0);
        SetItemButtonTexture(questItem, texture);
        getglobal(questItemName .. rewardsCount .. "Name"):SetText(name);
        questItem:SetPoint("TOPLEFT", learnSpellText, "BOTTOMLEFT", -3, -5);
    else
        getglobal(questState .. "SpellLearnText"):Hide();
    end

    -- Setup mandatory rewards
    if (numQuestRewards > 0 or money > 0) then
            SetFontColor(questItemReceiveText, "DarkBrown");
        -- Anchor the reward text differently if there are choosable rewards
        if (numQuestSpellRewards > 0) then
            questItemReceiveText:SetText(TEXT(REWARD_ITEMS));
            questItemReceiveText:SetPoint("TOPLEFT", questItemName .. rewardsCount, "BOTTOMLEFT", 3, -5);
        elseif (numQuestChoices > 0) then
            questItemReceiveText:SetText(TEXT(REWARD_ITEMS));
            local index = numQuestChoices;
            if (mod(index, 2) == 0) then
                index = index - 1;
            end
            questItemReceiveText:SetPoint("TOPLEFT", questItemName .. index, "BOTTOMLEFT", 3, -5);
        else
            questItemReceiveText:SetText(TEXT(REWARD_ITEMS_ONLY));
            questItemReceiveText:SetPoint("TOPLEFT", questState .. "RewardTitleText", "BOTTOMLEFT", 3, -5);
        end
        questItemReceiveText:Show();
        QuestFrame_SetAsLastShown(questItemReceiveText, spacerFrame);
        -- Setup mandatory rewards
        local index;
        local baseIndex = rewardsCount;
        for i = 1, numQuestRewards, 1 do
            index = i + baseIndex;
            questItem = getglobal(questItemName .. index);
            questItem.type = "reward";
            numItems = 1;
            if (isQuestLog == 1) then
                name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i);
            else
                name, texture, numItems, quality, isUsable = GetQuestItemInfo(questItem.type, i);
            end
            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.rewardType = "item";
            QuestFrame_SetAsLastShown(questItem, spacerFrame);
            getglobal(questItemName .. index .. "Name"):SetText(name);
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            if (isUsable) then
                -- SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                -- SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                -- SetItemButtonTextureVertexColor(questItem, 0.5, 0, 0);
                -- SetItemButtonNameFrameVertexColor(questItem, 1.0, 0, 0);
            end

            if (i > 1) then
                if (mod(i, 2) == 1) then
                    questItem:SetPoint("TOPLEFT", questItemName .. (index - 2), "BOTTOMLEFT", 0, -02);
                else
                    questItem:SetPoint("TOPLEFT", questItemName .. (index - 1), "TOPRIGHT", 50, 0);
                end
            else
                questItem:SetPoint("TOPLEFT", questState .. "ItemReceiveText", "BOTTOMLEFT", -3, -5);
            end
            rewardsCount = rewardsCount + 1;
        end
    else
        questItemReceiveText:Hide();
    end
    if (questState == "QuestReward") then
        DQuestFrameCompleteQuestButton:Enable();
        DQuestFrameRewardPanel.itemChoice = 0;
        DQuestRewardItemHighlight:Hide();
    end
end

function DQuestFrameDetailPanel_OnShow()
    DQuestFrameRewardPanel:Hide();
    DQuestFrameProgressPanel:Hide();
    DQuestFrameGreetingPanel:Hide();
    HideDefaultFrames();
    DialogUI_EnsureOriginalQuestHidden(); -- Extra call to ensure original stays hidden
    DQuestFrameNpcNameText:SetText(GetTitleText());
    DQuestDescription:SetText(GetQuestText());
    DQuestObjectiveText:SetText(GetObjectiveText());
    SetFontColor(DQuestFrameNpcNameText, "DarkBrown");
    SetFontColor(DQuestDescription, "DarkBrown");
    SetFontColor(DQuestObjectiveText, "DarkBrown");
    QuestFrame_SetAsLastShown(DQuestObjectiveText, DQuestSpacerFrame);
    DQuestFrameItems_Update("DQuestDetail");
    DQuestDetailScrollFrame:UpdateScrollChildRect();
    DQuestDetailScrollFrameScrollBar:SetValue(0);

    -- Hide Objectives and rewards until the text is completely displayed
    DTextAlphaDependentFrame:SetAlpha(0);
    DQuestFrameAcceptButton:Disable();

    DQuestFrameDetailPanel.fading = 1;
    DQuestFrameDetailPanel.fadingProgress = 0;
    DQuestDescription:SetAlphaGradient(0, QUEST_DESCRIPTION_GRADIENT_LENGTH);
    if (QUEST_FADING_DISABLE == "1") then
        DQuestFrameDetailPanel.fadingProgress = 1024;
    end
    
    -- Ensure original quest frame stays hidden during animation
    DialogUI_EnsureOriginalQuestHidden();
end

function DQuestFrameDetailPanel_OnUpdate(elapsed)
    if (this.fading) then
        -- Ensure original quest frame stays hidden during text animation
        DialogUI_EnsureOriginalQuestHidden();
        
        this.fadingProgress = this.fadingProgress + (elapsed * QUEST_DESCRIPTION_GRADIENT_CPS);
        PlaySound("WriteQuest");
        if (not DQuestDescription:SetAlphaGradient(this.fadingProgress, QUEST_DESCRIPTION_GRADIENT_LENGTH)) then
            this.fading = nil;
            -- Show Quest Objectives and Rewards
            if (QUEST_FADING_DISABLE == "0") then
                UIFrameFadeIn(DTextAlphaDependentFrame, QUESTINFO_FADE_IN);
            else
                DTextAlphaDependentFrame:SetAlpha(1);
            end
            DQuestFrameAcceptButton:Enable();
        end
    end
end

function DQuestDetailAcceptButton_OnClick()
    AcceptQuest();
end

function DQuestDetailDeclineButton_OnClick()
    DeclineQuest();
    PlaySound("igQuestCancel");
end

-- Function that gets called when ESC is pressed
function DQuestFrame_OnCancel()
    -- This gets called when ESC is pressed on the frame
    HideUIPanel(DQuestFrame);
end

-- Function to handle key presses
function DQuestFrame_OnKeyDown()
    if arg1 == "ESCAPE" then
        HideUIPanel(DQuestFrame);
    end
end


local function UpdateQuestIcons()
    local numActiveQuests = GetNumActiveQuests();
    local numAvailableQuests = GetNumAvailableQuests();
    
    -- Update active quest icons
    for i = 1, numActiveQuests do
        local button = getglobal("DQuestTitleButton" .. i);
        if button and button:IsVisible() then
            local iconTexture = button:GetRegions(); -- Gets the first region (your texture)
            if iconTexture and iconTexture.SetTexture then
                iconTexture:SetTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\activeQuestIcon");
            end
        end
    end
    
    -- Update available quest icons
    for i = (numActiveQuests + 1), (numActiveQuests + numAvailableQuests) do
        local button = getglobal("DQuestTitleButton" .. i);
        if button and button:IsVisible() then
            local iconTexture = button:GetRegions(); -- Gets the first region (your texture)
            if iconTexture and iconTexture.SetTexture then
                iconTexture:SetTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\availableQuestIcon");
            end
        end
    end
end

local originalOnShow = DQuestFrameGreetingPanel_OnShow;
DQuestFrameGreetingPanel_OnShow = function()
    originalOnShow();
    UpdateQuestIcons();
end

-- Function to reset frame position to default (unified)
function DialogUI_ResetPosition()
    DialogUIFramePosition = nil;
    DQuestFramePosition = nil; -- Also clear old variable
    
    -- Reset all frames to default position
    if DQuestFrame then
        DQuestFrame:ClearAllPoints();
        DQuestFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104);
    end
    if DGossipFrame then
        DGossipFrame:ClearAllPoints();
        DGossipFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104);
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: All frame positions reset to default.");
end

-- Legacy function for backward compatibility
function DQuestFrame_ResetPosition()
    DialogUI_ResetPosition();
end

-- Function to debug frame state (unified for all DialogUI frames)
function DialogUI_DebugState()
    -- Show saved position
    local position = DialogUIFramePosition or DQuestFramePosition;
    if position then
        DEFAULT_CHAT_FRAME:AddMessage("Saved Position: (" .. (position.xOfs or 0) .. ", " .. (position.yOfs or 0) .. ")");
    else
        DEFAULT_CHAT_FRAME:AddMessage("No saved position found");
    end
    
    -- Quest Frame
    if DQuestFrame then
        local movable = DQuestFrame:IsMovable() and "YES" or "NO";
        local mouseEnabled = DQuestFrame:IsMouseEnabled() and "YES" or "NO";
        local visible = DQuestFrame:IsVisible() and "YES" or "NO";
        
        DEFAULT_CHAT_FRAME:AddMessage("Quest Frame: Movable=" .. movable .. ", Mouse=" .. mouseEnabled .. ", Visible=" .. visible);
    end
    
    -- Gossip Frame
    if DGossipFrame then
        local movable = DGossipFrame:IsMovable() and "YES" or "NO";
        local mouseEnabled = DGossipFrame:IsMouseEnabled() and "YES" or "NO";
        local visible = DGossipFrame:IsVisible() and "YES" or "NO";
        
        DEFAULT_CHAT_FRAME:AddMessage("Gossip Frame: Movable=" .. movable .. ", Mouse=" .. mouseEnabled .. ", Visible=" .. visible);
    end
end

-- Legacy function for backward compatibility
function DQuestFrame_DebugState()
    DialogUI_DebugState();
end

-- Commands to reset position and debug (can be used in chat)
SlashCmdList["DIALOGUI_RESET"] = DialogUI_ResetPosition;
SLASH_DIALOGUI_RESET1 = "/resetdialogs";
SLASH_DIALOGUI_RESET2 = "/resetquest";
SLASH_DIALOGUI_RESET3 = "/questframereset";

SlashCmdList["DIALOGUI_DEBUG"] = DialogUI_DebugState;
SLASH_DIALOGUI_DEBUG1 = "/debugquest";
SLASH_DIALOGUI_DEBUG2 = "/debugdialogs";

-- Configuration functions and commands (moved here to ensure they're available)
function DialogUI_ShowConfig()
    if DConfigFrame then
        ShowUIPanel(DConfigFrame);
    else
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Configuration window not available yet. Try /reload.");
    end
end

function DialogUI_HideConfig()
    if DConfigFrame then
        HideUIPanel(DConfigFrame);
    end
end

function DialogUI_ToggleConfig()
    if DConfigFrame then
        if DConfigFrame:IsVisible() then
            DialogUI_HideConfig();
        else
            DialogUI_ShowConfig();
        end
    else
        DialogUI_ShowConfig(); -- This will show the error message
    end
end

-- Configuration commands
SlashCmdList["DIALOGUI_CONFIG"] = DialogUI_ToggleConfig;
SLASH_DIALOGUI_CONFIG1 = "/dialogui";
SLASH_DIALOGUI_CONFIG2 = "/dialogconfig";
SLASH_DIALOGUI_CONFIG3 = "/dconfig";

-- Add command for opening configuration (additional alias)
SlashCmdList["DIALOGUI_SETTINGS"] = DialogUI_ToggleConfig;
SLASH_DIALOGUI_SETTINGS1 = "/dialogsettings";

-- Debug command to test quest frame visibility
function DialogUI_TestQuestFrame()
    if DQuestFrame then
        DQuestFrame:Show();
        HideDefaultFrames();
        
        -- Try to show a simple panel
        if DQuestFrameGreetingPanel then
            DQuestFrameGreetingPanel:Show();
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: ERROR - DQuestFrame does not exist!");
    end
end

SlashCmdList["DIALOGUI_TEST"] = DialogUI_TestQuestFrame;
SLASH_DIALOGUI_TEST1 = "/dtest";

-- Basic configuration functions (fallback implementations)
function DialogUI_LoadConfig()
    if DialogUI_SavedConfig then
        DialogUI_Config.scale = DialogUI_SavedConfig.scale or 1.0;
        DialogUI_Config.alpha = DialogUI_SavedConfig.alpha or 1.0;
        DialogUI_Config.fontSize = DialogUI_SavedConfig.fontSize or 1.0;
    end
end

function DialogUI_SaveConfig()
    if not DialogUI_SavedConfig then
        DialogUI_SavedConfig = {};
    end
    
    DialogUI_SavedConfig.scale = DialogUI_Config.scale;
    DialogUI_SavedConfig.alpha = DialogUI_Config.alpha;
    DialogUI_SavedConfig.fontSize = DialogUI_Config.fontSize;
end

-- Transparency functions (moved here to be available early in load order)
function DialogUI_ApplyAlpha()
    local alpha = DialogUI_Config.alpha;
    
    -- Apply transparency to quest frame and its panels
    if DQuestFrame then
        -- Apply to main quest frame background
        DialogUI_ApplyAlphaToPanel(DQuestFrame, alpha);
        
        -- Apply to reward panel background
        local rewardPanel = getglobal("DQuestFrameRewardPanel");
        if rewardPanel then
            DialogUI_ApplyAlphaToPanel(rewardPanel, alpha);
        end
        
        -- Apply to progress panel background
        local progressPanel = getglobal("DQuestFrameProgressPanel");
        if progressPanel then
            DialogUI_ApplyAlphaToPanel(progressPanel, alpha);
        end
        
        -- Apply to greeting panel background
        local greetingPanel = getglobal("DQuestFrameGreetingPanel");
        if greetingPanel then
            DialogUI_ApplyAlphaToPanel(greetingPanel, alpha);
        end
        
        -- Apply to detail panel background
        local detailPanel = getglobal("DQuestFrameDetailPanel");
        if detailPanel then
            DialogUI_ApplyAlphaToPanel(detailPanel, alpha);
        end
    end
    
    -- Apply transparency to gossip frame
    if DGossipFrame then
        DialogUI_ApplyAlphaToPanel(DGossipFrame, alpha);
        
        -- Apply to gossip greeting panel
        local gossipGreetingPanel = getglobal("DGossipFrameGreetingPanel");
        if gossipGreetingPanel then
            DialogUI_ApplyAlphaToPanel(gossipGreetingPanel, alpha);
        end
    end
    
    -- Apply transparency to any money frames that might exist
    local moneyFrame = getglobal("DQuestProgressRequiredMoneyFrame");
    if moneyFrame then
        DialogUI_ApplyAlphaToPanel(moneyFrame, alpha);
    end
end

-- Helper function to apply alpha to a panel's background texture
function DialogUI_ApplyAlphaToPanel(panel, alpha)
    if not panel then return; end
    
    local regions = {panel:GetRegions()};
    for i = 1, table.getn(regions) do
        local region = regions[i];
        if region and region:GetObjectType() == "Texture" then
            -- Apply alpha only to background textures (usually the first ones)
            local texture = region:GetTexture();
            if texture and (string.find(texture, "Parchment") or i == 1) then
                region:SetAlpha(alpha);
                -- Only apply to the first parchment texture found
                break;
            end
        end
    end
end