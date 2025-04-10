----------------------------------------
--
-- ColorPicker.lua
--
-- Creates a frame containing a color picker.
--
----------------------------------------
GuiUtilities = require("../GuiUtilities")

local CustomTextButton = require("./CustomTextButton")
local VerticallyScalingListFrame = require("./VerticallyScalingListFrame")

local kColorPickedLabelHeight = 20

local ColorPickerClass = {}
ColorPickerClass.__index = ColorPickerClass

--- ColorPickerClass constructor.
--- @param nameSuffix string -- Suffix to append to the color picker's name.
--- @return ColorPickerClass -- A new instance of the color picker class.
function ColorPickerClass.new(nameSuffix: string)
  local self = setmetatable({}, ColorPickerClass)

  self._cancelFunction = nil
  self._confirmFunction = nil
  self._valueChangedFunction = nil

  local frame = Instance.new("Frame")
  frame.Name = "ClPck " .. nameSuffix
  frame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
  frame.BorderSizePixel = 0
  frame.Size = UDim2.fromOffset(170, 186)
  GuiUtilities.syncGuiElementBackgroundColor(frame)

  local colorSpectrum = Instance.new("ImageButton")
  colorSpectrum.Name = "ColorSpectrum"
  colorSpectrum.AnchorPoint = Vector2.new(0.5, 0)
  colorSpectrum.BackgroundColor3 = Color3.new(1, 1, 1)
  colorSpectrum.Image = "rbxassetid://138228531475439"
  colorSpectrum.Position = UDim2.new(0.5, 0, 0, 7)
  colorSpectrum.Size = UDim2.fromOffset(158, 118)
  colorSpectrum.Parent = frame
  GuiUtilities.syncGuiElementBorderColor(colorSpectrum)

  local cross = Instance.new("ImageLabel")
  cross.Name = "CrossIcon"
  cross.AnchorPoint = Vector2.new(0.5, 0.5)
  cross.BackgroundTransparency = 1
  cross.Image = "rbxassetid://15929013661"
  cross.Position = UDim2.fromScale(0, 0)
  cross.Size = UDim2.fromOffset(20, 20)
  cross.Parent = colorSpectrum

  local buttonsContainer = Instance.new("Frame")
  buttonsContainer.Name = "ButtonsContainer"
  buttonsContainer.AnchorPoint = Vector2.new(0.5, 1)
  buttonsContainer.BackgroundColor3 = Color3.fromRGB(169, 255, 129)
  buttonsContainer.BackgroundTransparency = 1
  buttonsContainer.BorderSizePixel = 0
  buttonsContainer.Position = UDim2.fromScale(0.5, 1)
  buttonsContainer.Size = UDim2.fromOffset(170, 36)
  buttonsContainer.Parent = frame

  local outputContainer = Instance.new("Frame")
  outputContainer.Name = "OutputContainer"
  outputContainer.AnchorPoint = Vector2.new(0.5, 1)
  outputContainer.BackgroundTransparency = 1
  outputContainer.BackgroundColor3 = Color3.fromRGB(40, 132, 181)
  outputContainer.BorderSizePixel = 0
  outputContainer.Position = UDim2.fromScale(0.5, 0.8)
  outputContainer.Size = UDim2.fromOffset(170, 24)
  outputContainer.Parent = frame

  local colorReference = Instance.new("Frame")
  colorReference.Name = "ColorReference"
  colorReference.AnchorPoint = Vector2.new(0, 0.5)
  colorReference.BackgroundColor3 = Color3.new(1, 1, 1)
  colorReference.Position = UDim2.new(0, 15, 0.5, 0)
  colorReference.Size = UDim2.new(0, 18, 0, 18)
  colorReference.Parent = outputContainer
  GuiUtilities.syncGuiElementBorderColor(colorReference)

  local colorRGBHexCode = Instance.new("TextBox")
  colorRGBHexCode.Name = "ColorRGBHexCode"
  colorRGBHexCode.AnchorPoint = Vector2.new(0, 0.5)
  colorRGBHexCode.BackgroundTransparency = 0
  colorRGBHexCode.BorderSizePixel = 0
  colorRGBHexCode.Font = Enum.Font.SourceSans
  colorRGBHexCode.Position = UDim2.new(0, 35, 0.5, 0)
  colorRGBHexCode.Size = UDim2.fromOffset(124, kColorPickedLabelHeight)
  colorRGBHexCode.Text = "255,255,255 #FFFFFF"
  colorRGBHexCode.TextSize = 15
  colorRGBHexCode.TextScaled = false
  colorRGBHexCode.Parent = outputContainer
  colorRGBHexCode.ClearTextOnFocus = false
  colorRGBHexCode.TextEditable = false
  GuiUtilities.syncGuiElementFontColor(colorRGBHexCode)
  GuiUtilities.syncGuiElementInputFieldColor(colorRGBHexCode)
  GuiUtilities.syncGuiElementBorderColor(colorRGBHexCode)

  colorSpectrum.InputBegan:Connect(function (inputObject: InputObject)
    if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    self._dragging = true
    self:_CalculatePickedColor(inputObject)
  end)

  colorSpectrum.InputChanged:Connect(function (inputObject)
    if not self._dragging then return end
    self:_CalculatePickedColor(inputObject)
  end)

  colorSpectrum.InputEnded:Connect(function (inputObject)
    if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    self._dragging = false
  end)

  local verticallyScalingFrame = VerticallyScalingListFrame.new("suffix")
  verticallyScalingFrame:GetFrame().Parent = buttonsContainer
  verticallyScalingFrame:GetFrame().AnchorPoint = Vector2.new(0, 0.5)
  verticallyScalingFrame:GetFrame().Position = UDim2.fromScale(0, 0.5)
  verticallyScalingFrame:SetHorizontalAlignment(Enum.HorizontalAlignment.Center)
  verticallyScalingFrame:SetVerticalAlignment(Enum.VerticalAlignment.Center)
  verticallyScalingFrame:SetFillDirection(Enum.FillDirection.Horizontal)
  verticallyScalingFrame:SetLayoutPadding(UDim.new(0, 5))

  local buttonConfirm = CustomTextButton.new("confirm", "Confirm", true)
  local buttonCancel = CustomTextButton.new("cancel", "Cancel", true)

  verticallyScalingFrame:AddChild(buttonConfirm:GetFrame())
  verticallyScalingFrame:AddChild(buttonCancel:GetFrame())

  self._frame = frame
  self._colorSpectrum = colorSpectrum
  self._colorReference = colorReference
  self._colorCodeBox = colorRGBHexCode
  self._colorCross = cross
  self._colorPicked = Color3.new(1,1,1) :: Color3
  self._buttonCancel = buttonCancel
  self._buttonConfirm = buttonConfirm
  self._dragging = false

  return self
end

function ColorPickerClass:_CalculatePickedColor(inputObject: InputObject)
  -- detect clicked color code based on the click position in the color spectrum image
  local clickPos = inputObject.Position
  local relX = (clickPos.X - self._colorSpectrum.AbsolutePosition.X) / self._colorSpectrum.AbsoluteSize.X
  local relY = (clickPos.Y - self._colorSpectrum.AbsolutePosition.Y) / self._colorSpectrum.AbsoluteSize.Y
  if relX >= 0 and relX <= 1 and relY >= 0 and relY <= 1 then
    local hue = relX * 360 -- Map X to Hue (0° → 360°)
    local fullColor = Color3.fromHSV(hue / 360, 1, 1) -- Pure color
    local colorPicked
    if relY < 0.5 then
      local alpha = relY * 2 -- White to Full Color
      colorPicked = Color3.new(1,1,1):Lerp(fullColor, alpha)
    else
      local alpha = (relY - 0.5) * 2 -- Full Color to Black
      colorPicked = fullColor:Lerp(Color3.new(0,0,0), alpha)
    end
    
    -- after finding it, generate a color code string like this: R,G,B #HEX
    local R, G, B = 0, 0, 0
    R = math.clamp(math.round(colorPicked.R * 255), 0, 255)
    G = math.clamp(math.round(colorPicked.G * 255), 0, 255)
    B = math.clamp(math.round(colorPicked.B * 255), 0, 255)
    
    self._colorReference.BackgroundColor3 = colorPicked
    self._colorCodeBox.Text = ("%d,%d,%d #%s"):format(R, G, B, string.upper(colorPicked:ToHex()))
    self._colorCross.Position = UDim2.fromScale(relX, relY)
    self._colorCross.ImageColor3 = if GuiUtilities.GetColorOverallBrightness(colorPicked) < 0.4 then Color3.new(1,1,1) else Color3.new(0,0,0)
    self._colorPicked = colorPicked
    if self._valueChangedFunction then -- fire value changed function
      self._valueChangedFunction(colorPicked)
    end
  end
end

--- Sets the function to be called when the cancel button is clicked.
--- @param cf function -- A function to execute when cancel is pressed.
function ColorPickerClass:SetCancelFunction(cf: () -> ())
  self._buttonCancel:SetClickedFunction(cf)
end

--- Sets the function to be called when the confirm button is clicked.
--- Passes the currently selected color to the callback.
--- @param cf function -- A function that takes the selected Color3 as a parameter.
function ColorPickerClass:SetConfirmFunction(cf: (chosenColor: Color3) -> ())
  self._buttonConfirm:SetClickedFunction(function (...)
    cf(self._colorPicked)
  end)
end

--- Sets a callback function to be called when the color value changes.
--- Passing nil will remove the existing callback.
--- @param vcf (newValue: Color3) -> () | nil -- Function to call on color change, or nil to unbind.
function ColorPickerClass:SetValueChangedFunction(vcf: (newValue: Color3) -> () | nil)
  self._valueChangedFunction = vcf
end

--- Returns the main UI frame of the color picker.
--- @return Frame -- The root frame containing the color picker UI.
function ColorPickerClass:GetFrame(): Frame
  return self._frame
end

--- Gets the currently selected color in the color picker.
--- @return Color3 -- The current color selection.
function ColorPickerClass:GetValue(): Color3
  return self._colorPicked
end

return ColorPickerClass