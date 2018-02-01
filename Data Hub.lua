

--[[
	Data Hub
	
	- Responsible for collecting requests for data changes
	
	DATA MANAGER COMMANDS:
		Manipulate(UserId, Field, NewData)
		GetStat(UserId, Field)
	
	- Client Data requests cannot exceed the following limitations:
		- Any requests must be checked over twice by various systems
		- No requests that are made on the server (Admin/Bans/Etc/Coins)
	
--]]

local DM = require(script.Data_Manager)
local rs = game:GetService('ReplicatedStorage')

function ValidateRequest(field, data, sender)
	local MAXBanLength 			= 		744 		-- 31 days max (24*60)
	local MAXStringLength 		= 		120 		-- 120 characters is plenty
	local MAXKillLength 		= 		500000 		-- 500K is a lot of kills
	local MAXWipeoutLength 		= 		500000 		-- 500K is a lot of deaths
	local MAXCoinLength 		= 		1000000 	-- 1M max coins
	local MAXTokenLength 		= 		1000000 	-- 1M max tokens
	local TotalAchievementCount = 		20 			-- Need to find total achievement count
	local MAXQuestCount 		= 		100 		-- Need to find total quest count
	
	if (field == "UserIsAdmin") and (sender == "Server") then
		return true
	elseif (field == "UserIsBanned") and (data <= MAXBanLength) and (sender == "Server") then
		return true
	elseif (field == "Bans") and (string.len(data) <= MAXStringLength) and (sender == "Server") then
		return true
	elseif (field == "Codes") and (sender == "Server") then
		return true
	elseif (field == "Kills") and (data <= MAXKillLength) and ((sender == "Client") or (sender == "Server")) then
		return true
	elseif (field == "Wipeouts") and (data <= MAXWipeoutLength) and ((sender == "Client") or (sender == "Server")) then
		return true
	elseif (field == "Coins") and (data <= MAXCoinLength) and (data >= 0) and (sender == "Server") then
		return true
	elseif (field == "Tokens") and (data <= MAXTokenLength) and (data >= 0) and (sender == "Server") then
		return true
	elseif (field == "AchievementCount") and (data <= TotalAchievementCount) and ((sender == "Client") or (sender == "Server")) then
		return true
	elseif (field == "QuestCount") and (data < MAXQuestCount) and ((sender == "Client") or (sender == "Server")) then
		return true
	elseif (field == "JoinDate") and ((sender == "Client") or (sender == "Server")) then
		return true
	else
		return false
	end
end


-- Loads data to various values on player join
game.Players.PlayerAdded:connect(function(User)
	local ID = User.UserId
	
end)


-- Client requested data changes (Double validate), Send success reply
rs.ClientDataChangeRequest.OnServerInvoke = function(user, field, data)
	local ID = user.UserId
	if data == true then
		return DM:GetStat(ID, field)
	elseif ValidateRequest(field, data, "Client") then
		DM:Manipulate(ID, field, data)
	end
end

-- Server requested data changes (Validate), Send success reply
script.ServerDataChangeRequest.OnInvoke = function(username, field, data)
	local ID = game:GetService("Players")[username].UserId
	if data == true then
		return DM:GetStat(ID, field)
	elseif ValidateRequest(field, data, "Server") then
		DM:Manipulate(ID, field, data)
	end
end







