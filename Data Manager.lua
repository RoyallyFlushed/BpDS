
--[[
	Data Manager, server
	
	- Deals with traffic from the datastore to the server's current data
	- Data stream saving/loading user data to server current data
	- Store for default data. Please be aware of the importance to change datastore key on addition/removal of stats
	
	
	15/jul/17
	- TeaAndCopy
--]]

-- Datastore KEY
local KEY = 'CommonTest_1'

-- Module Data
local script = nil
local Data_Manager = {}

-- Datastore Data
local DataStoreService = game:GetService('DataStoreService')
local User_Data = DataStoreService:GetDataStore('CommonTest_1')


-- Directory Variables
local Player_Service = game:GetService('Players')
local HttpService = game:GetService('HttpService')


-- Misc Variables
local AUTOSAVE_INTERVAL = 60
local DATASTORE_RETRIES = 3



-- Current session data
local ServerData = {}


-- The Table below is where you add all stats a player should have
local Default_Data = {
	['UserIsAdmin'] = false;
	['UserIsBanned'] = 0;
	['Bans'] = {};
	['Codes'] = {};
	['Kills'] = 0;
	['Wipeouts'] = 0;
	['Coins'] = 0;
	['Tokens'] = 0;
	['AchievementCount'] = 0;
	['QuestCount'] = 0;
	['JoinDate'] = 0;
	}

-- Simple time saving functions for decoding
local function DecodeJSON(JSON)
	return HttpService:JSONDecode(JSON)
end

-- Simple time saving functions for encoding
local function EncodeJSON(Table)
	return HttpService:JSONEncode(Table)
end

-- Sends data to data stream on request
function Data_Manager:GetSettings()
	local Encoded_DefaultData = HttpService:JSONEncode(Default_Data)
	
	return Encoded_DefaultData
end

-- Edits the specified Data field of the specified user with the new data (AFTER MATH)
function Data_Manager:Manipulate(UserId, Field, NewData)
	wait(1)
	-- Local Variables for the user's data folder, the Json data and the Table of the Json data
	local User_Folder = ServerData[UserId]
	local Table = DecodeJSON(User_Folder)
	
	-- Changes the specified data, encodes the table back into Json and stores it again
	Table[Field] = NewData
	local JSON = EncodeJSON(Table)
	ServerData[UserId] = JSON
end


-- Returns the specified statistic from User Data
function Data_Manager:GetStat(UserId, Field)
	wait(1)
	local User_Folder = ServerData[UserId]
	local Table = DecodeJSON(User_Folder)
	
	return Table[Field]
end

----------------------------------------------------------------------------------------------------------

local function Recall(args)
	local attempts = 0
	local success = true
	local data = nil
	repeat
		attempts = attempts + 1
		success = pcall(function() data = args() end)
		if not success then wait(1) end
	until (attempts == DATASTORE_RETRIES) or success
	if not success then
		error('Error accessing Datastore, please warn users')
	end
	return success, data
end

local function GetData(ID)
	return Recall(function()
		return User_Data:GetAsync(ID)
	end)
end

local function SaveData(ID)
	if ServerData[ID] then
		return Recall(function()
			return User_Data:SetAsync(ID, ServerData[ID])
		end)
	end
end

function Setup(User)
	local ID = User.UserId
	local success, Data = GetData(ID)
	if not success then
		ServerData[ID] = false
	else
		if Data == nil then
			ServerData[ID] = Data_Manager:GetSettings()
			SaveData(ID)
		else
			ServerData[ID] = Data
		end
	end
end


local function Autosave()
	while wait(AUTOSAVE_INTERVAL) do
		for user, data in pairs(ServerData) do
			SaveData(user)
		end
	end
end


Player_Service.PlayerAdded:connect(Setup)

Player_Service.PlayerRemoving:connect(function(User)
	local ID = Player_Service:GetUserIdFromNameAsync(User.Name)
	
	SaveData(ID)
	ServerData[ID] = nil
end)


spawn(Autosave)

return Data_Manager





