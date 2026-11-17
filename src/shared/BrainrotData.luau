-- Brainrot Base Battles: the cast, the rarity ladder and every economy number.
-- One module, one job: the server and the client both require this, so prices,
-- incomes and rarities always agree on both sides of the game.

local BrainrotData = {}

BrainrotData.GAME_NAME = "Brainrot Base Battles"

-- The rarity ladder, weakest first. A brainrot's rarity decides its spawn
-- weight on the belt and the colour of its name label.
BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

BrainrotData.RARITY_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Rare"] = Color3.fromRGB(80, 160, 255),
	["Epic"] = Color3.fromRGB(190, 90, 255),
	["Legendary"] = Color3.fromRGB(255, 170, 40),
	["Mythic"] = Color3.fromRGB(255, 80, 200),
	["Brainrot God"] = Color3.fromRGB(255, 215, 0),
}

-- How often each rarity walks down the belt (weights sum to 1).
BrainrotData.RARITY_WEIGHTS = {
	["Common"] = 0.45,
	["Rare"] = 0.25,
	["Epic"] = 0.15,
	["Legendary"] = 0.09,
	["Mythic"] = 0.04,
	["Brainrot God"] = 0.02,
}

-- A mutation is rolled when a brainrot spawns: Golden doubles its income,
-- Rainbow pays five times. Most brainrots are Normal.
BrainrotData.MUTATIONS = {
	{ name = "Normal", chance = 0.88, multiplier = 1 },
	{ name = "Golden", chance = 0.10, multiplier = 2 },
	{ name = "Rainbow", chance = 0.02, multiplier = 5 },
}

-- The cast: ten absurd, meme-born characters of our own invention. bodyColor
-- and headColor paint the blocky model the belt builds; accessory picks the
-- little extra part on top (Hat, Antenna, Crown, Sunglasses, Bowtie, Noodle).
BrainrotData.BRAINROTS = {
	{
		id = "wobble-wombat",
		name = "Wobble Wombat",
		rarity = "Common",
		incomePerSecond = 5,
		cost = 50,
		bodyColor = Color3.fromRGB(170, 120, 70),
		headColor = Color3.fromRGB(200, 150, 95),
		accessory = "Hat",
		blurb = "Wobbles everywhere. Earns a little, wobbles a lot.",
	},
	{
		id = "sir-toast",
		name = "Sir Toastalot",
		rarity = "Common",
		incomePerSecond = 8,
		cost = 120,
		bodyColor = Color3.fromRGB(220, 180, 110),
		headColor = Color3.fromRGB(240, 205, 140),
		accessory = "Bowtie",
		blurb = "Knighted for crunch. Never goes stale.",
	},
	{
		id = "captain-noodle",
		name = "Captain Noodle",
		rarity = "Rare",
		incomePerSecond = 15,
		cost = 300,
		bodyColor = Color3.fromRGB(255, 220, 90),
		headColor = Color3.fromRGB(255, 235, 140),
		accessory = "Hat",
		blurb = "Sails the belt in a noodle boat. Salty, but rich.",
	},
	{
		id = "dj-pickle",
		name = "DJ Pickle",
		rarity = "Rare",
		incomePerSecond = 22,
		cost = 500,
		bodyColor = Color3.fromRGB(90, 180, 80),
		headColor = Color3.fromRGB(120, 210, 100),
		accessory = "Sunglasses",
		blurb = "Drops beats and brine. The belt dances for him.",
	},
	{
		id = "prof-banana",
		name = "Professor Banana Peel",
		rarity = "Epic",
		incomePerSecond = 40,
		cost = 1200,
		bodyColor = Color3.fromRGB(255, 225, 60),
		headColor = Color3.fromRGB(255, 240, 120),
		accessory = "Antenna",
		blurb = "Slipped into a PhD. Teaches slipping, earns slipping.",
	},
	{
		id = "almighty-sock",
		name = "The Almighty Sock",
		rarity = "Epic",
		incomePerSecond = 60,
		cost = 2000,
		bodyColor = Color3.fromRGB(235, 235, 245),
		headColor = Color3.fromRGB(180, 200, 255),
		accessory = "Crown",
		blurb = "Ruler of every lost pair. Demands tribute hourly.",
	},
	{
		id = "grandma-spaghetti",
		name = "Grandma's Flying Spaghetti",
		rarity = "Legendary",
		incomePerSecond = 120,
		cost = 5000,
		bodyColor = Color3.fromRGB(240, 200, 150),
		headColor = Color3.fromRGB(255, 120, 90),
		accessory = "Noodle",
		blurb = "It flies. It feeds. It never asks permission.",
	},
	{
		id = "chairman-meow",
		name = "Chairman Meow",
		rarity = "Legendary",
		incomePerSecond = 180,
		cost = 8000,
		bodyColor = Color3.fromRGB(255, 160, 60),
		headColor = Color3.fromRGB(255, 190, 110),
		accessory = "Bowtie",
		blurb = "Chairs every meeting. The meetings pay him.",
	},
	{
		id = "lord-left-sock",
		name = "Lord of the Left Socks",
		rarity = "Mythic",
		incomePerSecond = 350,
		cost = 20000,
		bodyColor = Color3.fromRGB(160, 80, 220),
		headColor = Color3.fromRGB(200, 120, 255),
		accessory = "Crown",
		blurb = "Every left sock you ever lost works for him now.",
	},
	{
		id = "supreme-brainrot",
		name = "The Supreme Brainrot God",
		rarity = "Brainrot God",
		incomePerSecond = 1000,
		cost = 100000,
		bodyColor = Color3.fromRGB(255, 215, 0),
		headColor = Color3.fromRGB(255, 240, 150),
		accessory = "Crown",
		blurb = "The final brainrot. The belt bows to it.",
	},
}

-- Economy and loop tuning.
BrainrotData.BASE_SLOTS = 6
BrainrotData.BELT_SPAWN_SECONDS = 4
BrainrotData.BELT_MAX_ON_BELT = 8
BrainrotData.BELT_SPEED_STUDS_PER_SECOND = 4
BrainrotData.BELT_START_X = -70
BrainrotData.BELT_END_X = 72
BrainrotData.LOCK_SECONDS = 60
BrainrotData.LOCK_COOLDOWN_SECONDS = 120
BrainrotData.REBIRTH_MIN_BRAINROTS = 4
BrainrotData.REBIRTH_MIN_MONEY = 10000
BrainrotData.REBIRTH_BONUS_PER_REBIRTH = 0.25
BrainrotData.UPGRADE_MAX_LEVEL = 3
BrainrotData.UPGRADE_INCOME_MULTIPLIER = 1.5
BrainrotData.STEAL_PROTECTION_SECONDS = 15

--- Find one brainrot of the cast by its id, or nil.
function BrainrotData.getBrainrotById(id: string)
	for _, brainrot in ipairs(BrainrotData.BRAINROTS) do
		if brainrot.id == id then
			return brainrot
		end
	end
	return nil
end

--- Roll a rarity from the belt's spawn weights.
function BrainrotData.rollRarity(): string
	local roll = math.random()
	local running = 0
	for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
		running += BrainrotData.RARITY_WEIGHTS[rarity]
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

--- Roll a mutation (Normal, Golden or Rainbow) from its chances.
function BrainrotData.rollMutation(): { name: string, multiplier: number }
	local roll = math.random()
	local running = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		running += mutation.chance
		if roll <= running then
			return { name = mutation.name, multiplier = mutation.multiplier }
		end
	end
	return { name = "Normal", multiplier = 1 }
end

--- Pick a random brainrot of the given rarity.
function BrainrotData.randomBrainrotOfRarity(rarity: string)
	local pool = {}
	for _, brainrot in ipairs(BrainrotData.BRAINROTS) do
		if brainrot.rarity == rarity then
			table.insert(pool, brainrot)
		end
	end
	if #pool == 0 then
		return BrainrotData.BRAINROTS[1]
	end
	return pool[math.random(1, #pool)]
end

--- The price of upgrading a placed brainrot to the next level.
function BrainrotData.upgradeCost(brainrot, level: number): number
	return brainrot.cost * (level + 1)
end

--- Short money text for labels and the HUD: $850, $1.2K, $3.4M.
function BrainrotData.formatMoney(amount: number): string
	amount = math.floor(amount + 0.5)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return string.format("$%d", amount)
	end
end

--- The cheapest brainrot the player does not own yet, or nil when all are owned.
function BrainrotData.nextTierFor(ownedIds: { [string]: boolean })
	for _, brainrot in ipairs(BrainrotData.BRAINROTS) do
		if not ownedIds[brainrot.id] then
			return brainrot
		end
	end
	return nil
end

return BrainrotData
