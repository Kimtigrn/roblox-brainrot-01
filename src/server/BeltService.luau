-- Brainrot Base Battles: the conveyor belt.
-- BeltService spawns the cast at the west end, walks them east, despawns them
-- at the end, and sells them when a player answers the Buy prompt. A bought
-- brainrot leaves the belt and is handed to BaseService to place on a base.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local BeltService = {}

-- model -> true while it is walking the belt and can still be bought.
local beltModels = {}
local notifyRemote = nil

local function notifyPlayer(player: Player, message: string)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

--- The little extra part on top, by accessory name.
local function buildAccessory(accessory: string, headColor: Color3): Instance?
	if accessory == "Hat" then
		local hat = Instance.new("Part")
		hat.Name = "Accessory"
		hat.Size = Vector3.new(2.2, 0.4, 1.8)
		hat.Position = Vector3.new(0, 4.5, 0)
		hat.Color = Color3.fromRGB(60, 60, 70)
		hat.Material = Enum.Material.SmoothPlastic
		hat.Anchored = true
		hat.CanCollide = false
		return hat
	elseif accessory == "Antenna" then
		local antenna = Instance.new("Part")
		antenna.Name = "Accessory"
		antenna.Size = Vector3.new(0.2, 1.2, 0.2)
		antenna.Position = Vector3.new(0, 4.9, 0)
		antenna.Color = Color3.fromRGB(80, 80, 90)
		antenna.Material = Enum.Material.Metal
		antenna.Anchored = true
		antenna.CanCollide = false
		local tip = Instance.new("Part")
		tip.Name = "AccessoryTip"
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(0.6, 0.6, 0.6)
		tip.Position = Vector3.new(0, 5.6, 0)
		tip.Color = Color3.fromRGB(255, 80, 80)
		tip.Material = Enum.Material.Neon
		tip.Anchored = true
		tip.CanCollide = false
		tip.Parent = antenna
		return antenna
	elseif accessory == "Crown" then
		local crown = Instance.new("Part")
		crown.Name = "Accessory"
		crown.Size = Vector3.new(1.8, 0.5, 1.6)
		crown.Position = Vector3.new(0, 4.4, 0)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Material = Enum.Material.Metal
		crown.Anchored = true
		crown.CanCollide = false
		return crown
	elseif accessory == "Sunglasses" then
		local glasses = Instance.new("Part")
		glasses.Name = "Accessory"
		glasses.Size = Vector3.new(1.6, 0.4, 0.3)
		glasses.Position = Vector3.new(0, 3.7, 0.75)
		glasses.Color = Color3.fromRGB(20, 20, 25)
		glasses.Material = Enum.Material.SmoothPlastic
		glasses.Anchored = true
		glasses.CanCollide = false
		return glasses
	elseif accessory == "Bowtie" then
		local bowtie = Instance.new("Part")
		bowtie.Name = "Accessory"
		bowtie.Size = Vector3.new(1.2, 0.4, 0.3)
		bowtie.Position = Vector3.new(0, 2.8, 0.6)
		bowtie.Color = Color3.fromRGB(200, 30, 40)
		bowtie.Material = Enum.Material.SmoothPlastic
		bowtie.Anchored = true
		bowtie.CanCollide = false
		return bowtie
	elseif accessory == "Noodle" then
		local noodle = Instance.new("Part")
		noodle.Name = "Accessory"
		noodle.Shape = Enum.PartType.Ball
		noodle.Size = Vector3.new(0.5, 0.5, 0.5)
		noodle.Position = Vector3.new(0, 4.6, 0)
		noodle.Color = Color3.fromRGB(255, 240, 200)
		noodle.Material = Enum.Material.SmoothPlastic
		noodle.Anchored = true
		noodle.CanCollide = false
		return noodle
	end
	return nil
end

--- The floating label over a brainrot: name, rarity and mutation, income and price.
local function buildLabel(head: BasePart, brainrot, mutation, incomePerSecond: number)
	local label = Instance.new("BillboardGui")
	label.Name = "BrainrotLabel"
	label.Size = UDim2.fromOffset(240, 100)
	label.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	label.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = label

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.fromScale(0, 0.4)
	rarityLabel.Size = UDim2.fromScale(1, 0.3)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = brainrot.rarity .. "  ·  " .. mutation.name
	rarityLabel.TextColor3 = BrainrotData.RARITY_COLORS[brainrot.rarity]
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = label

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Position = UDim2.fromScale(0, 0.7)
	priceLabel.Size = UDim2.fromScale(1, 0.3)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = BrainrotData.formatMoney(incomePerSecond) .. "/s  ·  " .. BrainrotData.formatMoney(brainrot.cost)
	priceLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = label

	label.Parent = head
	return label
end

--- Assemble one brainrot model from parts: body, head, legs, eyes, accessory,
-- label and Buy prompt. The model's origin is at its feet, so PivotTo puts it
-- on the belt or on a slot pad.
local function buildBrainrotModel(brainrot, mutation): Model
	local incomePerSecond = brainrot.incomePerSecond * mutation.multiplier
	local model = Instance.new("Model")
	model.Name = brainrot.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 2, 1)
	body.Position = Vector3.new(0, 2, 0)
	body.Color = brainrot.bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.8, 1.4, 1.4)
	head.Position = Vector3.new(0, 3.6, 0)
	head.Color = brainrot.headColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	for _, side in ipairs({ -0.5, 0.5 }) do
		local leg = Instance.new("Part")
		leg.Name = "Leg"
		leg.Size = Vector3.new(0.7, 1, 0.7)
		leg.Position = Vector3.new(side, 0.5, 0)
		leg.Color = Color3.fromRGB(60, 60, 70)
		leg.Material = Enum.Material.SmoothPlastic
		leg.Anchored = true
		leg.CanCollide = false
		leg.Parent = model
	end

	for _, side in ipairs({ -0.4, 0.4 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.3, 0.3, 0.1)
		eye.Position = Vector3.new(side, 3.7, 0.75)
		eye.Color = Color3.fromRGB(20, 20, 25)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
	end

	local accessory = buildAccessory(brainrot.accessory, brainrot.headColor)
	if accessory then
		accessory.Parent = model
	end

	buildLabel(head, brainrot, mutation, incomePerSecond)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = brainrot.name .. "  ·  " .. BrainrotData.formatMoney(brainrot.cost)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model

	model.PrimaryPart = body
	model:SetAttribute("BrainrotId", brainrot.id)
	model:SetAttribute("Mutation", mutation.name)
	return model
end

--- Sell the brainrot a player just bought: charge them, lift it off the belt
-- and hand it to BaseService to place on their base.
local function onBuyPrompt(player: Player, model: Model)
	if not beltModels[model] then
		return
	end
	local brainrotId = model:GetAttribute("BrainrotId")
	local brainrot = BrainrotData.getBrainrotById(brainrotId)
	if not brainrot then
		return
	end
	local state = PlayerState.get(player)
	if state.money < brainrot.cost then
		notifyPlayer(player, "You need " .. BrainrotData.formatMoney(brainrot.cost) .. " for " .. brainrot.name .. ".")
		return
	end
	if not PlayerState.getPlayerBaseModel(player) then
		notifyPlayer(player, "All bases are taken right now.")
		return
	end
	beltModels[model] = nil
	if not PlayerState.spendMoney(player, brainrot.cost) then
		beltModels[model] = true
		notifyPlayer(player, "You need " .. BrainrotData.formatMoney(brainrot.cost) .. " for " .. brainrot.name .. ".")
		return
	end
	local mutation = { name = model:GetAttribute("Mutation"), multiplier = 1 }
	for _, candidate in ipairs(BrainrotData.MUTATIONS) do
		if candidate.name == mutation.name then
			mutation = candidate
			break
		end
	end
	local _, reason = BaseService.placeBrainrot(player, model, brainrotId, mutation)
	if reason then
		PlayerState.addMoney(player, brainrot.cost)
		beltModels[model] = true
		notifyPlayer(player, reason)
		return
	end
	notifyPlayer(player, "You bought " .. brainrot.name .. " for " .. BrainrotData.formatMoney(brainrot.cost) .. "!")
end

--- Roll a rarity, pick a brainrot of it, roll its mutation and walk it in.
local function spawnBrainrotOnBelt()
	local rarity = BrainrotData.rollRarity()
	local brainrot = BrainrotData.randomBrainrotOfRarity(rarity)
	local mutation = BrainrotData.rollMutation()
	local model = buildBrainrotModel(brainrot, mutation)
	model:PivotTo(CFrame.new(BrainrotData.BELT_START_X, 1, 0))
	model.Parent = workspace
	beltModels[model] = true
	local prompt = model:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			onBuyPrompt(player, model)
		end)
	end
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			beltModels[model] = nil
		end
	end)
end

--- Walk every brainrot on the belt east, and despawn it at the end.
local function startBeltLoop()
	RunService.Heartbeat:Connect(function(deltaTime)
		local step = BrainrotData.BELT_SPEED_STUDS_PER_SECOND * deltaTime
		for model in pairs(beltModels) do
			if model.Parent then
				local pivot = model:GetPivot()
				if pivot.X >= BrainrotData.BELT_END_X then
					beltModels[model] = nil
					model:Destroy()
				else
					model:PivotTo(pivot + Vector3.new(step, 0, 0))
				end
			else
				beltModels[model] = nil
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(BrainrotData.BELT_SPAWN_SECONDS)
			local count = 0
			for _ in pairs(beltModels) do
				count += 1
			end
			if count < BrainrotData.BELT_MAX_ON_BELT then
				spawnBrainrotOnBelt()
			end
		end
	end)
end

--- Start the belt. notify is the RemoteEvent the server uses for player messages.
function BeltService.init(notify: RemoteEvent)
	notifyRemote = notify
	startBeltLoop()
end

return BeltService
