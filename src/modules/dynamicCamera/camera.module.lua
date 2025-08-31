-- Dynamic Camera Module for DialogUI
-- Handles smooth camera transitions during NPC interactions

-- Initialize the camera module
DynamicCamera = {};
DynamicCamera.isActive = false;
DynamicCamera.originalDistance = nil;
DynamicCamera.originalPitch = nil;
DynamicCamera.originalYaw = nil;
DynamicCamera.transitionActive = false;

-- Default camera settings
DynamicCamera.config = {
    enabled = true,
    interactionDistance = 8,      -- Camera distance when talking to NPC
    interactionPitch = -0.3,      -- Camera pitch (up/down angle)
    transitionSpeed = 2.0,        -- Speed of camera transitions (higher = faster)
    enableForGossip = true,       -- Enable for gossip dialogs
    enableForVendors = true,      -- Enable for vendor interactions
    enableForTrainers = true,     -- Enable for trainer interactions
    enableForQuests = true,       -- Enable for quest dialogs (now ON by default)
    -- Preset system for vanilla WoW
    usePresetRestore = false,     -- Use custom preset instead of trying to restore original
    presetView = 2,              -- Saved camera view (1=first person, 2=third person, etc.)
    savedCameraYaw = nil,        -- Custom saved camera yaw
    savedCameraPitch = nil,      -- Custom saved camera pitch  
    savedCameraDistance = nil,   -- Custom saved camera distance
};

-- Save original camera position
function DynamicCamera:SaveOriginalPosition()
    if not self.isActive then
        -- Try to get camera values, with fallback defaults
        local distance = 15; -- Default fallback
        local pitch = 0; -- Default fallback
        local yaw = 0; -- Default fallback
        
        -- Try to get actual values if functions are available
        if GetCameraDistance then
            distance = GetCameraDistance() or 15;
        else
        end
        
        if GetCameraPitch then
            pitch = GetCameraPitch() or 0;
        else
        end
        
        if GetCameraYaw then
            yaw = GetCameraYaw() or 0;
        else
        end
        
        self.originalDistance = distance;
        self.originalPitch = pitch;
        self.originalYaw = yaw;
        
        
        -- Store in saved variables for persistence
        if not DialogUI_SavedConfig then
            DialogUI_SavedConfig = {};
        end
        DialogUI_SavedConfig.originalCameraDistance = self.originalDistance;
        DialogUI_SavedConfig.originalCameraPitch = self.originalPitch;
        DialogUI_SavedConfig.originalCameraYaw = self.originalYaw;
        
    end
end

-- Save current camera position as preset for restoration
function DynamicCamera:SaveCameraPreset()
    
    -- Try to capture current camera state using WoW Vanilla functions
    local currentDistance = 15; -- Default fallback
    local currentPitch = 0;
    local currentYaw = 0;
    
    -- Try to get current camera distance using CVars (most reliable in Vanilla)
    if GetCVar then
        local maxDist = GetCVar("cameraDistanceMax");
        if maxDist then
            currentDistance = tonumber(maxDist) or 15;
        end
        
        -- Try to get camera angle info if available
        local cameraPitch = GetCVar("cameraPitchMoveSpeed");
        if cameraPitch then
        end
    end
    
    -- Save as restoration preset
    self.config.usePresetRestore = true;
    self.config.savedCameraDistance = currentDistance;
    self.config.savedCameraPitch = currentPitch;
    self.config.savedCameraYaw = currentYaw;
    self.config.presetView = GetCVar and GetCVar("cameraView") or 2; -- Save current view mode
    
    -- Save configuration
    self:SaveConfig();
    
end

-- Restore original camera position
function DynamicCamera:RestoreOriginalPosition()
    
    if self.originalDistance then
        -- Use saved preset if available
        if self.config.usePresetRestore and self.config.savedCameraDistance then
            
            -- Restore to saved preset position
            if SetCVar and self.config.savedCameraDistance then
                SetCVar("cameraDistanceMax", tostring(self.config.savedCameraDistance));
            end
            
            -- Restore view mode if available
            if SetView and self.config.presetView then
                SetView(self.config.presetView);
            end
            
            -- Try to restore camera distance using zoom functions as backup
            if CameraZoomOut and self.config.savedCameraDistance then
                local targetDistance = self.config.savedCameraDistance;
                if targetDistance > 10 then
                    -- Zoom out for wider views
                    for i = 1, 3 do
                        CameraZoomOut(2.0);
                    end
                end
            end
            
        else
            -- Default restore to third-person
            if SetView then
                SetView(2); -- Third person view
            end
            
            -- Reset camera distance to reasonable default
            if SetCVar then
                SetCVar("cameraDistanceMax", "15");
            end
        end
        
        -- Clean up
        self.isActive = false;
        self.originalDistance = nil;
        self.originalPitch = nil;
        self.originalYaw = nil;
        
    else
    end
end

-- Apply interaction camera position
function DynamicCamera:ApplyInteractionPosition()
    if not self.config.enabled then
        return;
    end
    
    -- Only apply if not already active to avoid interference
    if self.isActive then
        return;
    end
    
    -- Don't interfere if quest frames are in transition or loading
    if DQuestFrame and DQuestFrame:IsVisible() then
        local alpha = DQuestFrame:GetAlpha();
        if alpha < 1.0 then
            -- Frame is still transitioning, wait a bit more
            return;
        end
    end
    
    self:SaveOriginalPosition();
    
    -- Calculate target camera position
    local targetDistance = self.config.interactionDistance;
    local targetPitch = self.config.interactionPitch;
    local currentYaw = self.originalYaw;
    
    -- Apply camera immediately without transition
    self:ApplyImmediateCamera(targetDistance, targetPitch, currentYaw);
    self.isActive = true;
end

-- Apply camera settings immediately without transitions
function DynamicCamera:ApplyImmediateCamera(distance, pitch, yaw)
    -- Apply camera settings immediately for better performance
    if CameraZoomIn and CameraZoomOut then
        -- Zoom to the target distance immediately
        local currentDist = GetCameraDistance and GetCameraDistance() or 15;
        local targetDist = distance or 8;
        
        if currentDist > targetDist then
            -- Need to zoom in
            for i = 1, math.ceil(currentDist - targetDist) do
                CameraZoomIn(1);
            end
        elseif currentDist < targetDist then
            -- Need to zoom out
            for i = 1, math.ceil(targetDist - currentDist) do
                CameraZoomOut(1);
            end
        end
    elseif SetCVar then
        -- Use CVars for immediate camera control
        if distance then
            SetCVar("cameraDistanceMax", distance);
            SetCVar("cameraDistanceMaxFactor", 1.0);
        end
    end
end

-- Smooth camera transition
function DynamicCamera:SmoothTransition(targetDistance, targetPitch, targetYaw, onComplete)
    
    if self.transitionActive then
        return; -- Avoid multiple transitions
    end
    
    self.transitionActive = true;
    
    -- Use saved values instead of getting current values
    local startDistance = self.originalDistance or 15;
    local startPitch = self.originalPitch or 0;
    local startYaw = self.originalYaw or 0;
    
    
    -- Check what camera functions are available in this WoW version
    
    -- Try using camera functions that are available in vanilla
    if CameraZoomIn and targetDistance < 10 then
        -- Use zoom for closer view
        for i = 1, 5 do
            CameraZoomIn(1.0); -- Zoom in step by step
        end
    elseif SetCVar then
        -- Try using CVars for camera control
        SetCVar("cameraDistanceMax", tostring(targetDistance));
        SetCVar("cameraDistanceMaxFactor", "1.0");
    else
    end
    
    self.transitionActive = false;
    if onComplete then
        onComplete();
    end
    
    local steps = 30; -- Number of transition steps
    local stepDuration = 0.05; -- Duration of each step in seconds
    local currentStep = 0;
    
    -- Create transition frame
    local transitionFrame = CreateFrame("Frame");
    local elapsedTime = 0;
    
    
    transitionFrame:SetScript("OnUpdate", function()
        elapsedTime = elapsedTime + arg1; -- arg1 is the time elapsed since last frame
        
        if elapsedTime >= stepDuration then
            currentStep = currentStep + 1;
            elapsedTime = 0;
            
            local progress = currentStep / steps;
            
            -- Ease-in-out interpolation for smooth transitions
            local easedProgress = progress * progress * (3 - 2 * progress);
            
            -- Calculate current position
            local currentDistance = startDistance + (targetDistance - startDistance) * easedProgress;
            local currentPitch = startPitch + (targetPitch - startPitch) * easedProgress;
            local currentYaw = startYaw + (targetYaw - startYaw) * easedProgress;
            
            -- Apply camera position
            SetCameraDistance(currentDistance);
            SetCameraPitch(currentPitch);
            SetCameraYaw(currentYaw);
            
            if currentStep >= steps then
                -- Transition complete
                transitionFrame:SetScript("OnUpdate", nil);
                transitionFrame = nil;
                self.transitionActive = false;
                
                if onComplete then
                    onComplete();
                end
            end
        end
    end);
end

-- Event handlers
function DynamicCamera:OnGossipShow()
    if self.config.enableForGossip then
        -- Apply camera immediately without delay
        self:ApplyInteractionPosition();
    end
end

function DynamicCamera:OnGossipClosed()
    if self.config.enableForGossip and self.isActive then
        self:RestoreOriginalPosition();
    end
end

function DynamicCamera:OnMerchantShow()
    if self.config.enableForVendors then
        self:ApplyInteractionPosition();
    end
end

function DynamicCamera:OnMerchantClosed()
    if self.config.enableForVendors and self.isActive then
        self:RestoreOriginalPosition();
    end
end

function DynamicCamera:OnTrainerShow()
    if self.config.enableForTrainers then
        self:ApplyInteractionPosition();
    end
end

function DynamicCamera:OnTrainerClosed()
    if self.config.enableForTrainers and self.isActive then
        self:RestoreOriginalPosition();
    end
end

function DynamicCamera:OnQuestDetail()
    -- For quest frames, be very conservative to avoid interference
    if self.config.enableForQuests then
        -- Don't activate camera if already active
        if self.isActive then
            return;
        end
        self:ApplyInteractionPosition();
    end
end

function DynamicCamera:OnQuestFinished()
    if self.config.enableForQuests and self.isActive then
        self:RestoreOriginalPosition();
    end
end

-- Load saved camera configuration
function DynamicCamera:LoadConfig()
    if DialogUI_SavedConfig and DialogUI_SavedConfig.camera then
        local saved = DialogUI_SavedConfig.camera;
        self.config.enabled = saved.enabled or true;
        self.config.interactionDistance = saved.interactionDistance or 8;
        self.config.interactionPitch = saved.interactionPitch or -0.3;
        self.config.transitionSpeed = saved.transitionSpeed or 2.0;
        self.config.enableForGossip = saved.enableForGossip or true;
        self.config.enableForVendors = saved.enableForVendors or true;
        self.config.enableForTrainers = saved.enableForTrainers or true;
        self.config.enableForQuests = saved.enableForQuests or true;
        -- Load preset settings
        self.config.usePresetRestore = saved.usePresetRestore or false;
        self.config.presetView = saved.presetView or 2;
        self.config.savedCameraYaw = saved.savedCameraYaw;
        self.config.savedCameraPitch = saved.savedCameraPitch;
        self.config.savedCameraDistance = saved.savedCameraDistance;
    end
end

-- Save camera configuration
function DynamicCamera:SaveConfig()
    if not DialogUI_SavedConfig then
        DialogUI_SavedConfig = {};
    end
    DialogUI_SavedConfig.camera = {
        enabled = self.config.enabled,
        interactionDistance = self.config.interactionDistance,
        interactionPitch = self.config.interactionPitch,
        transitionSpeed = self.config.transitionSpeed,
        enableForGossip = self.config.enableForGossip,
        enableForVendors = self.config.enableForVendors,
        enableForTrainers = self.config.enableForTrainers,
        enableForQuests = self.config.enableForQuests,
        -- Save preset settings
        usePresetRestore = self.config.usePresetRestore,
        presetView = self.config.presetView,
        savedCameraYaw = self.config.savedCameraYaw,
        savedCameraPitch = self.config.savedCameraPitch,
        savedCameraDistance = self.config.savedCameraDistance,
    };
end

-- Initialize camera module
function DynamicCamera:Initialize()
    
    -- Load configuration
    self:LoadConfig();
    

    -- Create event frame
    local eventFrame = CreateFrame("Frame", "DynamicCameraEventFrame");
    eventFrame:RegisterEvent("GOSSIP_SHOW");
    eventFrame:RegisterEvent("GOSSIP_CLOSED");
    eventFrame:RegisterEvent("MERCHANT_SHOW");
    eventFrame:RegisterEvent("MERCHANT_CLOSED");
    eventFrame:RegisterEvent("TRAINER_SHOW");
    eventFrame:RegisterEvent("TRAINER_CLOSED");
    eventFrame:RegisterEvent("QUEST_DETAIL");
    eventFrame:RegisterEvent("QUEST_FINISHED");
    eventFrame:RegisterEvent("QUEST_COMPLETE");


    eventFrame:SetScript("OnEvent", function()
        local event = event; -- Local reference to event

        if event == "GOSSIP_SHOW" then
            DynamicCamera:OnGossipShow();
        elseif event == "GOSSIP_CLOSED" then
            DynamicCamera:OnGossipClosed();
        elseif event == "MERCHANT_SHOW" then
            DynamicCamera:OnMerchantShow();
        elseif event == "MERCHANT_CLOSED" then
            DynamicCamera:OnMerchantClosed();
        elseif event == "TRAINER_SHOW" then
            DynamicCamera:OnTrainerShow();
        elseif event == "TRAINER_CLOSED" then
            DynamicCamera:OnTrainerClosed();
        elseif event == "QUEST_DETAIL" then
            DynamicCamera:OnQuestDetail();
        elseif event == "QUEST_FINISHED" or event == "QUEST_COMPLETE" then
            DynamicCamera:OnQuestFinished();
        end
    end);
    
end

-- Slash commands for camera module
SlashCmdList["DYNAMICCAMERA_TOGGLE"] = function()
    DynamicCamera.config.enabled = not DynamicCamera.config.enabled;
    DynamicCamera:SaveConfig();
    
    local status = DynamicCamera.config.enabled and "enabled" or "disabled";
end;
SLASH_DYNAMICCAMERA_TOGGLE1 = "/togglecamera";
SLASH_DYNAMICCAMERA_TOGGLE2 = "/dcamera";

-- Test command for camera positioning
SlashCmdList["DYNAMICCAMERA_TEST"] = function()
    if DynamicCamera.isActive then
        DynamicCamera:RestoreOriginalPosition();
    else
        DynamicCamera:ApplyInteractionPosition();
    end
end;
SLASH_DYNAMICCAMERA_TEST1 = "/testcamera";

-- Additional debug command for quest frame compatibility
SlashCmdList["DYNAMICCAMERA_QUESTDEBUG"] = function()
    local questVisible = DQuestFrame and DQuestFrame:IsVisible() and "YES" or "NO";
    local questAlpha = DQuestFrame and DQuestFrame:GetAlpha() or "N/A";
    local cameraActive = DynamicCamera.isActive and "YES" or "NO";
    
end;
SLASH_DYNAMICCAMERA_QUESTDEBUG1 = "/cameradebug";

-- Command to save current camera position as preset
SlashCmdList["DYNAMICCAMERA_SAVEPRESET"] = function()
    DynamicCamera:SaveCameraPreset();
end;
SLASH_DYNAMICCAMERA_SAVEPRESET1 = "/savecamerapreset";
SLASH_DYNAMICCAMERA_SAVEPRESET2 = "/savepreset";

-- Configuration UI Integration
function DynamicCamera:AddConfigControls()
    local parent = DConfigScrollChild or DConfigFrame;
    if not parent then
        return;
    end
    
    -- Verify DConfigFontLabel exists
    if not DConfigFontLabel then
        return;
    end
    
    -- Create camera section title
    local cameraTitle = parent:CreateFontString("DCameraSectionTitle", "OVERLAY", "DQuestButtonTitleGossip");
    cameraTitle:SetPoint("TOPLEFT", DConfigFontLabel, "BOTTOMLEFT", 0, -35);
    cameraTitle:SetText("Configuracion de Camara");
    cameraTitle:SetJustifyH("LEFT");
    SetFontColor(cameraTitle, "DarkBrown");
    
    -- Camera enabled checkbox
    local cameraEnabledCheckbox = CreateFrame("CheckButton", "DCameraEnabledCheckbox", parent, "UICheckButtonTemplate");
    cameraEnabledCheckbox:SetPoint("TOPLEFT", cameraTitle, "BOTTOMLEFT", 0, -10);
    cameraEnabledCheckbox:SetScale(0.8);
    cameraEnabledCheckbox:SetChecked(self.config.enabled);
    
    local cameraEnabledLabel = parent:CreateFontString("DCameraEnabledLabel", "OVERLAY", "DQuestButtonTitleGossip");
    cameraEnabledLabel:SetPoint("LEFT", cameraEnabledCheckbox, "RIGHT", 5, 0);
    cameraEnabledLabel:SetText("Activar Camara Dinamica");
    SetFontColor(cameraEnabledLabel, "DarkBrown");
    
    cameraEnabledCheckbox:SetScript("OnClick", function()
        DynamicCamera.config.enabled = cameraEnabledCheckbox:GetChecked();
        DynamicCamera:SaveConfig();
    end);
    
    -- Settings display
    local settingsRow = parent:CreateFontString("DCameraSettingsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    settingsRow:SetPoint("TOPLEFT", cameraEnabledCheckbox, "BOTTOMLEFT", 0, -20);
    settingsRow:SetText("Configuracion Actual: Distancia " .. string.format("%.1f", self.config.interactionDistance) .. 
                       " | Angulo " .. string.format("%.1f", self.config.interactionPitch) .. 
                       " | Velocidad " .. string.format("%.1f", self.config.transitionSpeed));
    SetFontColor(settingsRow, "DarkBrown");
    self.settingsLabel = settingsRow;
    
    -- Interaction types
    local typesLabel = parent:CreateFontString("DInteractionTypesLabel", "OVERLAY", "DQuestButtonTitleGossip");
    typesLabel:SetPoint("TOPLEFT", settingsRow, "BOTTOMLEFT", 0, -15);
    typesLabel:SetText("Activar para:");
    SetFontColor(typesLabel, "DarkBrown");
    
    -- Checkboxes for interaction types
    local checkboxData = {
        {name = "Comercio", config = "enableForGossip", yOffset = -10},
        {name = "Vendedores", config = "enableForVendors", yOffset = -35},
        {name = "Entrenadores", config = "enableForTrainers", yOffset = -60},
        {name = "Misiones", config = "enableForQuests", yOffset = -85}
    };
    
    for i, data in ipairs(checkboxData) do
        local checkbox = CreateFrame("CheckButton", "DCamera" .. data.name .. "Checkbox", parent, "UICheckButtonTemplate");
        checkbox:SetPoint("TOPLEFT", typesLabel, "BOTTOMLEFT", 0, data.yOffset);
        checkbox:SetScale(0.7);
        checkbox:SetChecked(self.config[data.config]);
        
        local label = parent:CreateFontString("DCamera" .. data.name .. "Label", "OVERLAY", "DQuestButtonTitleGossip");
        label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0);
        label:SetText(data.name);
        SetFontColor(label, "DarkBrown");
        
        checkbox:SetScript("OnClick", function()
            DynamicCamera.config[data.config] = checkbox:GetChecked();
            DynamicCamera:SaveConfig();
        end);
    end
    
    -- Quick preset section
    local presetsLabel = parent:CreateFontString("DCameraPresetsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    presetsLabel:SetPoint("TOPLEFT", typesLabel, "BOTTOMLEFT", 0, -120);
    presetsLabel:SetText("Presets de Camara (aplicar al hablar con NPCs):");
    presetsLabel:SetJustifyH("LEFT");
    SetFontColor(presetsLabel, "DarkBrown");
    
    -- Preset buttons (4 presets in a row)
    local presets = {"Cinematica", "Cerca", "Normal", "Amplia"};
    local presetConfigs = {
        {distance = 6, pitch = -0.5},   -- Cinematic
        {distance = 4, pitch = -0.2},   -- Close  
        {distance = 8, pitch = -0.3},   -- Normal
        {distance = 12, pitch = -0.1}   -- Wide
    };
    
    -- Create preset buttons manually (avoiding loops that may fail in Vanilla)
    
    -- Button 1: Cinematica
    local btn1Text = parent:CreateFontString("DCameraBtn1Text", "OVERLAY", "DQuestButtonTitleGossip");
    btn1Text:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -10);
    btn1Text:SetText("[Cinematica]");
    btn1Text:SetJustifyH("LEFT");
    SetFontColor(btn1Text, "DarkBrown");
    
    -- Button 2: Cerca  
    local btn2Text = parent:CreateFontString("DCameraBtn2Text", "OVERLAY", "DQuestButtonTitleGossip");
    btn2Text:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 85, -10);
    btn2Text:SetText("[Cerca]");
    btn2Text:SetJustifyH("LEFT");
    SetFontColor(btn2Text, "DarkBrown");
    
    -- Button 3: Normal
    local btn3Text = parent:CreateFontString("DCameraBtn3Text", "OVERLAY", "DQuestButtonTitleGossip");
    btn3Text:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 170, -10);
    btn3Text:SetText("[Normal]");
    btn3Text:SetJustifyH("LEFT");
    SetFontColor(btn3Text, "DarkBrown");
    
    -- Button 4: Amplia
    local btn4Text = parent:CreateFontString("DCameraBtn4Text", "OVERLAY", "DQuestButtonTitleGossip");
    btn4Text:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 255, -10);
    btn4Text:SetText("[Amplia]");
    btn4Text:SetJustifyH("LEFT");
    SetFontColor(btn4Text, "DarkBrown");
    
    
    -- Now create clickable areas manually
    
    -- Try creating simple buttons instead of frames
    
    -- Button 1: Cinematica
    local btn1 = CreateFrame("Button", "DCameraBtn1", parent, "DUIPanelButtonTemplate");
    if btn1 then
        
        -- Use SetWidth/SetHeight instead of SetSize for compatibility
        btn1:SetWidth(80);
        btn1:SetHeight(22);
        
        -- Set position
        btn1:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -10);
        
        -- Set text using template method
        btn1:SetText("[Cinematica]");
        
        -- Set click handler
        btn1:SetScript("OnClick", function()
            DynamicCamera.config.interactionDistance = 6;
            DynamicCamera.config.interactionPitch = -0.5;
            DynamicCamera:SaveConfig();
            
            -- Update settings display with smooth transition
            if DynamicCamera.settingsLabel then
                DynamicCamera.settingsLabel:SetText("");
                local updateFrame = CreateFrame("Frame");
                local elapsed = 0;
                updateFrame:SetScript("OnUpdate", function()
                    elapsed = elapsed + arg1;
                    if elapsed >= 0.1 then
                        DynamicCamera.settingsLabel:SetText("Configuracion Actual: Distancia 6.0 | Angulo -0.5 | Velocidad " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
                        updateFrame:SetScript("OnUpdate", nil);
                    end
                end);
            end
        end);
    else
    end
    
    -- Button 2: Cerca
    local btn2 = CreateFrame("Button", "DCameraBtn2", parent, "DUIPanelButtonTemplate");
    if btn2 then
        btn2:SetWidth(80);
        btn2:SetHeight(22);
        btn2:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 85, -10);
        btn2:SetText("[Cerca]");
        btn2:SetScript("OnClick", function()
            DynamicCamera.config.interactionDistance = 4;
            DynamicCamera.config.interactionPitch = -0.2;
            DynamicCamera:SaveConfig();
            
            -- Update settings display with smooth transition
            if DynamicCamera.settingsLabel then
                DynamicCamera.settingsLabel:SetText("");
                local updateFrame = CreateFrame("Frame");
                local elapsed = 0;
                updateFrame:SetScript("OnUpdate", function()
                    elapsed = elapsed + arg1;
                    if elapsed >= 0.1 then
                        DynamicCamera.settingsLabel:SetText("Configuracion Actual: Distancia 4.0 | Angulo -0.2 | Velocidad " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
                        updateFrame:SetScript("OnUpdate", nil);
                    end
                end);
            end
        end);
    else
    end
    
    -- Button 3: Normal
    local btn3 = CreateFrame("Button", "DCameraBtn3", parent, "DUIPanelButtonTemplate");
    if btn3 then
        btn3:SetWidth(80);
        btn3:SetHeight(22);
        btn3:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 170, -10);
        btn3:SetText("[Normal]");
        btn3:SetScript("OnClick", function()
            DynamicCamera.config.interactionDistance = 8;
            DynamicCamera.config.interactionPitch = -0.3;
            DynamicCamera:SaveConfig();
            
            -- Update settings display with smooth transition
            if DynamicCamera.settingsLabel then
                DynamicCamera.settingsLabel:SetText("");
                local updateFrame = CreateFrame("Frame");
                local elapsed = 0;
                updateFrame:SetScript("OnUpdate", function()
                    elapsed = elapsed + arg1;
                    if elapsed >= 0.1 then
                        DynamicCamera.settingsLabel:SetText("Configuracion Actual: Distancia 8.0 | Angulo -0.3 | Velocidad " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
                        updateFrame:SetScript("OnUpdate", nil);
                    end
                end);
            end
        end);
    else
    end
    
    -- Button 4: Amplia
    local btn4 = CreateFrame("Button", "DCameraBtn4", parent, "DUIPanelButtonTemplate");
    if btn4 then
        btn4:SetWidth(80);
        btn4:SetHeight(22);
        btn4:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 255, -10);
        btn4:SetText("[Amplia]");
        btn4:SetScript("OnClick", function()
            DynamicCamera.config.interactionDistance = 12;
            DynamicCamera.config.interactionPitch = -0.1;
            DynamicCamera:SaveConfig();
            
            -- Update settings display with smooth transition
            if DynamicCamera.settingsLabel then
                DynamicCamera.settingsLabel:SetText("");
                local updateFrame = CreateFrame("Frame");
                local elapsed = 0;
                updateFrame:SetScript("OnUpdate", function()
                    elapsed = elapsed + arg1;
                    if elapsed >= 0.1 then
                        DynamicCamera.settingsLabel:SetText("Configuracion Actual: Distancia 12.0 | Angulo -0.1 | Velocidad " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
                        updateFrame:SetScript("OnUpdate", nil);
                    end
                end);
            end
        end);
    else
    end
    
    
    -- Save Current Camera button
    local saveCurrentBtn = CreateFrame("Button", "DSaveCurrentButton", parent, "DUIPanelButtonTemplate");
    saveCurrentBtn:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -45);
    saveCurrentBtn:SetWidth(140);
    saveCurrentBtn:SetHeight(22);                           
    saveCurrentBtn:SetText("Guardar Posicion Actual");
    saveCurrentBtn:SetScript("OnClick", function()
        DynamicCamera:SaveCameraPreset();
        
        -- Update status indicator if it exists
        if DynamicCamera.presetStatus then
            DynamicCamera.presetStatus:SetText("Estado: Posicion personalizada guardada ✓");
        end
    end);
    
    -- Add preset status indicator
    local presetStatus = parent:CreateFontString("DPresetStatus", "OVERLAY", "DQuestButtonTitleGossip");
    presetStatus:SetPoint("TOPLEFT", saveCurrentBtn, "BOTTOMLEFT", 0, -10);
    presetStatus:SetJustifyH("LEFT");
    SetFontColor(presetStatus, "DarkBrown");
    
    -- Show current preset status
    if self.config.usePresetRestore and self.config.savedCameraDistance then
        presetStatus:SetText("Estado: Posicion personalizada guardada ✓");
    else
        presetStatus:SetText("Estado: Usando restauracion por defecto");
    end
    
    -- Store reference for updates
    
end

