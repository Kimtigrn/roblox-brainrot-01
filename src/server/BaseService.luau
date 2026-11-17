-- Brainrot Base Battles: everything that happens on a player's base.
-- BaseService owns the placed brainrots (one record per model), the six slots
-- of each base, the lock gate, stealing, upgrades and rebirths. Money itself
-- lives in PlayerState; this module only decides what a base may do.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local BaseService = {}

-- Which way a placed brainrot faces: the south bases face the conveyor to
-- their north (yaw 180), the north bases face it to their south (yaw 0).
local BASE_FACING_YAW = { Base1 = 180, Base2 = 180, Base3 = 0, Base4 = 0 }
local GATE_OPEN_Y = 9
local GATE_CLOSED_Y = 3

-- uid -> { model, owner, brainrotId, mutation, level, slotName, baseName, stealProtectedUntil }
local placedByUid = {}
-- baseName -> slotName -> uid (or nil when the slot is free)
local slotOccupants = {}
local uidCounter = 0
local notifyRemote = nil

local function notifyPlayer(player: Player, message: string)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

local function nextUid(): string
	uidCounter += 1
	return "br-" .. tostring(uidCounter)
end

--- The income one placed brainrot earns each second, with every multiplier.
function BaseService.brainrotIncome(record, player: Player): number
	local brainrot = BrainrotData.getBrainrotById(record.brainrotId)
	if not brainrot then
		return 0
	end
	local income = brainrot.incomePerSecond * record.mutation.multiplier
	income *= math.pow(BrainrotData.UPGRADE_INCOME_MULTIPLIER, record.level - 1)
	income *= PlayerState.rebirthMultiplier(player)
	return math.floor(income + 0.5)
end

--- Every brainrot a player has placed, as records.
function BaseService.getPlacedBrainrots(player: Player)
	local placed = {}
	for _, record in pairs(placedByUid) do
		if record.owner == player then
			table.insert(placed, record)
		end
	end
	return placed
end

--- The whole income of a player per second, across their placed brainrots.
function BaseService.computeIncomePerSecond(player: Player): number
	local total = 0
	for _, record in ipairs(BaseService.getPlacedBrainrots(player)) do
		total += BaseService.brainrotIncome(record, player)
	end
	return total
end

--- The first free slot pad of a base model, or nil when it is full.
local function findFreeSlot(baseModel: Model): (BasePart?, string?)
	for slotIndex = 1, BrainrotData.BASE_SLOTS do
		local slotName = "Slot" .. tostring(slotIndex)
		local slot = baseModel:FindFirstChild(slotName)
		if slot and slot:IsA("BasePart") then
			local occupants = slotOccupants[baseModel.Name]
			if not occupants or not occupants[slotName] then
				return slot, slotName
			end
		end
	end
	return nil, nil
end

--- Move a brainrot from the belt onto the first free slot of a player's base.
-- Returns the new record, or nil with a reason when it cannot be placed.
function BaseService.placeBrainrot(player: Player, model: Model, brainrotId: string, mutation)
	local baseModel = PlayerState.getPlayerBaseModel(player)
	if not baseModel then
		return nil, "You have no base yet."
	end
	local slot, slotName = findFreeSlot(baseModel)
	if not slot then
		return nil, "Your base is full! Rebirth to clear it."
	end
	local uid = nextUid()
	local record = {
		model = model,
		owner = player,
		brainrotId = brainrotId,
		mutation = mutation,
		level = 1,
		slotName = slotName,
		baseName = baseModel.Name,
		stealProtectedUntil = os.time() + BrainrotData.STEAL_PROTECTION_SECONDS,
	}
	placedByUid[uid] = record
	slotOccupants[baseModel.Name] = slotOccupants[baseModel.Name] or {}
	slotOccupants[baseModel.Name][slotName] = uid
	model:SetAttribute("Uid", uid)
	model:SetAttribute("Owner", player.Name)
	local yaw = BASE_FACING_YAW[baseModel.Name] or 0
	model:PivotTo(CFrame.new(slot.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(yaw), 0))
	local prompt = model:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "Steal"
		prompt.ObjectText = BrainrotData.getBrainrotById(brainrotId).name .. " (" .. player.Name .. "'s)"
		prompt.HoldDuration = 0
		-- The prompt keeps working after the buy: answering it now steals the
		-- brainrot off this base (the belt's buy handler ignores placed models).
		prompt.Triggered:Connect(function(otherPlayer: Player)
			BaseService.onStealPrompt(otherPlayer, model)
		end)
	end
	return record, nil
end

--- Answer a Steal prompt on a placed brainrot. Silent when the model is
-- still on the belt: the belt's buy handler owns that prompt until it is bought.
function BaseService.onStealPrompt(player: Player, model: Model)
	local record = BaseService.getRecordByModel(model)
	if not record then
		return
	end
	local victim = record.owner
	local ok, message = BaseService.stealBrainrot(player, model)
	notifyPlayer(player, message)
	if ok and victim and victim ~= player then
		notifyPlayer(victim, player.Name .. " stole your " .. BrainrotData.getBrainrotById(record.brainrotId).name .. "! Lock your base!")
	end
end

--- Free a brainrot's slot and forget its record (the caller destroys the model).
function BaseService.removePlacedBrainrot(uid: string)
	local record = placedByUid[uid]
	if not record then
		return
	end
	local occupants = slotOccupants[record.baseName]
	if occupants then
		occupants[record.slotName] = nil
	end
	placedByUid[uid] = nil
end

--- The record of a brainrot model, or nil when it is not placed anywhere.
function BaseService.getRecordByModel(model: Model)
	local uid = model:GetAttribute("Uid")
	if typeof(uid) ~= "string" then
		return nil, nil
	end
	return placedByUid[uid], uid
end

--- Slide a base's gate down (locked) or up (open).
local function setGate(baseName: string, closed: boolean)
	local bases = workspace:FindFirstChild("Bases")
	if not bases then
		return
	end
	local baseModel = bases:FindFirstChild(baseName)
	if not baseModel then
		return
	end
	local gate = baseModel:FindFirstChild("Gate")
	if gate and gate:IsA("BasePart") then
		local pos = gate.Position
		gate.Position = Vector3.new(pos.X, closed and GATE_CLOSED_Y or GATE_OPEN_Y, pos.Z)
	end
end

--- Lock the player's own base for 60 seconds. Returns false with a reason
-- when the lock is on cooldown or the player has no base.
function BaseService.lockBase(player: Player): (boolean, string)
	local state = PlayerState.get(player)
	if not state.baseName then
		return false, "You have no base to lock."
	end
	if PlayerState.isBaseLocked(player) then
		return false, "Your base is already locked."
	end
	local cooldown = PlayerState.lockCooldownLeft(player)
	if cooldown > 0 then
		return false, "Lock recharges in " .. tostring(cooldown) .. "s."
	end
	local now = os.time()
	state.lockUntil = now + BrainrotData.LOCK_SECONDS
	state.lockCooldownUntil = now + BrainrotData.LOCK_SECONDS + BrainrotData.LOCK_COOLDOWN_SECONDS
	setGate(state.baseName, true)
	task.delay(BrainrotData.LOCK_SECONDS, function()
		setGate(state.baseName, false)
	end)
	return true, "Base locked for 60 seconds!"
end

--- Steal a brainrot off another player's base onto your own. Fails when the
-- victim's base is locked, the brainrot is steal-protected, or your base is full.
function BaseService.stealBrainrot(player: Player, model: Model): (boolean, string)
	local record, uid = BaseService.getRecordByModel(model)
	if not record then
		return false, "That brainrot is not on a base."
	end
	if record.owner == player then
		return false, "That brainrot is already yours."
	end
	if os.time() < record.stealProtectedUntil then
		return false, "That brainrot is steal-protected right now."
	end
	if PlayerState.isBaseLocked(record.owner) then
		return false, record.owner.Name .. "'s base is locked!"
	end
	local myBase = PlayerState.getPlayerBaseModel(player)
	if not myBase then
		return false, "You have no base to steal into."
	end
	local slot, slotName = findFreeSlot(myBase)
	if not slot then
		return false, "Your base is full! Rebirth to clear it."
	end
	local oldBaseName = record.baseName
	local oldSlotName = record.slotName
	local occupants = slotOccupants[oldBaseName]
	if occupants then
		occupants[oldSlotName] = nil
	end
	slotOccupants[myBase.Name] = slotOccupants[myBase.Name] or {}
	slotOccupants[myBase.Name][slotName] = uid
	record.owner = player
	record.baseName = myBase.Name
	record.slotName = slotName
	record.stealProtectedUntil = os.time() + BrainrotData.STEAL_PROTECTION_SECONDS
	model:SetAttribute("Owner", player.Name)
	local yaw = BASE_FACING_YAW[myBase.Name] or 0
	model:PivotTo(CFrame.new(slot.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(yaw), 0))
	local prompt = model:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ObjectText = BrainrotData.getBrainrotById(record.brainrotId).name .. " (" .. player.Name .. "'s)"
	end
	return true, "You stole " .. BrainrotData.getBrainrotById(record.brainrotId).name .. "!"
end

--- Upgrade one of the player's placed brainrots one level (max 3).
function BaseService.upgradeBrainrot(player: Player, uid: string): (boolean, string)
	local record = placedByUid[uid]
	if not record or record.owner ~= player then
		return false, "That is not your brainrot."
	end
	if record.level >= BrainrotData.UPGRADE_MAX_LEVEL then
		return false, "Already at max level."
	end
	local brainrot = BrainrotData.getBrainrotById(record.brainrotId)
	local cost = BrainrotData.upgradeCost(brainrot, record.level)
	if not PlayerState.spendMoney(player, cost) then
		return false, "You need " .. BrainrotData.formatMoney(cost) .. " to upgrade."
	end
	record.level += 1
	local prompt = record.model:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ObjectText = brainrot.name .. " Lv" .. tostring(record.level) .. " (" .. player.Name .. "'s)"
	end
	return true, brainrot.name .. " is now level " .. tostring(record.level) .. "!"
end

--- Rebirth: clear the player's brainrots and money for a permanent +25%
-- income per rebirth. Needs 4 placed brainrots and $10,000 on hand.
function BaseService.rebirthPlayer(player: Player): (boolean, string)
	local placed = BaseService.getPlacedBrainrots(player)
	local state = PlayerState.get(player)
	if #placed < BrainrotData.REBIRTH_MIN_BRAINROTS then
		return false, "Rebirth needs " .. tostring(BrainrotData.REBIRTH_MIN_BRAINROTS) .. " brainrots on your base."
	end
	if state.money < BrainrotData.REBIRTH_MIN_MONEY then
		return false, "Rebirth needs " .. BrainrotData.formatMoney(BrainrotData.REBIRTH_MIN_MONEY) .. "."
	end
	for _, record in ipairs(placed) do
		local _, uid = BaseService.getRecordByModel(record.model)
		if uid then
			BaseService.removePlacedBrainrot(uid)
		end
		record.model:Destroy()
	end
	PlayerState.addMoney(player, -state.money)
	state.rebirths += 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = state.rebirths
		end
	end
	return true, "Rebirth " .. tostring(state.rebirths) .. "! All income is now +" .. tostring(state.rebirths * 25) .. "% forever."
end

--- The snapshot the HUD renders, sent to the client every second.
function BaseService.getPlayerStateForHud(player: Player)
	local state = PlayerState.get(player)
	local brainrots = {}
	local ownedIds = {}
	for _, record in ipairs(BaseService.getPlacedBrainrots(player)) do
		local brainrot = BrainrotData.getBrainrotById(record.brainrotId)
		local upgradeCost = nil
		if record.level < BrainrotData.UPGRADE_MAX_LEVEL then
			upgradeCost = BrainrotData.upgradeCost(brainrot, record.level)
		end
		table.insert(brainrots, {
			uid = record.model:GetAttribute("Uid"),
			name = brainrot.name,
			rarity = brainrot.rarity,
			income = BaseService.brainrotIncome(record, player),
			level = record.level,
			mutation = record.mutation.name,
			upgradeCost = upgradeCost,
		})
		ownedIds[record.brainrotId] = true
	end
	local nextTier = BrainrotData.nextTierFor(ownedIds)
	return {
		money = state.money,
		incomePerSecond = BaseService.computeIncomePerSecond(player),
		rebirths = state.rebirths,
		hasBase = state.baseName ~= nil,
		lockSecondsLeft = PlayerState.lockSecondsLeft(player),
		lockCooldownLeft = PlayerState.lockCooldownLeft(player),
		brainrots = brainrots,
		nextTier = nextTier and { name = nextTier.name, cost = nextTier.cost } or nil,
	}
end

--- Ready the slot tables for every base in the world. notify is the
-- RemoteEvent the server uses for player messages (steal alerts included).
function BaseService.init(notify: RemoteEvent)
	notifyRemote = notify
	local bases = workspace:WaitForChild("Bases")
	for _, baseModel in ipairs(bases:GetChildren()) do
		if baseModel:IsA("Model") then
			slotOccupants[baseModel.Name] = {}
		end
	end
end

return BaseService
