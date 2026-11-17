-- Brainrot Base Battles: the HUD the player sees over the 3D world.
-- One module, one job: build the ScreenGui once, then repaint it from the
-- server's once-a-second snapshot. Nothing here decides game rules; the
-- server validates every button the player presses. HUD text stays clear of
-- the top-left corner, where Roblox's own menu buttons sit.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local Hud = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local nextTierLabel = nil
local lockButton = nil
local rebirthButton = nil
local rowsFrame = nil
local notifyLabel = nil
local notifyTween = nil
local rowsByUid = {}

local function makeLabel(parent: Instance, name: string, text: string, size: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = parent
	return button
end

--- Build the whole HUD once. callbacks fires the server's remotes:
-- onLock(), onRebirth(), onUpgrade(uid).
function Hud.build(callbacks)
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = playerGui

	local title = makeLabel(gui, "Title", "BRAINROT BASE BATTLES", 24, Color3.fromRGB(255, 255, 255))
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 14)
	title.Size = UDim2.new(0, 420, 0, 30)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextStrokeTransparency = 0.5

	local moneyPanel = Instance.new("Frame")
	moneyPanel.Name = "MoneyPanel"
	moneyPanel.AnchorPoint = Vector2.new(1, 0)
	moneyPanel.Position = UDim2.new(1, -16, 0, 16)
	moneyPanel.Size = UDim2.new(0, 280, 0, 96)
	moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	moneyPanel.BackgroundTransparency = 0.25
	moneyPanel.BorderSizePixel = 0
	moneyPanel.Parent = gui
	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 10)
	moneyCorner.Parent = moneyPanel

	moneyLabel = makeLabel(moneyPanel, "Money", "$0", 32, Color3.fromRGB(120, 255, 140))
	moneyLabel.Position = UDim2.new(0, 14, 0, 6)
	moneyLabel.Size = UDim2.new(1, -28, 0, 38)
	incomeLabel = makeLabel(moneyPanel, "Income", "$0/s", 18, Color3.fromRGB(255, 255, 255))
	incomeLabel.Position = UDim2.new(0, 14, 0, 44)
	incomeLabel.Size = UDim2.new(1, -28, 0, 22)
	rebirthLabel = makeLabel(moneyPanel, "Rebirths", "Rebirths: 0", 16, Color3.fromRGB(255, 215, 0))
	rebirthLabel.Position = UDim2.new(0, 14, 0, 68)
	rebirthLabel.Size = UDim2.new(1, -28, 0, 22)

	local listPanel = Instance.new("Frame")
	listPanel.Name = "BrainrotPanel"
	listPanel.Position = UDim2.new(0, 16, 0, 120)
	listPanel.Size = UDim2.new(0, 300, 0, 320)
	listPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	listPanel.BackgroundTransparency = 0.25
	listPanel.BorderSizePixel = 0
	listPanel.Parent = gui
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 10)
	listCorner.Parent = listPanel

	local listTitle = makeLabel(listPanel, "Title", "YOUR BRAINROTS", 18, Color3.fromRGB(255, 255, 255))
	listTitle.Position = UDim2.new(0, 12, 0, 8)
	listTitle.Size = UDim2.new(1, -24, 0, 24)

	rowsFrame = Instance.new("Frame")
	rowsFrame.Name = "Rows"
	rowsFrame.Position = UDim2.new(0, 8, 0, 38)
	rowsFrame.Size = UDim2.new(1, -16, 1, -46)
	rowsFrame.BackgroundTransparency = 1
	rowsFrame.Parent = listPanel

	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.AnchorPoint = Vector2.new(0.5, 1)
	bottomBar.Position = UDim2.new(0.5, 0, 1, -16)
	bottomBar.Size = UDim2.new(0, 560, 0, 64)
	bottomBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	bottomBar.BackgroundTransparency = 0.25
	bottomBar.BorderSizePixel = 0
	bottomBar.Parent = gui
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = bottomBar

	nextTierLabel = makeLabel(bottomBar, "NextTier", "Next: -", 18, Color3.fromRGB(255, 255, 255))
	nextTierLabel.Position = UDim2.new(0, 14, 0, 0)
	nextTierLabel.Size = UDim2.new(0, 260, 1, 0)

	lockButton = makeButton(bottomBar, "LockButton", "LOCK BASE", Color3.fromRGB(70, 130, 230))
	lockButton.Position = UDim2.new(0, 284, 0, 10)
	lockButton.Size = UDim2.new(0, 130, 0, 44)
	lockButton.MouseButton1Click:Connect(function()
		callbacks.onLock()
	end)

	rebirthButton = makeButton(bottomBar, "RebirthButton", "REBIRTH", Color3.fromRGB(150, 80, 200))
	rebirthButton.Position = UDim2.new(0, 422, 0, 10)
	rebirthButton.Size = UDim2.new(0, 124, 0, 44)
	rebirthButton.MouseButton1Click:Connect(function()
		callbacks.onRebirth()
	end)

	notifyLabel = makeLabel(gui, "Notify", "", 20, Color3.fromRGB(255, 255, 255))
	notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
	notifyLabel.Position = UDim2.new(0.5, 0, 0, 64)
	notifyLabel.Size = UDim2.new(0, 640, 0, 30)
	notifyLabel.TextXAlignment = Enum.TextXAlignment.Center
	notifyLabel.TextStrokeTransparency = 0.5
	notifyLabel.TextTransparency = 1
end

--- One row of the brainrot list: name, income, level and its Upgrade button.
local function makeRow(uid: string, callbacks): Frame
	local row = Instance.new("Frame")
	row.Name = "Row_" .. uid
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row

	local nameLabel = makeLabel(row, "Name", "", 16, Color3.fromRGB(255, 255, 255))
	nameLabel.Position = UDim2.new(0, 8, 0, 2)
	nameLabel.Size = UDim2.new(1, -100, 0, 22)
	local incomeLabelRow = makeLabel(row, "Income", "", 14, Color3.fromRGB(120, 255, 140))
	incomeLabelRow.Position = UDim2.new(0, 8, 0, 22)
	incomeLabelRow.Size = UDim2.new(1, -100, 0, 20)
	local upgradeButton = makeButton(row, "Upgrade", "Up", Color3.fromRGB(60, 160, 80))
	upgradeButton.AnchorPoint = Vector2.new(1, 0.5)
	upgradeButton.Position = UDim2.new(1, -8, 0.5, 0)
	upgradeButton.Size = UDim2.new(0, 76, 0, 30)
	upgradeButton.TextSize = 14
	upgradeButton.MouseButton1Click:Connect(function()
		callbacks.onUpgrade(uid)
	end)
	row.Parent = rowsFrame
	return row
end

--- Repaint the HUD from the server's snapshot (money, income, lock, list).
function Hud.update(state, callbacks)
	if not gui then
		return
	end
	moneyLabel.Text = BrainrotData.formatMoney(state.money)
	incomeLabel.Text = BrainrotData.formatMoney(state.incomePerSecond) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.rebirths)
	if state.nextTier then
		nextTierLabel.Text = "Next: " .. state.nextTier.name .. "  ·  " .. BrainrotData.formatMoney(state.nextTier.cost)
	else
		nextTierLabel.Text = "Next: you own them all!"
	end
	if state.lockSecondsLeft > 0 then
		lockButton.Text = "LOCKED (" .. tostring(state.lockSecondsLeft) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
	elseif state.lockCooldownLeft > 0 then
		lockButton.Text = "LOCK IN " .. tostring(state.lockCooldownLeft) .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
	else
		lockButton.Text = "LOCK BASE"
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 130, 230)
	end
	local seen = {}
	for index, entry in ipairs(state.brainrots) do
		seen[entry.uid] = true
		local row = rowsByUid[entry.uid]
		if not row then
			row = makeRow(entry.uid, callbacks)
			rowsByUid[entry.uid] = row
		end
		row.LayoutOrder = index
		row.Position = UDim2.new(0, 0, 0, (index - 1) * 48)
		local nameLabel = row:FindFirstChild("Name")
		if nameLabel then
			nameLabel.Text = entry.name .. "  ·  " .. entry.mutation
			nameLabel.TextColor3 = BrainrotData.RARITY_COLORS[entry.rarity] or Color3.fromRGB(255, 255, 255)
		end
		local rowIncome = row:FindFirstChild("Income")
		if rowIncome then
			rowIncome.Text = BrainrotData.formatMoney(entry.income) .. "/s  ·  Lv" .. tostring(entry.level)
		end
		local upgradeButton = row:FindFirstChild("Upgrade")
		if upgradeButton then
			if entry.level >= BrainrotData.UPGRADE_MAX_LEVEL then
				upgradeButton.Text = "MAX"
			elseif entry.upgradeCost then
				upgradeButton.Text = "Up " .. BrainrotData.formatMoney(entry.upgradeCost)
			else
				upgradeButton.Text = "Up"
			end
		end
	end
	for uid, row in pairs(rowsByUid) do
		if not seen[uid] then
			row:Destroy()
			rowsByUid[uid] = nil
		end
	end
	if #state.brainrots == 0 then
		nextTierLabel.Text = "Buy a brainrot from the belt!"
	end
end

--- Flash a message across the top of the screen, then fade it out.
function Hud.notify(message: string)
	if not notifyLabel then
		return
	end
	if notifyTween then
		notifyTween:Cancel()
	end
	notifyLabel.Text = message
	notifyLabel.TextTransparency = 0
	notifyTween = TweenService:Create(notifyLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 2), { TextTransparency = 1 })
	notifyTween:Play()
end

return Hud
