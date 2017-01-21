PlayerManager = {}

function PlayerManager:startGame(numPlayers)
	numPlayers = numPlayers or 4

	if numPlayers > 4 then 
		numPlayers = 4
	elseif numPlayers < 2 then
		numPlayers = 2
	end
	print("Debugging! PlayerManager:startGame numPlayers hardcoded to 1!")
	numPlayers = 1
	self.map = Map:new()
	self.players = {}
	for i = 1, numPlayers do
		local spawnX, spawnY = self.map:getSpawnPoint(i)
		self.players[i] = Player:new(spawnX, spawnY, self.map, index)
	end

	self:rollDie()

	self:nextPlayer()
end

function PlayerManager:nextPlayer()
	if self.order[1] then
		self.currentPlayer = self.order[1]
	else
		self:rollDie()
		self.currentPlayer = self.order[1]
	end
end

function PlayerManager:rollDie()
	print("TODO PlayerManager:rollDie and set PlayerManager.order")
	self.order = self.players
end

Player = {}
Player_mt = {__index = Player}

function Player:new(q, r, map, index)
	local newPlayer = {}
	newPlayer.characters = {}
	newPlayer.numCharacters = 4
	newPlayer.index = index
	for i = 1, newPlayer.numCharacters do
		table.insert(newPlayer.characters, Character:new(q, r, map))
	end

	newPlayer.currentCharacter = newPlayer.characters[1]

	return newPlayer
end

function Player:getAvailableCharacters()
	local results = {}
	for k, character in ipairs(self.characters) do
		if character.currentActions > 0 then
			table.insert(results, character)
		end
	end
	if #results >= 1 then
		return results
	else
		PlayerManager:nextPlayer()
		return self:getAvailableCharacters()
	end
end


Character = {}
Character_mt = {__index = Character}

function Character:new(q, r, map)
	print("New character at " .. tostring(q) .. " - " .. tostring(r))
	local newCharacter = {}
	setmetatable(newCharacter, Character_mt)
	newCharacter.q = q
	newCharacter.r = r
	newCharacter.map = map
	newCharacter.actionsPerRound = 1
	newCharacter.currentActions = 1
	newCharacter.portrait = {}
	newCharacter.actions = {
		CharacterAction:new("Build Bridge", newCharacter, newCharacter.buildBridge, newCharacter.checkBuildBridge),
		CharacterAction:new("Build wave breaker", newCharacter, newCharacter.buildBreaker, newCharacter.checkBuildBreaker),
		CharacterAction:new("Walk", newCharacter, newCharacter.walk, newCharacter.checkWalk)
	}

	return newCharacter
end

function Character:getPossibleActions()
	local results = {}
	for k, action in pairs(self.actions) do
		if action.callbackTable.check(callbackTable) then
			table.insert(results, action)
		end
	end

	if #results >= 1 then
		return results
	end
end

function Character:getSurroundingTiles()
	local results = {}
	for i = -1, 1 do
		for j = -1, 1 do
			local tile = self.map:getTile(self.q + i, self.r + j)
			if tile then
				table.insert(results, tile)
			end
		end
	end
	return results
end

function Character:checkBuildBridge()
	local tiles = self:getSurroundingTiles()
	for k, tile in ipairs(tiles) do
		if tile.type == "Bridge" or tile.type == "Sandbank" then
			if not tile.bridgeActive then
				return true
			end
		end
	end
	return false
end

function Character:buildBridge(x, y)
	self.currentActions = self.currentActions - 1

end

function Character:checkBuildBreaker()
	local tile = self.map:getTile(self.q, self.r)
	if tile.breakerDirections then
		return true
	end
	return false
end

function Character:buildBreaker()
	self.currentActions = self.currentActions - 1
end

function Character:checkWalk()

end

function Character:walk()
	self.currentActions = self.currentActions - 1
end

CharacterAction = {}
CharacterAction_mt = {__index = CharacterAction}

function CharacterAction:new(name, callbackTable, actionFunction, checkFunction)
	if not actionFunction or not checkFunction then
		print("New character action without both function callback!")
		return nil
	end
	if not callbackTable then
		print("New character action without callback table!")
		return nil
	end
	local newAction = {}
	setmetatable(newAction, CharacterAction_mt)
	newAction.name = name or "Error, no action name defined"
	newAction.callbackTable = callbackTable
	newAction.func = actionFunction
	newAction.check = checkFunction

	return newAction
end
