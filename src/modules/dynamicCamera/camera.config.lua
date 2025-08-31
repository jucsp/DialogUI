-- Dynamic Camera Configuration Integration
-- Extends the DialogUI config window with camera controls

-- Debug message to confirm file is loading
DEFAULT_CHAT_FRAME:AddMessage("DialogUI: camera.config.lua cargando...");

-- Add camera controls to the config window
function DynamicCamera:AddConfigControls()
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Intentando agregar controles de camara...");
    
    local parent = DConfigScrollChild or DConfigFrame;
    if not parent then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: ERROR - No se encontro DConfigScrollChild o DConfigFrame");
        return; -- Config frame not available yet
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Parent encontrado: " .. (parent:GetName() or "unknown"));
    
    -- Verify DConfigFontLabel exists
    if not DConfigFontLabel then
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: ERROR - DConfigFontLabel no existe");
        return;
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: DConfigFontLabel encontrado, creando seccion de camara...");
    
    -- Create camera section title
    local cameraTitle = parent:CreateFontString("DCameraSectionTitle", "OVERLAY", "DQuestButtonTitleGossip");
    cameraTitle:SetPoint("TOP", DConfigFontLabel, "BOTTOM", 0, -35);
    cameraTitle:SetText("Configuracion de Camara");
    cameraTitle:SetJustifyH("LEFT");
    SetFontColor(cameraTitle, "DarkBrown");
    
    -- Camera enabled checkbox
    local cameraEnabledCheckbox = CreateFrame("CheckButton", "DCameraEnabledCheckbox", parent, "UICheckButtonTemplate");
    cameraEnabledCheckbox:SetPoint("TOPLEFT", cameraTitle, "BOTTOMLEFT", 0, -10);
    cameraEnabledCheckbox:SetScale(0.8);
    cameraEnabledCheckbox:SetChecked(DynamicCamera.config.enabled);
    
    local cameraEnabledLabel = parent:CreateFontString("DCameraEnabledLabel", "OVERLAY", "DQuestButtonTitleGossip");
    cameraEnabledLabel:SetPoint("LEFT", cameraEnabledCheckbox, "RIGHT", 5, 0);
    cameraEnabledLabel:SetText("Activar Camara Dinamica");
    SetFontColor(cameraEnabledLabel, "DarkBrown");
    
    cameraEnabledCheckbox:SetScript("OnClick", function()
        DynamicCamera.config.enabled = cameraEnabledCheckbox:GetChecked();
        DynamicCamera:SaveConfig();
        
        local status = DynamicCamera.config.enabled and "activada" or "desactivada";
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Camara Dinamica " .. status);
    end);
    
    -- Settings display
    local settingsRow = parent:CreateFontString("DCameraSettingsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    settingsRow:SetPoint("TOPLEFT", cameraEnabledCheckbox, "BOTTOMLEFT", 0, -20);
    settingsRow:SetText("Distancia: " .. string.format("%.1f", DynamicCamera.config.interactionDistance) .. 
                       " | Angulo: " .. string.format("%.1f", DynamicCamera.config.interactionPitch) .. 
                       " | Velocidad: " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
    SetFontColor(settingsRow, "DarkBrown");
    
    -- Store reference for updates
    DynamicCamera.settingsLabel = settingsRow;
    
    -- Interaction types
    local typesLabel = parent:CreateFontString("DInteractionTypesLabel", "OVERLAY", "DQuestButtonTitleGossip");
    typesLabel:SetPoint("TOPLEFT", settingsRow, "BOTTOMLEFT", 0, -15);
    typesLabel:SetText("Activar para: ");
    SetFontColor(typesLabel, "DarkBrown");
    
    -- Horizontal layout for checkboxes
    local checkboxes = {};
    local checkboxData = {
        {name = "Comercio", config = "enableForGossip", xOffset = 0},
        {name = "Vendedores", config = "enableForVendors", xOffset = 80},
        {name = "Entrenadores", config = "enableForTrainers", xOffset = 160},
        {name = "Misiones", config = "enableForQuests", xOffset = 240}
    };
    
    for i, data in ipairs(checkboxData) do
        local checkbox = CreateFrame("CheckButton", "DCamera" .. data.name .. "Checkbox", parent, "UICheckButtonTemplate");
        checkbox:SetPoint("TOPLEFT", typesLabel, "BOTTOMLEFT", data.xOffset, -10);
        checkbox:SetScale(0.7);
        checkbox:SetChecked(DynamicCamera.config[data.config]);
        
        local label = parent:CreateFontString("DCamera" .. data.name .. "Label", "OVERLAY", "DQuestButtonTitleGossip");
        label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0);
        label:SetText(data.name);
        SetFontColor(label, "DarkBrown");
        
        checkbox:SetScript("OnClick", function()
            DynamicCamera.config[data.config] = checkbox:GetChecked();
            DynamicCamera:SaveConfig();
        end);
        
        checkboxes[i] = {checkbox = checkbox, label = label};
    end
    
    -- Quick preset section
    local presetsLabel = parent:CreateFontString("DCameraPresetsLabel", "OVERLAY", "DQuestButtonTitleGossip");
    presetsLabel:SetPoint("TOPLEFT", typesLabel, "BOTTOMLEFT", 0, -45);
    presetsLabel:SetText("Vistas Rapidas:");
    SetFontColor(presetsLabel, "DarkBrown");
    
    -- Save Current Camera Preset button
    local savePresetBtn = CreateFrame("Button", "DSavePresetButton", parent, "DUIPanelButtonTemplate");
    savePresetBtn:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -10);
    savePresetBtn:SetSize(150, 25);
    savePresetBtn:SetText("Guardar Vista Actual");
    savePresetBtn:SetScript("OnClick", function()
        -- Save current camera settings as user preset
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Vista actual guardada como preset personalizado");
    end);
    
    -- Preset info
    local presetInfo = parent:CreateFontString("DCameraPresetInfo", "OVERLAY", "DQuestButtonTitleGossip");
    presetInfo:SetPoint("TOPLEFT", savePresetBtn, "BOTTOMLEFT", 0, -5);
    presetInfo:SetWidth(300);
    presetInfo:SetJustifyH("LEFT");
    presetInfo:SetText("Ajusta tu camara como quieres que quede despues de hablar con NPCs, luego guarda la vista.");
    SetFontColor(presetInfo, "LightBrown");
    
    local presets = {"Cinematic", "Close", "Normal", "Wide"};
    local presetNames = {"Cinematica", "Cerca", "Normal", "Amplia"};
    for i, presetName in ipairs(presets) do
        local button = CreateFrame("Button", "DCamera" .. presetName .. "Button", parent, "DUIPanelButtonTemplate");
        button:SetText(presetNames[i]);
        button:SetSize(80, 22);
        
        -- Position buttons in a row
        button:SetPoint("TOPLEFT", presetInfo, "BOTTOMLEFT", (i-1) * 85, -10);
        button:SetScript("OnClick", function()
            DynamicCamera:ApplyPreset(string.lower(presetName));
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Vista '" .. presetNames[i] .. "' aplicada");
            -- Update display
            if DynamicCamera.settingsLabel then
                DynamicCamera.settingsLabel:SetText("Distancia: " .. string.format("%.1f", DynamicCamera.config.interactionDistance) .. 
                                                   " | Angulo: " .. string.format("%.1f", DynamicCamera.config.interactionPitch) .. 
                                                   " | Velocidad: " .. string.format("%.1f", DynamicCamera.config.transitionSpeed));
            end
        end);
    end
    
    -- Debug: Confirm camera section was created
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Seccion de camara creada con " .. #presets .. " botones de preset");
end

-- Confirm function was defined
DEFAULT_CHAT_FRAME:AddMessage("DialogUI: AddConfigControls function definida correctamente");

-- Test camera presets
function DynamicCamera:ApplyPreset(presetName)
    if presetName == "cinematic" then
        self.config.interactionDistance = 6;
        self.config.interactionPitch = -0.5;
    elseif presetName == "close" then
        self.config.interactionDistance = 4;
        self.config.interactionPitch = -0.2;
    elseif presetName == "normal" then
        self.config.interactionDistance = 8;
        self.config.interactionPitch = -0.3;
    elseif presetName == "wide" then
        self.config.interactionDistance = 12;
        self.config.interactionPitch = -0.1;
    end
    
    self:SaveConfig();
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Vista de camara '" .. presetName .. "' aplicada");
end

-- Preset commands
SlashCmdList["CAMERA_PRESET"] = function(msg)
    local preset = string.lower(msg or "");
    if preset == "cinematic" or preset == "close" or preset == "normal" or preset == "wide" then
        DynamicCamera:ApplyPreset(preset);
    else
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Vistas disponibles: cinematic, close, normal, wide");
        DEFAULT_CHAT_FRAME:AddMessage("Uso: /camerapreset [nombre_vista]");
    end
end;
SLASH_CAMERA_PRESET1 = "/camerapreset";
