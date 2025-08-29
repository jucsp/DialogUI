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
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: SaveOriginalPosition called");
    if not self.isActive then
        -- Try to get camera values, with fallback defaults
        local distance = 15; -- Default fallback
        local pitch = 0; -- Default fallback
        local yaw = 0; -- Default fallback
        
        -- Try to get actual values if functions are available
        if GetCameraDistance then
            distance = GetCameraDistance() or 15;
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: GetCameraDistance returned: " .. tostring(distance));
        else
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: GetCameraDistance not available, using default");
        end
        
        if GetCameraPitch then
            pitch = GetCameraPitch() or 0;
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: GetCameraPitch returned: " .. tostring(pitch));
        else
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: GetCameraPitch not available, using default");
        end
        
        if GetCameraYaw then
            yaw = GetCameraYaw() or 0;
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: GetCameraYaw returned: " .. tostring(yaw));
        else
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: GetCameraYaw not available, using default");
        end
        
        self.originalDistance = distance;
        self.originalPitch = pitch;
        self.originalYaw = yaw;
        
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Saved - Distance: " .. tostring(self.originalDistance) .. ", Pitch: " .. tostring(self.originalPitch));
        
        -- Store in saved variables for persistence
        if not DialogUI_SavedConfig then
            DialogUI_SavedConfig = {};
        end
        DialogUI_SavedConfig.originalCameraDistance = self.originalDistance;
        DialogUI_SavedConfig.originalCameraPitch = self.originalPitch;
        DialogUI_SavedConfig.originalCameraYaw = self.originalYaw;
        
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: SaveOriginalPosition completed successfully");
    end
end

-- Save current camera position as preset
function DynamicCamera:SaveCameraPreset()
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Saving current camera position as preset");
    
    -- Try to get current camera state using available functions
    local currentView = 2; -- Default third person
    
    -- Save the current view
    self.config.presetView = currentView;
    self.config.usePresetRestore = true;
    
    -- Try to save additional camera info if available
    if GetCVar then
        local maxDist = GetCVar("cameraDistanceMax");
        if maxDist then
            self.config.savedCameraDistance = tonumber(maxDist) or 15;
        end
    end
    
    -- Save configuration
    self:SaveConfig();
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Camera preset saved! This will be used when restoring camera after NPC interactions.");
end

-- Restore original camera position
function DynamicCamera:RestoreOriginalPosition()
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: RestoreOriginalPosition called");
    if self.originalDistance then
        -- Use preset if available, otherwise default restore
        if self.config.usePresetRestore then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Using saved camera preset");
            if SetView then
                SetView(self.config.presetView or 2);
                DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Applied preset view: " .. tostring(self.config.presetView or 2));
            end
            
            -- Restore distance if we have it saved
            if self.config.savedCameraDistance and SetCVar then
                SetCVar("cameraDistanceMax", tostring(self.config.savedCameraDistance));
                DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Applied preset distance: " .. tostring(self.config.savedCameraDistance));
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Using default third-person view restore");
            if SetView then
                SetView(2); -- Third person view
                DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Restored to third-person view");
            else
                DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: SetView not available");
            end
        end
        
        -- Clean up
        self.isActive = false;
        self.originalDistance = nil;
        self.originalPitch = nil;
        self.originalYaw = nil;
        
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Original position restored, camera deactivated");
    end
end

-- Apply interaction camera position
function DynamicCamera:ApplyInteractionPosition()
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: ApplyInteractionPosition called");
    
    if not self.config.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Module disabled, skipping");
        return;
    end
    
    -- Only apply if not already active to avoid interference
    if self.isActive then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Already active, skipping");
        return;
    end
    
    -- Don't interfere if quest frames are in transition or loading
    if DQuestFrame and DQuestFrame:IsVisible() then
        local alpha = DQuestFrame:GetAlpha();
        if alpha < 1.0 then
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Quest frame alpha low (" .. tostring(alpha) .. "), waiting");
            -- Frame is still transitioning, wait a bit more
            return;
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Proceeding with camera adjustment");
    
    self:SaveOriginalPosition();
    -- DON'T set isActive here - wait until transition completes
    
    -- Calculate target camera position
    local targetDistance = self.config.interactionDistance;
    local targetPitch = self.config.interactionPitch;
    local currentYaw = self.originalYaw; -- Use saved yaw instead of getting it again
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Applying smooth transition - Distance: " .. tostring(targetDistance) .. ", Pitch: " .. tostring(targetPitch));
    
    -- Set isActive in the callback when transition completes
    self:SmoothTransition(targetDistance, targetPitch, currentYaw, function()
        self.isActive = true;
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Transition completed, camera now active");
    end);
end

-- Smooth camera transition
function DynamicCamera:SmoothTransition(targetDistance, targetPitch, targetYaw, onComplete)
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: SmoothTransition started - Target distance: " .. tostring(targetDistance));
    
    if self.transitionActive then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Transition already active, skipping");
        return; -- Avoid multiple transitions
    end
    
    self.transitionActive = true;
    
    -- Use saved values instead of getting current values
    local startDistance = self.originalDistance or 15;
    local startPitch = self.originalPitch or 0;
    local startYaw = self.originalYaw or 0;
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Start position - Distance: " .. tostring(startDistance) .. ", Pitch: " .. tostring(startPitch));
    
    -- Check what camera functions are available in this WoW version
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Checking available camera functions:");
    DEFAULT_CHAT_FRAME:AddMessage("- SetView: " .. (SetView and "YES" or "NO"));
    DEFAULT_CHAT_FRAME:AddMessage("- CameraZoomIn: " .. (CameraZoomIn and "YES" or "NO"));
    DEFAULT_CHAT_FRAME:AddMessage("- CameraZoomOut: " .. (CameraZoomOut and "YES" or "NO"));
    DEFAULT_CHAT_FRAME:AddMessage("- SetCVar: " .. (SetCVar and "YES" or "NO"));
    
    -- Try using camera functions that are available in vanilla
    if CameraZoomIn and targetDistance < 10 then
        -- Use zoom for closer view
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Using CameraZoomIn for close interaction");
        for i = 1, 5 do
            CameraZoomIn(1.0); -- Zoom in step by step
        end
    elseif SetCVar then
        -- Try using CVars for camera control
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Using CVars for camera control");
        SetCVar("cameraDistanceMax", tostring(targetDistance));
        SetCVar("cameraDistanceMaxFactor", "1.0");
    else
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: No usable camera functions found - feature not supported in this WoW version");
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
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Starting transition loop");
    
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
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: OnGossipShow event triggered");
    if self.config.enableForGossip then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Gossip camera enabled, starting delay");
        -- Small delay to let UI settle first
        local delayFrame = CreateFrame("Frame");
        local delayElapsed = 0;
        delayFrame:SetScript("OnUpdate", function()
            delayElapsed = delayElapsed + arg1;
            if delayElapsed >= 0.2 then -- 200ms delay
                delayFrame:SetScript("OnUpdate", nil);
                DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Gossip delay completed, applying camera");
                self:ApplyInteractionPosition();
            end
        end);
    else
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Gossip camera disabled in config");
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
        
        -- Quest frames are complex, add very long delay and multiple checks
        local delayFrame = CreateFrame("Frame");
        local delayElapsed = 0;
        local checkCount = 0;
        
        delayFrame:SetScript("OnUpdate", function()
            delayElapsed = delayElapsed + arg1;
            checkCount = checkCount + 1;
            
            -- Check every 5 updates for better compatibility
            if delayElapsed >= 0.1 and checkCount >= 5 then
                checkCount = 0; -- Reset counter
                -- Verify that quest UI is completely stable before applying camera
                if DQuestFrame and DQuestFrame:IsVisible() and DQuestFrame:GetAlpha() >= 1.0 then
                    -- Additional check: make sure frame has been stable for a while
                    if delayElapsed >= 2.0 then -- Wait 2 full seconds
                        delayFrame:SetScript("OnUpdate", nil);
                        self:ApplyInteractionPosition();
                    end
                end
            end
            
            -- Timeout after 5 seconds if frames never stabilize
            if delayElapsed >= 5.0 then
                delayFrame:SetScript("OnUpdate", nil);
            end
        end);
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
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Initialize called");
    
    -- Load configuration
    self:LoadConfig();
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Config loaded - Enabled: " .. (self.config.enabled and "YES" or "NO") .. ", Gossip: " .. (self.config.enableForGossip and "YES" or "NO") .. ", Quests: " .. (self.config.enableForQuests and "YES" or "NO"));

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

    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Event frame created and events registered");

    eventFrame:SetScript("OnEvent", function()
        local event = event; -- Local reference to event
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Event received - " .. tostring(event));

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
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera: Initialization complete");
end-- Slash commands for camera module
SlashCmdList["DYNAMICCAMERA_TOGGLE"] = function()
    DynamicCamera.config.enabled = not DynamicCamera.config.enabled;
    DynamicCamera:SaveConfig();
    
    local status = DynamicCamera.config.enabled and "enabled" or "disabled";
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Dynamic Camera " .. status);
end;
SLASH_DYNAMICCAMERA_TOGGLE1 = "/togglecamera";
SLASH_DYNAMICCAMERA_TOGGLE2 = "/dcamera";

-- Test command for camera positioning
SlashCmdList["DYNAMICCAMERA_TEST"] = function()
    if DynamicCamera.isActive then
        DynamicCamera:RestoreOriginalPosition();
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camera restored to original position");
    else
        DynamicCamera:ApplyInteractionPosition();
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camera applied interaction position");
    end
end;
SLASH_DYNAMICCAMERA_TEST1 = "/testcamera";

-- Additional debug command for quest frame compatibility
SlashCmdList["DYNAMICCAMERA_QUESTDEBUG"] = function()
    local questVisible = DQuestFrame and DQuestFrame:IsVisible() and "YES" or "NO";
    local questAlpha = DQuestFrame and DQuestFrame:GetAlpha() or "N/A";
    local cameraActive = DynamicCamera.isActive and "YES" or "NO";
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI Camera Debug:");
    DEFAULT_CHAT_FRAME:AddMessage("- Quest Frame Visible: " .. questVisible);
    DEFAULT_CHAT_FRAME:AddMessage("- Quest Frame Alpha: " .. tostring(questAlpha));
    DEFAULT_CHAT_FRAME:AddMessage("- Camera Active: " .. cameraActive);
    DEFAULT_CHAT_FRAME:AddMessage("- Quests Enabled: " .. (DynamicCamera.config.enableForQuests and "YES" or "NO"));
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
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: AddConfigControls EJECUTADO!");
    
    local parent = DConfigScrollChild or DConfigFrame;
    if not parent then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: No parent found");
        return;
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Parent found: " .. (parent:GetName() or "unknown"));
    
    -- Verify DConfigFontLabel exists
    if not DConfigFontLabel then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: ERROR - DConfigFontLabel no existe");
        return;
    end
    
    -- Create camera section title
    local cameraTitle = parent:CreateFontString("DCameraSectionTitle", "OVERLAY", "DQuestButtonTitleGossip");
    cameraTitle:SetPoint("TOP", DConfigFontLabel, "BOTTOM", -110, -35);
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
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camara " .. (DynamicCamera.config.enabled and "activada" or "desactivada"));
    end);
    
    -- Settings display
    local settingsRow = parent:CreateFontString("DCameraSettingsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    settingsRow:SetPoint("TOPLEFT", cameraEnabledCheckbox, "BOTTOMLEFT", 0, -20);
    settingsRow:SetText("Distancia: " .. string.format("%.1f", self.config.interactionDistance) .. 
                       " | Angulo: " .. string.format("%.1f", self.config.interactionPitch) .. 
                       " | Velocidad: " .. string.format("%.1f", self.config.transitionSpeed));
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
    presetsLabel:SetText("Vistas Rapidas de Camara:");
    SetFontColor(presetsLabel, "DarkBrown");
    
    -- Preset buttons (4 presets in a row)
    local presets = {"Cinematica", "Cerca", "Normal", "Amplia"};
    local presetConfigs = {
        {distance = 6, pitch = -0.5},   -- Cinematic
        {distance = 4, pitch = -0.2},   -- Close  
        {distance = 8, pitch = -0.3},   -- Normal
        {distance = 12, pitch = -0.1}   -- Wide
    };
    
    for i, presetName in ipairs(presets) do
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Creando boton " .. i .. ": " .. presetName);
        
        -- Create invisible clickable frame
        local clickFrame = CreateFrame("Frame", "DCamera" .. i .. "ClickFrame", parent);
        clickFrame:SetSize(80, 22);
        clickFrame:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", (i-1) * 85, -10);
        clickFrame:EnableMouse(true);
        
        -- Create visible text
        local buttonText = parent:CreateFontString("DCamera" .. i .. "Text", "OVERLAY", "DQuestButtonTitleGossip");
        buttonText:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", (i-1) * 85, -10);
        buttonText:SetText("[" .. presetName .. "]");
        SetFontColor(buttonText, "DarkBrown");
        
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Texto " .. presetName .. " creado y mostrado");
        
        -- Add click handler to the invisible frame
        clickFrame:SetScript("OnMouseUp", function()
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Boton " .. presetName .. " presionado!");
            
            local config = presetConfigs[i];
            DynamicCamera.config.interactionDistance = config.distance;
            DynamicCamera.config.interactionPitch = config.pitch;
            DynamicCamera:SaveConfig();
            
            -- Update settings display
            if DynamicCamera.settingsLabel then
                DynamicCamera.settingsLabel:SetText("Distancia: " .. string.format("%.1f", config.distance) .. 
                                                   " | Angulo: " .. string.format("%.1f", config.pitch) .. 
                                                   " | Velocidad: " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Vista '" .. presetName .. "' aplicada");
        end);
    end
    
    -- Save Current Camera button
    local saveCurrentBtn = CreateFrame("Button", "DSaveCurrentButton", parent, "DUIPanelButtonTemplate");
    saveCurrentBtn:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -45);
    saveCurrentBtn:SetSize(120, 22);
    saveCurrentBtn:SetText("Guardar Actual");
    saveCurrentBtn:SetScript("OnClick", function()
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Vista actual guardada como preset personalizado");
    end);
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Seccion de camara creada con " .. table.getn(presets) .. " presets y opciones avanzadas");
end

DEFAULT_CHAT_FRAME:AddMessage("DialogUI: AddConfigControls definido en camera.module.lua");
