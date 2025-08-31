---@diagnostic disable: undefined-global

-- DialogUI Configuration System
DialogUI_Config = {
    scale = 1.0,        -- Frame scale (0.5 - 2.0)
    alpha = 1.0,        -- Frame transparency (0.1 - 1.0)
    fontSize = 1.0      -- Font size multiplier (0.5 - 2.0)
};

local COLORS = {
    DarkBrown = {0.19, 0.17, 0.13},
    LightBrown = {0.50, 0.36, 0.24},
    Ivory = {0.87, 0.86, 0.75}
};

function SetFontColor(fontObject, key)
    local color = COLORS[key];
    fontObject:SetTextColor(color[1], color[2], color[3]);
end

-- Main Config Frame Functions
function DConfigFrame_OnLoad()
    -- Disable dragging since it's always centered
    this:SetMovable(false);
    this:EnableMouse(true);
    
    -- Set initial info text with available commands
    local infoText = "Ajusta la configuración para personalizar tu experiencia con DialogUI.\n\n" ..
                    "Escala: Cambia el tamaño de todas las ventanas de diálogo (0.5 - 2.0)\n" ..
                    "Transparencia: Ajusta la opacidad del fondo (10% - 100%)\n" ..
                    "Tamaño de Fuente: Cambia el tamaño del texto en diálogos (0.5 - 2.0)\n" ..
                    "Cámara Dinámica: Ajusta suavemente la cámara durante interacciones con NPCs\n\n" ..
                    "Comandos Disponibles:\n" ..
                    "- /dialogui o /dialogui config: Abre esta ventana de configuración\n" ..
                    "- /dialogui reset: Restablece toda la configuración por defecto\n" ..
                    "- /togglecamera o /dcamera: Activa/desactiva la cámara dinámica\n" ..
                    "- /testcamera: Prueba el posicionamiento de cámara\n" ..
                    "- /camerapreset [preset]: Aplica vistas predefinidas (cinematic, close, normal, wide)\n\n" ..
                    "También puedes editar valores directamente en las cajas de texto.\n" ..
                    "Los cambios se aplican inmediatamente y se guardan automáticamente.";
    
    if DConfigInfoText then
        DConfigInfoText:SetText(infoText);
        SetFontColor(DConfigInfoText, "DarkBrown");
    end
end

function DConfigFrame_OnShow()
    PlaySound("igQuestListOpen");
    
    -- Always keep config frame at scale 1.0 and centered
    DConfigFrame:SetScale(1.0);
    DConfigFrame:ClearAllPoints();
    DConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    
    -- Initialize scroll frame
    if DConfigScrollFrame and DConfigScrollChild then
        DConfigScrollFrame:SetScrollChild(DConfigScrollChild);
        DConfigScrollFrame:SetHorizontalScroll(0);
        DConfigScrollFrame:SetVerticalScroll(0);
    end
    
    -- Set label colors
    local scaleLabel = getglobal("DConfigScaleLabel");
    if scaleLabel then
        SetFontColor(scaleLabel, "DarkBrown");
    end
    
    local alphaLabel = getglobal("DConfigAlphaLabel");
    if alphaLabel then
        SetFontColor(alphaLabel, "DarkBrown");
    end
    
    local fontLabel = getglobal("DConfigFontLabel");
    if fontLabel then
        SetFontColor(fontLabel, "DarkBrown");
    end
    
    -- Update EditBox values (with safety checks)
    local scaleEditBox = getglobal("DConfigScaleEditBox");
    if scaleEditBox then
        scaleEditBox:SetText(string.format("%.1f", DialogUI_Config.scale));
    end
    
    local alphaEditBox = getglobal("DConfigAlphaEditBox");
    if alphaEditBox then
        alphaEditBox:SetText(tostring(math.floor(DialogUI_Config.alpha * 100)));
    end
    
    local fontEditBox = getglobal("DConfigFontEditBox");
    if fontEditBox then
        fontEditBox:SetText(string.format("%.1f", DialogUI_Config.fontSize));
    end
    
    -- Apply current transparency to config frame background
    DialogUI_ApplyConfigAlpha();
    
    -- Add camera controls if DynamicCamera module is available
    if DynamicCamera then
        if DynamicCamera.AddConfigControls then
            DynamicCamera:AddConfigControls();
        else
            DEFAULT_CHAT_FRAME:AddMessage("DialogUI: ERROR - AddConfigControls no existe");
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: ERROR - DynamicCamera no existe");
    end
end

function DConfigFrame_OnHide()
    PlaySound("igQuestListClose");
end

-- EditBox Functions
function DConfigScaleEditBox_OnEnterPressed()
    local editBox = getglobal("DConfigScaleEditBox");
    if not editBox then return; end
    
    local text = editBox:GetText();
    -- Replace comma with dot for decimal support
    text = string.gsub(text, ",", ".");
    local value = tonumber(text);
    
    if value and value >= 0.5 and value <= 2.0 then
        DialogUI_Config.scale = value;
        editBox:SetText(string.format("%.1f", value));
        DialogUI_ApplyScale();
        DialogUI_SaveConfig();
        editBox:ClearFocus();
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Scale set to " .. string.format("%.1f", value));
    else
        editBox:SetText(string.format("%.1f", DialogUI_Config.scale));
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Scale must be between 0.5 and 2.0 (example: 1.5)");
    end
end

function DConfigAlphaEditBox_OnEnterPressed()
    local editBox = getglobal("DConfigAlphaEditBox");
    if not editBox then return; end
    
    local value = tonumber(editBox:GetText());
    if value and value >= 10 and value <= 100 then
        local alpha = value / 100;
        DialogUI_Config.alpha = alpha;
        editBox:SetText(tostring(value));
        DialogUI_ApplyAlpha();
        DialogUI_ApplyConfigAlpha();
        DialogUI_SaveConfig();
        editBox:ClearFocus();
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Transparency set to " .. value .. "%");
    else
        editBox:SetText(tostring(math.floor(DialogUI_Config.alpha * 100)));
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Transparency must be between 10 and 100 (whole numbers only)");
    end
end

function DConfigFontEditBox_OnEnterPressed()
    local editBox = getglobal("DConfigFontEditBox");
    if not editBox then return; end
    
    local text = editBox:GetText();
    -- Replace comma with dot for decimal support
    text = string.gsub(text, ",", ".");
    local value = tonumber(text);
    
    if value and value >= 0.5 and value <= 2.0 then
        DialogUI_Config.fontSize = value;
        editBox:SetText(string.format("%.1f", value));
        DialogUI_ApplyFontSize();
        DialogUI_SaveConfig();
        editBox:ClearFocus();
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Font size set to " .. string.format("%.1f", value));
    else
        editBox:SetText(string.format("%.1f", DialogUI_Config.fontSize));
        DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Font size must be between 0.5 and 2.0 (example: 1.2)");
    end
end

-- Button Functions
function DConfigResetButton_OnClick()
    -- Reset to default values
    DialogUI_Config.scale = 1.0;
    DialogUI_Config.alpha = 1.0;
    DialogUI_Config.fontSize = 1.0;
    
    -- Update EditBoxes
    local scaleEditBox = getglobal("DConfigScaleEditBox");
    if scaleEditBox then
        scaleEditBox:SetText("1.0");
    end
    
    local alphaEditBox = getglobal("DConfigAlphaEditBox");
    if alphaEditBox then
        alphaEditBox:SetText("100");
    end
    
    local fontEditBox = getglobal("DConfigFontEditBox");
    if fontEditBox then
        fontEditBox:SetText("1.0");
    end
    
    -- Apply changes
    DialogUI_ApplyAllSettings();
    DialogUI_SaveConfig();
    
    DEFAULT_CHAT_FRAME:AddMessage("DialogUI: Settings reset to default");
    PlaySound("igQuestListComplete");
end

function DConfigCloseButton_OnClick()
    HideUIPanel(DConfigFrame);
end

-- Configuration Application Functions
function DialogUI_ApplyScale()
    local scale = DialogUI_Config.scale;
    
    -- Only apply scale to dialog frames, NOT config frame
    if DQuestFrame then
        DQuestFrame:SetScale(scale);
    end
    if DGossipFrame then
        DGossipFrame:SetScale(scale);
    end
    -- Config frame keeps fixed scale of 1.0
end

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
    
    -- Config frame transparency is handled separately by DialogUI_ApplyConfigAlpha()
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

function DialogUI_ApplyFontSize()
    local fontSize = DialogUI_Config.fontSize;
    
    -- Apply to quest frame fonts
    if DQuestFrame then
        DialogUI_ScaleFonts(DQuestFrame, fontSize);
    end
    
    -- Apply to gossip frame fonts
    if DGossipFrame then
        DialogUI_ScaleFonts(DGossipFrame, fontSize);
    end
end

function DialogUI_ScaleFonts(frame, scale)
    if not frame then return; end
    
    -- Scale all FontString objects in the frame
    local regions = {frame:GetRegions()};
    for i = 1, table.getn(regions) do
        local region = regions[i];
        if region and region:GetObjectType() == "FontString" then
            local fontName, fontSize, fontFlags = region:GetFont();
            if fontName and fontSize then
                region:SetFont(fontName, fontSize * scale, fontFlags);
            end
        end
    end
    
    -- Recursively scale fonts in child frames
    local children = {frame:GetChildren()};
    for i = 1, table.getn(children) do
        local child = children[i];
        if child then
            DialogUI_ScaleFonts(child, scale);
        end
    end
end

function DialogUI_ApplyAllSettings()
    DialogUI_ApplyScale();
    DialogUI_ApplyAlpha();
    DialogUI_ApplyFontSize();
end

-- Configuration Saving/Loading (enhanced versions that override basic ones)
function DialogUI_SaveConfig()
    if not DialogUI_SavedConfig then
        DialogUI_SavedConfig = {};
    end
    
    DialogUI_SavedConfig.scale = DialogUI_Config.scale;
    DialogUI_SavedConfig.alpha = DialogUI_Config.alpha;
    DialogUI_SavedConfig.fontSize = DialogUI_Config.fontSize;
end

function DialogUI_LoadConfig()
    if DialogUI_SavedConfig then
        DialogUI_Config.scale = DialogUI_SavedConfig.scale or 1.0;
        DialogUI_Config.alpha = DialogUI_SavedConfig.alpha or 1.0;
        DialogUI_Config.fontSize = DialogUI_SavedConfig.fontSize or 1.0;
        
        -- Apply loaded settings
        DialogUI_ApplyAllSettings();
    end
end

-- Show/Hide Config Frame Functions (these will override the basic ones from quest.frame.lua)
function DialogUI_ShowConfig()
    if DConfigFrame then
        DConfigFrame:Show();
    end
end

function DialogUI_HideConfig()
    if DConfigFrame then
        DConfigFrame:Hide();
    end
end

-- Config Frame specific transparency function
function DialogUI_ApplyConfigAlpha()
    local alpha = DialogUI_Config.alpha;
    
    -- Apply transparency only to the background parchment of config frame
    if DConfigFrame then
        local layers = {DConfigFrame:GetRegions()};
        for i = 1, table.getn(layers) do
            if layers[i]:GetObjectType() == "Texture" then
                layers[i]:SetAlpha(alpha);
                break; -- Only first texture which is the background
            end
        end
    end
end

function DialogUI_ToggleConfig()
    if DConfigFrame:IsVisible() then
        DialogUI_HideConfig();
    else
        DialogUI_ShowConfig();
    end
end
