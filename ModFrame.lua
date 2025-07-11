if Faceroll == nil then
    _, Faceroll = ...
end

local FONTS = {
    ["firamono"]="Interface\\AddOns\\Faceroll\\fonts\\FiraMono-Medium.ttf",
    ["forcedsquare"]="Interface\\AddOns\\Faceroll\\fonts\\FORCED SQUARE.ttf",
}

Faceroll.createFrame = function(
    width, height,
    corner, x, y,
    strata, alpha,
    justify, font, fontSize)

    local frFrame = {}

    local frame = CreateFrame("Frame")
    frame:SetPoint(corner, x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetFrameStrata(strata)
    local text = frame:CreateFontString(nil, "ARTWORK")
    text:SetFont(FONTS[font], fontSize, "OUTLINE")
    text:SetPoint(justify, 0,0)
    if justify == "TOPLEFT" then
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
    end
    frame.texture = frame:CreateTexture()
    frame.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    frame.texture:SetVertexColor(0.0, 0.0, 0.0, alpha)
    frame.texture:SetAllPoints(text)
    text:Show()
    frame:Show()

    frFrame.frame = frame
    frFrame.text = text
    frFrame.setText = function(self, text)
        self.text:SetText(text)
    end
    return frFrame
end
