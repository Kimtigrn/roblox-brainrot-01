-- Brainrot Base Battles: one player's state, kept in one place.
-- PlayerState owns the per-player table (money, rebirths, base, lock timers)
-- and the leaderstats the HUD reads. Every other server module asks here
-- instead of keeping its own copy, so money can never disagree with itself.

local Players = game:GetService("Players")

local PlayerState = {}

-- Base models in the order they are handed out: Base1 is the red base by the
-- spawn, then green, blue, yellow. Four bases, so four players can own one.
PlayerState.BASE_ORDER = { "Base1", "Base2", "Base3", "Base4" }
PlayerState.BASE_COLORS = {
	Base1 = Color3.fromRGB(230, 64, 64),
	Base2 = Color3.fromRGB(64, 190, 77),
	Base3 = Color3.fromRGB(64, 128, 242),
	Base4 = Color3.fromRGB(242, 204, 51),
}

-- player -> { money, rebirths, baseName, lockUntil, lockCooldownUntil }
local states = {}
-- baseName -> player (who owns it right now)
local baseOwners = {}

--- The state table for a player, creating it on first ask.
function PlayerState.get(player: Player)
	local state = states[player]
	if not state then
		state = {
			money = 0,
			rebirths = 0,
			baseName = nil,
			lockUntil = 0,
			lockCooldownUntil = 0,
		}
		states[player] = state
	end
	return state
end

--- The leaderstats Money value, or nil before the player has one.
function PlayerState.getMoneyValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild("Money")
end

--- Give a joining player their leaderstats and their base, if one is free.
function PlayerState.setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	local income = Instance.new("IntValue")
	income.Name = "IncomePerSecond"
	income.Value = 0
	income.Parent = leaderstats

	local state = PlayerState.get(player)
	for _, baseName in ipairs(PlayerState.BASE_ORDER) do
		if not baseOwners[baseName] then
			baseOwners[baseName] = player
			state.baseName = baseName
			break
		end
	end
end

--- Hand a leaving player's base back so the next joiner can take it.
function PlayerState.removePlayer(player: Player)
	local state = states[player]
	if state and state.baseName then
		if baseOwners[state.baseName] == player then
			baseOwners[state.baseName] = nil
		end
	end
	states[player] = nil
end

--- The base model a player owns, or nil when they own none.
function PlayerState.getPlayerBaseModel(player: Player): Model?
	local state = PlayerState.get(player)
	if not state.baseName then
		return nil
	end
	local bases = workspace:FindFirstChild("Bases")
	if not bases then
		return nil
	end
	return bases:FindFirstChild(state.baseName)
end

--- Who owns a base, or nil when it is free.
function PlayerState.getBaseOwner(baseName: string): Player?
	return baseOwners[baseName]
end

--- The base a model sits on, found from the base model it belongs to.
function PlayerState.getBaseNameOfModel(model: Model): string?
	local parent = model.Parent
	while parent do
		if parent.Name == "Base1" or parent.Name == "Base2" or parent.Name == "Base3" or parent.Name == "Base4" then
			return parent.Name
		end
		parent = parent.Parent
	end
	return nil
end

--- Add money to a player (and keep leaderstats in step).
function PlayerState.addMoney(player: Player, amount: number)
	local state = PlayerState.get(player)
	state.money += amount
	local moneyValue = PlayerState.getMoneyValue(player)
	if moneyValue then
		moneyValue.Value = state.money
	end
end

--- Take money from a player. Returns false when they cannot afford it.
function PlayerState.spendMoney(player: Player, amount: number): boolean
	local state = PlayerState.get(player)
	if state.money < amount then
		return false
	end
	state.money -= amount
	local moneyValue = PlayerState.getMoneyValue(player)
	if moneyValue then
		moneyValue.Value = state.money
	end
	return true
end

--- The income multiplier from rebirths: +25% per rebirth, forever.
function PlayerState.rebirthMultiplier(player: Player): number
	local state = PlayerState.get(player)
	return 1 + state.rebirths * 0.25
end

--- True while the player's base lock is still up.
function PlayerState.isBaseLocked(player: Player): boolean
	local state = PlayerState.get(player)
	return os.time() < state.lockUntil
end

--- Seconds left on the player's base lock, or 0.
function PlayerState.lockSecondsLeft(player: Player): number
	local state = PlayerState.get(player)
	return math.max(0, math.floor(state.lockUntil - os.time()))
end

--- Seconds left before the player may lock again, or 0.
function PlayerState.lockCooldownLeft(player: Player): number
	local state = PlayerState.get(player)
	return math.max(0, math.floor(state.lockCooldownUntil - os.time()))
end

--- Set every joining player up, and clean up when they leave.
function PlayerState.start()
	Players.PlayerAdded:Connect(function(player)
		PlayerState.setupPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlayerState.removePlayer(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerState.setupPlayer(player)
	end
end

return PlayerState
