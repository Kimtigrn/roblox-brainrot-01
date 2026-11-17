-- Brainrot Base Battles: the money tap.
-- EconomyService ticks once a second: every placed brainrot pays its owner,
-- and every player gets a fresh HUD snapshot (money, income, lock timers,
-- their brainrots, the next tier). The money itself lives in PlayerState.

local Players = game:GetService("Players")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local EconomyService = {}

local stateUpdateRemote = nil

--- Pay one player one second of income and refresh their HUD snapshot.
local function tickPlayer(player: Player)
	local income = BaseService.computeIncomePerSecond(player)
	if income > 0 then
		PlayerState.addMoney(player, income)
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local incomeValue = leaderstats:FindFirstChild("IncomePerSecond")
		if incomeValue then
			incomeValue.Value = income
		end
	end
	if stateUpdateRemote then
		stateUpdateRemote:FireClient(player, BaseService.getPlayerStateForHud(player))
	end
end

--- Start the one-second income tick for everyone in the game.
function EconomyService.init(stateUpdate: RemoteEvent)
	stateUpdateRemote = stateUpdate
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(tickPlayer, player)
				if not ok then
					warn("Brainrot income tick failed for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end)
end

return EconomyService
