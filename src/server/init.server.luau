-- Brainrot Base Battles: the server entrypoint.
-- One job: build the remote events, start every service, and answer the three
-- buttons the HUD sends (lock, rebirth, upgrade). Buying and stealing run
-- through the prompts on the brainrots themselves, on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local BeltService = require(script.Parent:WaitForChild("BeltService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

--- One RemoteEvent of this name, made fresh each server start.
local function makeRemote(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local notifyRemote = makeRemote(remotes, "Notify")
local stateUpdateRemote = makeRemote(remotes, "StateUpdate")
local lockBaseRemote = makeRemote(remotes, "LockBase")
local rebirthRemote = makeRemote(remotes, "Rebirth")
local upgradeRemote = makeRemote(remotes, "UpgradeBrainrot")

PlayerState.start()
BaseService.init(notifyRemote)
BeltService.init(notifyRemote)
EconomyService.init(stateUpdateRemote)

lockBaseRemote.OnServerEvent:Connect(function(player: Player)
	local ok, message = BaseService.lockBase(player)
	notifyRemote:FireClient(player, message)
end)

rebirthRemote.OnServerEvent:Connect(function(player: Player)
	local ok, message = BaseService.rebirthPlayer(player)
	notifyRemote:FireClient(player, message)
end)

upgradeRemote.OnServerEvent:Connect(function(player: Player, uid: string)
	if typeof(uid) ~= "string" then
		return
	end
	local ok, message = BaseService.upgradeBrainrot(player, uid)
	notifyRemote:FireClient(player, message)
end)

print("Brainrot Base Battles server started: belt, bases, economy and remotes are live.")
