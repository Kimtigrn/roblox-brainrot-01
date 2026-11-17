-- Brainrot Base Battles: the client entrypoint.
-- One job: find the server's remotes, build the HUD, and pass messages both
-- ways. The server owns every rule; this script only shows what it says and
-- forwards what the player presses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local stateUpdateRemote = remotes:WaitForChild("StateUpdate")
local lockBaseRemote = remotes:WaitForChild("LockBase")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local upgradeRemote = remotes:WaitForChild("UpgradeBrainrot")

local callbacks = {
	onLock = function()
		lockBaseRemote:FireServer()
	end,
	onRebirth = function()
		rebirthRemote:FireServer()
	end,
	onUpgrade = function(uid: string)
		upgradeRemote:FireServer(uid)
	end,
}

Hud.build(callbacks)

stateUpdateRemote.OnClientEvent:Connect(function(state)
	Hud.update(state, callbacks)
end)

notifyRemote.OnClientEvent:Connect(function(message: string)
	Hud.notify(message)
end)

print("Brainrot Base Battles client started: HUD is live.")
