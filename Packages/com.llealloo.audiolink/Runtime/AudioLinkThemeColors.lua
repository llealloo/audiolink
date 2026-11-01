-- Custom theme colours for the CVR AudioLink controller.
--
-- The four colours are stored as twelve hidden sliders (H0 S0 V0 .. H3 S3 V3), each mirrored to a
-- networked, buffered CVRVariableBuffer. This script only converts HSV to RGB and paints the
-- materials, so every client and late joiner converges on the same colours without Lua networking.

UnityEngine = require("UnityEngine")

SLOTS = 4
CUSTOM_THEME_MODE = 1
selectedSlot = 0
applying = false

-- h, s, v in [0, 1]; matches UnityEngine.Color.HSVToRGB.
function HsvToRgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6

    if i == 0 then
        return v, t, p
    elseif i == 1 then
        return q, v, p
    elseif i == 2 then
        return p, v, t
    elseif i == 3 then
        return p, q, v
    elseif i == 4 then
        return t, p, v
    end
    return v, p, q
end

function Stored(channel, slot)
    return BoundObjects[channel .. slot]
end

-- Paints all four colours and shows the selected slot on the HSV sliders.
function ApplyThemeColors()
    local audioLink = BoundObjects["AudioLinkMaterial"]
    local screen = BoundObjects["ScreenMaterial"]

    for slot = 0, SLOTS - 1 do
        local r, g, b = HsvToRgb(Stored("H", slot).value, Stored("S", slot).value, Stored("V", slot).value)
        local color = UnityEngine.NewColor(r, g, b, 1)
        audioLink.SetColor("_CustomThemeColor" .. slot, color)
        screen.SetColor("_CustomColor" .. slot, color)
    end

    local h = Stored("H", selectedSlot).value
    local s = Stored("S", selectedSlot).value
    local v = Stored("V", selectedSlot).value

    -- Setting the visible sliders fires OnHsvChanged; ignore it.
    applying = true
    BoundObjects["Hue"].value = h
    BoundObjects["Saturation"].value = s
    BoundObjects["Value"].value = v
    applying = false

    screen.SetFloat("_SelectedColor", selectedSlot)
    screen.SetFloat("_Hue", h)
    screen.SetFloat("_Saturation", s)
    screen.SetFloat("_Value", v)
end

-- Writing a hidden slider triggers its buffer, which syncs and calls ApplyThemeColors everywhere.
function OnHsvChanged()
    if applying then
        return
    end

    Stored("H", selectedSlot).value = BoundObjects["Hue"].value
    Stored("S", selectedSlot).value = BoundObjects["Saturation"].value
    Stored("V", selectedSlot).value = BoundObjects["Value"].value
    BoundObjects["ThemeMode"].value = CUSTOM_THEME_MODE
    ApplyThemeColors()
end

-- The selected slot is local, as on the VRChat controller.
function SelectSlot(slot)
    selectedSlot = slot
    ApplyThemeColors()
end

function SelectSlot0() SelectSlot(0) end
function SelectSlot1() SelectSlot(1) end
function SelectSlot2() SelectSlot(2) end
function SelectSlot3() SelectSlot(3) end

function Start()
    ApplyThemeColors()
end
