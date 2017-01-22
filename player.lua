PlayerManager = {}

function PlayerManager:startGame(numPlayers)
	numPlayers = numPlayers or 4

	if numPlayers > 4 then 
		numPlayers = 4
	elseif numPlayers < 2 then
		numPlayers = 2
	end
	print("Debugging! PlayerManager:startGame numPlayers hardcoded to 1!")
	numPlayers = 4
	self.map = Map:new()
	self.players = {}
	for i = 1, numPlayers do
		local spawnX, spawnY = self.map:getSpawnPoint(i)
		local index = i
		self.players[i] = Player:new(spawnX, spawnY, self.map, index)
		print("Player #" .. tostring(i) .. " has index " .. tostring(i) .. " in self.players")
	end

	self.order = self.players

	--NO TOUCHIES
	self:rollDice()

	self.initDone = true

	--self:nextPlayer()
end

function PlayerManager:draw()
	for i=1,4 do
		if self.players[i] then
			self.players[i]:draw()
		end
	end
end


--CHANGED BY YOGURT ### NO TOUCHIES ###
function PlayerManager:nextPlayer()
	if self.currentPlayer then
		if self.currentPlayerID then
			if self.currentPlayerID == 4 then
				self:preWave()
				--self:nextRound()
				return nil
			else
				self.currentPlayerID = self.currentPlayerID + 1
				--self.currentPlayer = self.order[self.currentPlayerID]
				self.currentPlayer = self.players[self.order[self.currentPlayerID]]
			end
		end
	else
		self.currentPlayer = self.players[self.order[1]]
		self.currentPlayerID = 1
	end

	print("Player #" .. tostring(self.currentPlayerID) .. " is playing")
	CurrentPlayerImage:setPlayer(self.currentPlayer)
	self.currentPlayer:startTurn()
end

function PlayerManager:preWave()
	if WaveInfoImage:isWaveComing() then
		CurrentPlayerImage:setPlayer(self.players[self.order[1]])
		UIManager:unlockWaveButton()
	else 
		self:nextRound()
	end
end

function PlayerManager:waveDirIsSet(dir)
	--Implement Wave

	self:nextRound()
end

--ADDED BY YOGURT
function PlayerManager:nextRound()
	self.currentPlayer = nil
	OrderSelector:reset()
	self:rollDice()
end

--CHANGED BY YOGURT ### NO TOUCHIES ###
function PlayerManager:rollDice()
	UIManager.rollDice()
end

--ADDED BY YOGURT ### NO TOUCHIES ###
function PlayerManager:updateInc(order)
	self.order = order
	self:nextPlayer()
end


Player = {}
Player_mt = {__index = Player}

function Player:new(q, r, map, index)
	local newPlayer = {}
	setmetatable(newPlayer, Player_mt)

	newPlayer.portrait = love.graphics.newImage("img/spieler" .. tostring(index) .. "_1.png")

	newPlayer.characters = {}
	newPlayer.numCharacters = 4
	newPlayer.index = index
	for i = 1, newPlayer.numCharacters do
		table.insert(newPlayer.characters, Character:new(q, r, map, index, (200*0.3)/2 + (i-2) * 5, (200*0.3)/2 + (i-2) * 5))
	end

	newPlayer.currentCharacter = newPlayer.characters[1]

	return newPlayer
end

function Player:getAvailableCharacters()
	local results = {}
	--print("CurrPlayer CharAmnt: " .. tostring(table.getn(self.c)))
	for k, character in ipairs(self.characters) do
		if character.currentActions > 0 then
			table.insert(results, character)
		end
	end
	if #results >= 1 then
		return results
	else
		--PlayerManager:nextPlayer()
		return {}
	end
end

function Player:draw()
	for i=1,4 do
		if self.characters[i] then
			self.characters[i]:draw()
		end
	end
end

--ADDED BY YOGURT
function Player:startTurn()
	for i=1,self.numCharacters do
		if self.characters[i] then
			self.characters[i].currentActions = 1
			self.characters[i].selected = false
		end
	end
	UIManager.displayCharacterSelector()
end


Character = {}
Character_mt = {__index = Character}

function Character:new(q, r, map, id, dispX, dispY)
	print("New character at " .. tostring(q) .. " - " .. tostring(r))
	local newCharacter = {}
	setmetatable(newCharacter, Character_mt)

	tileX, tileY = PlayerManager.map:tileToPixel(q, r)
	newCharacter.displayX = tileX - dispX
	newCharacter.displayY = tileY - dispY
	newCharacter.image = love.graphics.newImage("img/spieler" .. tostring(id) .. "_" .. tostring(math.random(4)) .. ".png")

	newCharacter.q = q
	newCharacter.r = r
	newCharacter.map = map
	newCharacter.actionsPerRound = 1
	newCharacter.currentActions = 1
	newCharacter.portrait = {}
	newCharacter.actions = {
		CharacterAction:new("Build Bridge", newCharacter, newCharacter.buildBridge, newCharacter.checkBuildBridge),
		CharacterAction:new("Build wave breaker", newCharacter, newCharacter.buildBreaker, newCharacter.checkBuildBreaker),
		CharacterAction:new("Walk", newCharacter, newCharacter.walk, newCharacter.checkWalk),
		CharacterAction:new("Sleep", newCharacter, newCharacter.sleep, newCharacter.checkSleep)
	}

	return newCharacter
end

function Character:draw()
	x, y = PlayerManager.map:tileToPixel(self.q, self.r)

	x = x + math.random(-5, 5)
	y = y + math.random(-5, 5)

	love.graphics.draw(self.image, self.displayX, self.displayY, 0, 0.3)
end


function Character:getPossibleActions()
	local results = {}
	for k, action in pairs(self.actions) do
		if action.check(action.callbackTable) then
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
	local dfa = self.map:getTile(self.q, self.r)
	if dfa.type == "Startpoint" then
		for k, v in pairs(dfa.reachableBridges) do
			for l, w in pairs(results) do
				if v ~= w then
					table.insert(results, v)
				end
			end
		end
	end
	
	return results
end

function Character:checkBuildBridge()
	local tiles = self:getSurroundingTiles()
	local possibleTiles = {}
	for k, tile in ipairs(tiles) do
		if tile.type == "Bridge" or tile.type == "Sandbank" then
			if not tile.bridgeActive then
				table.insert(possibleTiles, tile)
			end
		end
	end
	if #possibleTiles >= 1 then
		return possibleTiles
	end
end

function Character:buildBridge(tile)
	self.currentActions = self.currentActions - 1
	if tile.type == "Bridge" or tile.type == "Sandbank" then
		tile.bridgeActive = true
	end
end

function Character:checkBuildBreaker()
	local tile = self.map:getTile(self.q, self.r)
	if tile.breakerDirections then
		return tile:breakerDirections()
	end
end

function Character:buildBreaker(direction)
	self.currentActions = self.currentActions - 1
	local tile = Map:getTile(self.q, self.r)
	tile:addBreaker(direction)
end

function Character:checkWalk()
	local surrounding = self:getSurroundingTiles()
	local results = {}
	for k, tile in pairs(surrounding) do
		if tile.type == "Bridge" then
			if tile.bridgeActive then
				if tile.walkToTiles then
					for k, option in pairs(tile.walkToTiles) do
						if option.ax ~= self.q or option.ay ~= self.r then
							table.insert(results, tile)
						end
					end
				end
			end
		end
	end
	if #results >= 1 then
		return results
	end
end

function Character:walk(newQ, newR)
	self.currentActions = self.currentActions - 1
	self.q = newQ
	self.r = newR
end

function Character:checkSleep()
	return true
end

function Character:sleep()
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
