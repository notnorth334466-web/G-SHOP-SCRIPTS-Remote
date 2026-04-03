local MainModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local ALLOWED_OWNERS = {
	["Username1"] = true,
	["Username2"] = true,
	["Username3"] = true,
	["Username4"] = true,
	["Username5"] = true,
	
}

local SHIELD_CONFIG = {
	MAX_REQUESTS = 15,
	TIME_WINDOW = 1,
	BAN_THRESHOLD = 5,
}

local PlayerStats = {}


local function createWarningUI(player)
	local sg = Instance.new("ScreenGui")
	sg.Name = "GShop_Warning"
	sg.IgnoreGuiInset = true
	sg.Parent = player:WaitForChild("PlayerGui")
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Parent = sg
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0.2, 0)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "⚠️ [G-SHOP SHIELD ALERT]\nของเถื่อนนะเนี่ย\nไปติดต่อเจ้าของสคริปต์ (G-Shop) | TikTok: grass_north"
	label.Parent = frame
end

local function processSecurity(player)
	local now = os.clock()
	local uid = player.UserId
	if not PlayerStats[uid] then PlayerStats[uid] = {count = 0, lastReset = now, violations = 0} end
	local data = PlayerStats[uid]
	
	if now - data.lastReset >= SHIELD_CONFIG.TIME_WINDOW then
		data.count = 0
		data.lastReset = now
	end
	
	data.count += 1
	if data.count > SHIELD_CONFIG.MAX_REQUESTS then
		data.violations += 1
		warn("⚠️ [G-SHOP] " .. player.Name .. " กำลังสแปม")
		if data.violations >= SHIELD_CONFIG.BAN_THRESHOLD then
			player:Kick("\n[G-SHOP] Remote Abuse Detected")
		end
		return false
	end
	return true
end

local function secureObject(obj)
	if obj:IsA("RemoteEvent") then
		obj.OnServerEvent:Connect(function(player)
			processSecurity(player)
		end)
	elseif obj:IsA("RemoteFunction") then
		obj.OnServerInvoke = function(player, ...)
			if not processSecurity(player) then return nil end
			
		end
	end
end

function MainModule.Start()
	print("[G-SHOP] Verifying owner identity...")
	

	local creatorName = ""
	local success, err = pcall(function()
		if game.CreatorType == Enum.CreatorType.User then
			creatorName = Players:GetNameFromUserIdAsync(game.CreatorId)
		else
			
			local groupService = game:GetService("GroupService")
			local groupInfo = groupService:GetGroupInfoAsync(game.CreatorId)
			creatorName = groupInfo.Owner.Name
		end
	end)

	if success and ALLOWED_OWNERS[creatorName] then
		print("✅ [G-SHOP] Verified Owner: " .. creatorName)
		
		
		for _, child in pairs(ReplicatedStorage:GetDescendants()) do
			secureObject(child)
		end
		ReplicatedStorage.DescendantAdded:Connect(secureObject)

		Players.PlayerRemoving:Connect(function(player)
			PlayerStats[player.UserId] = nil
		end)

		return true
	end


	warn("❌ [G-SHOP] Unauthorized Owner Detected!")
	Players.PlayerAdded:Connect(createWarningUI)
	for _, p in pairs(Players:GetPlayers()) do 
		pcall(function() createWarningUI(p) end) 
	end
end

return MainModule
