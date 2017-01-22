-- MASTERDIE SECTION

MasterDie = {}

function MasterDie:rollNumbers(num)
	if num > 6 then
		num = 6
	end

	randoms = {}
	for i=1,num do
		table.insert(randoms, math.random(6))
	end
	return self:checkForDuplicates(randoms)
end

function MasterDie:checkForDuplicates(numbers)
	needReroll = false

	for i=1,table.getn(numbers) do
		for g=1,table.getn(numbers) do
			if not (i == g) then
				if numbers[i] == numbers[g] then
					needReroll = true
					break
				end
			end
		end
	end

	if needReroll then
		return self:rollNumbers(table.getn(numbers))
	end
	return numbers
end

-- END MASTERDIE SECTION

-- DIE SECTION

Die = {}
Die_mt = {__index = Die}

function Die:new(x, y)
	local newDie = {}
	setmetatable(newDie, Die_mt)

	newDie.images = {}
	newDie:loadGraphics()
	newDie.lastDisplay = newDie.images[1]

	print(tostring(table.getn(newDie.images)))

	--scrolling number
	newDie.rolledNumber = 1

	newDie.x = x
	newDie.y = y

	newDie.width = 40
	newDie.height = 40

	-- show the die?
	newDie.displayDie = false

	newDie.finalRoll = 0

	-- currently rolling?
	newDie.isActive = false

	-- timeline
	newDie.timeline = Timeline:new(4, false, false)
	newDie.lastState = 0

	Time:addUpdateCallback(newDie)

	return newDie
end

function Die:loadGraphics()
	for i=1,6 do
		table.insert(self.images, love.graphics.newImage("img/wuerfel_" .. tostring(i) .. ".png"))
	end
end

function Die:roll(finalNum)
	if not self.isActive then
		--print("I am rolling!")
		self.timeline:activate()
		self.isActive = true
		self.displayDie = true
		self.finalRoll = finalNum
		self:getNewNumber()
		self.lastState = 0
	end
	return self.finalRoll
end

function Die:getNewNumber()
	self.rolledNumber = math.random(6)
end

function Die:getNewImage()
	repeat
		self:getNewNumber()
	until self.lastDisplay ~= self.images[self.rolledNumber]
	self.lastDisplay = self.images[self.rolledNumber]
end

function Die:update()
	if self.timeline.active then
		if self.timeline:getPercentageDone() <= 0.25 then
			if self.timeline:getPercentageDone() - self.lastState >= 0.01 then
				self:getNewImage()
				self.lastState = self.timeline:getPercentageDone()
			end
		elseif self.timeline:getPercentageDone() <= 0.5 then
			if self.timeline:getPercentageDone() - self.lastState >= 0.05 then
				self:getNewImage()
				self.lastState = self.timeline:getPercentageDone()
			end
		elseif self.timeline:getPercentageDone() <= 0.75 then
			if self.timeline:getPercentageDone() - self.lastState >= 0.1 then
				self:getNewImage()
				self.lastState = self.timeline:getPercentageDone()
			end
		else 
			self.lastDisplay = self.images[self.finalRoll]
		end
	else
		self.isActive = false
		--self.displayDie = false
	end
end

function Die:draw()
	if self.displayDie then
		if self.lastDisplay then
			love.graphics.draw(self.lastDisplay, self.x, self.y, 0, 0.1)
			--love.graphics.print(self.lastDisplay, self.x, self.y, 0, 3)
		end
	end
end

-- END DIE SECTION

-- CHARACTER SELECTOR SECTION

CharacterSelector = {}

function CharacterSelector:init()
	if PlayerManager.currentPlayer then
		self.availableChars = PlayerManager.currentPlayer:getAvailableCharacters()
	end

	self.boxX = 100
	self.boxY = 0
	self.boxWidth = 200 + 25
	self.boxHeight = 60

	self.charX = 105
	self.charY = 5
	self.charWidth = 50
	self.charHeight = 50
	self.charSpacing = 5

	self.selectedChar = nil

	self.displaySelector = false
end

function CharacterSelector:drawBox()
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("fill", self.boxX, self.boxY, self.boxWidth, self.boxHeight)
end

function CharacterSelector:drawCharacter(character, num)
	if character.selected then
		love.graphics.setColor(255, 150, 150, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end
	character.selectorLoc = self.charX + (num - 1)*(self.charWidth+self.charSpacing)
	love.graphics.draw(character.image, self.charX + (num - 1)*(self.charWidth+self.charSpacing), self.charY, 0, 0.25)
	--love.graphics.rectangle("fill", self.charX + (num - 1)*(self.charWidth+self.charSpacing), self.charY, self.charWidth, self.charHeight)
end

function CharacterSelector:draw()
	if self.displaySelector then
		self:drawBox()
		if self.availableChars then
			for i=1,4 do
				if self.availableChars[i] then
					self:drawCharacter(self.availableChars[i], i)
				end
			end
			love.graphics.setColor(255, 255, 255, 255)
		end
	end
end

function CharacterSelector:update()
	--print("Current: " .. tostring(PlayerManager.currentPlayer.index))
	self.availableChars = PlayerManager.currentPlayer:getAvailableCharacters()
	--print(tostring(table.getn(self.availableChars)))
end

function CharacterSelector:deselectAll()
	for i=1,4 do
		if self.availableChars[i] then
			self.availableChars[i].selected = false
		end
	end
	UIManager:hideActionSelector()
end

function CharacterSelector:mouseClick(x, y)
	if not self.displaySelector then
		return false
	end

	local checkX = true

	if not (y >= self.charY and y <= (self.charY + self.charHeight)) then
		checkX = false
	end

	if checkX then

		local selectorChanged = false
		local selectedChar = nil

		for i=1,4 do
			if self.availableChars[i] then
				local currChar = self.availableChars[i]
				if currChar.selectorLoc then
					if x >= currChar.selectorLoc and x <= currChar.selectorLoc + self.charWidth then
						currChar.selected = true
						selectorChanged = true
						selectedChar = currChar
						self.selectedChar = currChar
						UIManager.displayActionSelector()
						break
					end
				end
			end
		end

		if selectorChanged then
			for i=1,4 do
				if self.availableChars[i] then
					if not (self.availableChars[i] == selectedChar) then
						self.availableChars[i].selected = false
					end
				end
			end
			ActionSelector:updateActiveButtons(selectedChar)
		end
	end

	--Input was handled
	if x >= self.boxX and x <= self.boxX + self.boxWidth and y >= self.boxY and y <= self.boxY + self.boxHeight then
		return true
	end
	return false
end

-- END CHARACTER SELECTOR SECTION

-- WAVE SELECTOR SECTION

WaveSelector = {}

function WaveSelector:init()
	local width, height, flags = love.window.getMode()
	self.boxWidth = 400
	self.boxHeight = 290
	self.boxX = width / 2 - self.boxWidth / 2 
	self.boxY = height / 2 - self.boxHeight / 2

	self.buttonWidth = 100
	self.buttonHeight = 100
	self.buttonSpacingX = 25
	self.buttonSpacingY = 30

	self.directionButtons = {}
	self.lastSelectedWaveDir = 0

	self.displaySelector = false

	self:initDirectionButtons()
end

function WaveSelector:initDirectionButtons()
	for i=0,5 do
		table.insert(self.directionButtons, self:createDirectionButton(i))
	end
end

function WaveSelector:createDirectionButton(dir)
	local dirButton = {}

	local xSpace = dir % 3
	local ySpace = math.floor(dir / 3)

	dirButton.image = love.graphics.newImage("img/arrow_" .. tostring(dir+1) .. ".png")

	dirButton.x = self.boxX + self.buttonSpacingX + xSpace * (self.buttonWidth + self.buttonSpacingX)
	dirButton.y = self.boxY + self.buttonSpacingY + ySpace * (self.buttonHeight + self.buttonSpacingY)

	dirButton.direction = dir + 1

	return dirButton
end

function WaveSelector:drawBox()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.rectangle("fill", self.boxX, self.boxY, self.boxWidth, self.boxHeight)
	love.graphics.setColor(255, 255, 255, 255)
end

function WaveSelector:drawButton(button)
	love.graphics.draw(button.image, button.x, button.y, 0, 0.5)
	-- love.graphics.setColor(0, 255, 0, 255)
	-- love.graphics.rectangle("fill", button.x, button.y, self.buttonWidth, self.buttonHeight)
	-- love.graphics.setColor(255, 0, 0, 255)
	-- love.graphics.print(button.direction, button.x + self.buttonWidth / 2, button.y + self.buttonHeight / 2, 0, 4)
end

function WaveSelector:draw()
	if self.displaySelector then
		self:drawBox()
		for i=1,6 do
			if self.directionButtons[i] then
				self:drawButton(self.directionButtons[i])
			end
		end
	end
	love.graphics.setColor(255, 255, 255, 255)
end

function WaveSelector:mouseClick(x, y)
	if not self.displaySelector then
		return false
	end

	for i=1,6 do
		if self.directionButtons[i] then
			local currBut = self.directionButtons[i]

			if x >= currBut.x and x <= currBut.x + self.buttonWidth and y >= currBut.y and y <= currBut.y + self.buttonHeight then
				self.lastSelectedWaveDir = currBut.direction
				self.displaySelector = false
				WaveInfoImage.buttonLocked = true
				PlayerManager:waveDirIsSet(dir)
			end
		end
	end

	--Input was handled
	if x >= self.boxX and x <= self.boxX + self.boxWidth and y >= self.boxY and y <= self.boxY + self.boxHeight then
		return true
	end
	return false
end

-- END WAVE SELECTOR SECTION

-- PLAYERIMAGE SECTION

CurrentPlayerImage = {}

function CurrentPlayerImage:setPlayer(player)
	--TODO read image from Player object
	if player then
		self.image = player.portrait
	else
		self.image = love.graphics.newImage("img/spieler1_1.png")
	end
end

function CurrentPlayerImage:drawBox()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.rectangle("fill", 0, 0, 64, 104)
	love.graphics.setColor(255, 255, 255, 255)
end

function CurrentPlayerImage:drawImage()
	love.graphics.draw(self.image, -20, 0, 0, 0.5)
end

function CurrentPlayerImage:draw()
	self:drawBox()
	self:drawImage()
	love.graphics.setColor(255, 255, 255, 255)
end

-- END CURRENTPLAYERIMAGE SECTION

-- ORDERSELECTOR SECTION

OrderSelector = {}

function OrderSelector:init()
	self.dice = {Die:new(377, 60), Die:new(521, 60), Die:new(665, 60), Die:new(809, 60)}
	self.diceValues = {}
	self.diceRolling = false

	self.done = false

	self.displaySelector = false
end

function OrderSelector:reset()
	self.diceValues = {}
	self.diceRolling = false
	self.done = false
	self.displaySelector = false
end

function OrderSelector:update()
	if not self.done then

		diceActive = false

		if self.diceRolling then
			for i=1,table.getn(self.dice) do
				if self.dice[i] then
					if self.dice[i].isActive then
						diceActive = true
					end
				end
			end
		end

		if not diceActive then
			self.diceRolling = false
			self:orderPlayers()
		end
	end
end

function OrderSelector:rollDice()
	self.displaySelector = true

	self.rolledNumbers = MasterDie:rollNumbers(table.getn(self.dice))
	self.diceValues = self.rolledNumbers

	for i=1,table.getn(self.dice) do
		if self.dice[i] then
			self.dice[i]:roll(self.rolledNumbers[i])
		end
	end
	self.diceRolling = true
end

function OrderSelector:drawDice()
	for i=1,4 do
		if self.dice[i] then
			self.dice[i]:draw()
		end
	end
end

function OrderSelector:draw()
	--OrderSelector:drawPlayerImages()
	self:drawDice()
end

--UNUSED
-- function OrderSelector:evaluateResult()

-- 	local sameIDs = {}

-- 	for i=1,4 do
-- 		for g=1,4 do
-- 			if self.diceValues[i] and self.diceValues[g] then
-- 				if self.diceValues[i] == self.diceValues[g] then
-- 					if not (i == g) then
-- 						local containsI = false
-- 						local containsG = false

-- 						for z=1,4 do
-- 							if sameIDs[z] then
-- 								if sameIDs[z] == self.diceValues[i] then
-- 									containsI = true
-- 								end
-- 								if sameIDs[z] == self.diceValues[g] then
-- 									containsG = true
-- 								end
-- 							end
-- 						end

-- 						if not containsI then
-- 							table.insert(sameIDs, i)
-- 						end
-- 						if not containsG then
-- 							table.insert(sameIDs, g)
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	if table.getn(sameIDs) == 0 then
-- 		self.done = true
-- 		self:orderPlayers()
-- 	else
-- 		self:reroll(sameIDs)
-- 	end
-- end

function OrderSelector:orderPlayers()
	local biggerThanMe = 1
	local order = {}

	local wave = false

	for i=1,4 do
		--Check if a 6 was rolled
		if self.diceValues[i] == 6 then
			wave = true
		end

		for g=1,4 do
			if self.diceValues[i] < self.diceValues[g] then
				biggerThanMe = biggerThanMe + 1
			end
		end
		order[biggerThanMe] = i
		biggerThanMe = 1
	end

	--set wave icon depending on 6
	WaveInfoImage:setWave(wave)
	print("wave set to: " .. tostring(wave))

	PlayerOrderDisplay:setOrder(order)
	UIManager:displayPlayerOrderDisplay()
	PlayerManager:updateInc(order)
	self.displaySelector = false
end

--UNUSED
-- function OrderSelector:reroll(sameIDs)
-- 	for i=1,4 do
-- 		if sameIDs[i] then
-- 			index = sameIDs[i]
-- 			if self.dice[index] then
-- 				self.diceValues[index] = self.dice[index]:roll()
-- 			end
-- 		end
-- 	end
-- 	self.diceRolling = true
-- end

-- END ORDERSELECTOR SECTION

-- PLAYERORDERDISPLAY SECTION

PlayerOrderDisplay = {}

function PlayerOrderDisplay:init()
	self.playerImages = {}

	self:initImages()
	
	self.emptyImage = love.graphics.newImage("empty.jpg")

	self.order = {}

	width, height, flags = love.window.getMode()

	self.boxX = 0
	self.boxY = height - 70
	self.boxWidth = 250
	self.boxHeight = 120

	self.imageX = 10
	self.imageY = self.boxY + 10
	self.imageWidth = 50
	self.imageHeight = 50
	self.imageSpacing = 10

	self.displayThis = false
end

function PlayerOrderDisplay:initImages()
	for i=1,4 do
		table.insert(self.playerImages, love.graphics.newImage("/img/spieler" .. tostring(i) .. "_1.png"))
	end
end

function PlayerOrderDisplay:setOrder(order)
	if table.getn(order) == 4 then
		self.order = order
	else
		print("Invalid table size : PlayerOrderDisplay.order")
	end

	for i=1,4 do
		print(tostring(self.order[i]))
	end
end

function PlayerOrderDisplay:setEmpty()
	self.order = {}
end

function PlayerOrderDisplay:drawBox()
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.rectangle("fill", self.boxX, self.boxY, self.boxWidth, self.boxHeight)
	love.graphics.setColor(255, 255, 255, 255)
end

function PlayerOrderDisplay:drawImage(num, id)
	if id == -1 then
		love.graphics.draw(self.emptyImage, self.imageX + (num - 1) * (self.imageSpacing + self.imageWidth), self.imageY)		
		return nil
	end

	if self.playerImages[id] then
		love.graphics.draw(self.playerImages[id], self.imageX + (num - 1) * (self.imageSpacing + self.imageWidth), self.imageY, 0, 0.25)
	else
		love.graphics.draw(self.defaultImage, self.imageX + (num - 1) * (self.imageSpacing + self.imageWidth), self.imageY)
	end
end

function PlayerOrderDisplay:draw()
	if self.displayThis then
		self:drawBox()
		for i=1,4 do
			if self.order[i] then
				self:drawImage(i, self.order[i])
			else
				self:drawImage(i, -1)
			end
		end
	end
end

-- END PLAYERORDERDISPLAY SECTION

-- ACTIONSELECTOR SECTION

ActionSelector = {}

function ActionSelector:init()

	self.boxX = 0
	self.boxY = 200
	self.boxWidth = 70
	self.boxHeight = 250

	self.buttonX = 10
	self.buttonY = 210
	self.buttonWidth = 50
	self.buttonHeight = 50
	self.buttonSpacingY = 10

	self.buttons = {self:createButton(1, true), self:createButton(2, true), self:createButton(3, true), self:createButton(4, true)}
	self.buttonImages = {}

	self.currentAction = nil
	self.validTiles = nil

	self.displaySelector = false
end

function ActionSelector:drawButtons()
	for i=1,4 do
		if self.buttons[i] then
			self:drawButton(self.buttons[i])
		end
	end
end

function ActionSelector:updateActiveButtons(selectedChar)
	for i=1,4 do
		self.buttons[i].active = false
	end

	for i=1,5 do
		if selectedChar:getPossibleActions()[i] then
			if selectedChar:getPossibleActions()[i].name == "Build Bridge" then
				self.buttons[1].active = true
				self.buttons[1].action = selectedChar:getPossibleActions()[i]
			elseif selectedChar:getPossibleActions()[i].name == "Build wave breaker" then
				self.buttons[2].active = true
				self.buttons[2].action = selectedChar:getPossibleActions()[i]
			elseif selectedChar:getPossibleActions()[i].name == "Walk" then
				self.buttons[3].active = true
				self.buttons[3].action = selectedChar:getPossibleActions()[i]
			else
				self.buttons[4].active = true
				self.buttons[4].action = selectedChar:getPossibleActions()[i]
			end
		end
	end
end
	

function ActionSelector:createButton(num, active)
	local button = {}
	button.x = self.buttonX
	button.active = active
	button.image = love.graphics.newImage("img/action_" .. tostring(num) .. ".png")
	button.imageSel = love.graphics.newImage("img/action_" .. tostring(num) .. "_selected.png")
	button.y = self.buttonY + (num-1) * (self.buttonHeight + self.buttonSpacingY)

	return button
end

function ActionSelector:drawButton(button)
	if button.active then
		love.graphics.setColor(255, 255, 255, 255)
	else
		love.graphics.setColor(140, 140, 140, 255)
	end
	if button.selected then
		love.graphics.draw(button.imageSel, button.x, button.y, 0, 0.25)
	else
		love.graphics.draw(button.image, button.x, button.y, 0, 0.25)
	end
end

function ActionSelector:tileClicked(tile)
	if self.awaitingInput then
		tileValid = false
		for i=1,6 do
			if tile == self.validTiles[i] then
				tileValid = true
				break
			end
		end

		if tileValid then
			self.currentAction.func(self.currentAction.callbackTable, tile)
			self:hideStuff()
			return nil
		end
		self.awaitingInput = false
		UIManager.displayActionSelector()
		Tile.unhighlihgtAll()
	end
end

function ActionSelector:drawBox()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.rectangle("fill", self.boxX, self.boxY, self.boxWidth, self.boxHeight)
end

function ActionSelector:draw()
	if self.displaySelector then
		self:drawBox()
		self:drawButtons()
		love.graphics.setColor(255, 255, 255, 255)
	end
end

function ActionSelector:mouseClick(x, y)
	if not self.displaySelector then
		return false
	end

	for i=1,4 do
		if self.buttons[i] then
			local currBut = self.buttons[i]

			if x >= currBut.x and x <= currBut.x + self.buttonWidth and y >= currBut.y and y <= currBut.y + self.buttonHeight then

				if currBut.active then
					
					if currBut.action.name == "Build Bridge" then
						availTiles = currBut.action.check(currBut.action.callbackTable)
						self.awaitingInput = true
						self.currentAction = currBut.action
						self.validTiles = availTiles
						print("bride")
					elseif currBut.action.name == "Build wave breaker" then
						availTiles = currBut.action.check(currBut.action.callbackTable)
						self.awaitingInput = true
						self.currentAction = currBut.action
						self.validTiles = availTiles
					elseif currBut.action.name == "Walk" then
						availTiles = currBut.action.check(currBut.action.callbackTable)
						self.awaitingInput = true
						self.currentAction = currBut.action
						self.validTiles = availTiles
						print("walk")
					else 
						currBut.action.func(currBut.action.callbackTable)
					end		--TODO Call Character Action
					self:highLightTiles()
				end
				break
			end
		end
	end

	--Input was handled
	if x >= self.boxX and x <= self.boxX + self.boxWidth and y >= self.boxY and y <= self.boxY + self.boxHeight then
		return true
	end
	return false
end

function ActionSelector:highLightTiles()
	for i=1,6 do
		if self.validTiles[i] then
			self.validTiles[i]:highlight()
		end
	end
end

function ActionSelector:hideStuff()
	print("hidden")
	UIManager:hideActionSelector()
	Tile.unhighlihgtAll()
	if table.getn(CharacterSelector.availableChars) <= 1 then
		UIManager:hideActionSelector()
		UIManager:hideCharacterSelector()
		PlayerManager:nextPlayer()
	end	
end

-- END ACTIONSELECTOR SECTION

-- WAVE INFO SECTION

WaveInfoImage = {}

function WaveInfoImage:init()
	self.noWaveImage = love.graphics.newImage("img/waterlevel_no_wave.png")
	self.waveImage = love.graphics.newImage("img/waterlevel_wave.png")

	self.waveComes = false

	width, height, flags = love.window.getMode( )

	self.x = width - 200
	self.y = 0

	self.buttonLocked = true

	self.displayImage = true
end

function WaveInfoImage:setWave(waveComes)
	self.waveComes = waveComes
end

function WaveInfoImage:draw()
	if self.waveComes then
		if not self.buttonLocked then
			if WaveSelector.displaySelector then
				love.graphics.setColor(255, 0, 0, 255)
			else
				love.graphics.setColor(0, 255, 0, 255)
			end
		end
		love.graphics.draw(self.waveImage, self.x, self.y)
		love.graphics.setColor(255, 255, 255, 255)
	else
		love.graphics.draw(self.noWaveImage, self.x, self.y)
	end
end

function WaveInfoImage:toggleWaveSelector()
	WaveSelector.displaySelector = not WaveSelector.displaySelector
end

function WaveInfoImage:isWaveComing()
	return self.waveComes
end

function WaveInfoImage:mouseClick(x, y)
	if not self.buttonLocked then
		if x >= self.x and x <= self.x + 200 and y >= self.y and y <= self.y + 200 then
			self:toggleWaveSelector()
			return true
		end
	end
	return false
end

-- END WAVE INFO SECTION

-- UIMANAGER SECTION

UIManager = {}

function UIManager:init()
	CurrentPlayerImage:setPlayer(nil)
	WaveInfoImage:init()
	OrderSelector:init()
	PlayerOrderDisplay:init()
	ActionSelector:init()
	CharacterSelector:init()
	WaveSelector:init()
end

function UIManager:update()
	if CharacterSelector.displaySelector then
		CharacterSelector:update()
	end
	if OrderSelector.displaySelector then
		OrderSelector:update()
	end
end

function UIManager:draw()
	CurrentPlayerImage:draw()

	if PlayerOrderDisplay.displayThis then
		PlayerOrderDisplay:draw()
	end

	if CharacterSelector.displaySelector then
		CharacterSelector:draw()
	end
	if WaveSelector.displaySelector then
		WaveSelector:draw()
	end

	if OrderSelector.displaySelector then
		OrderSelector:draw()
	end

	if ActionSelector.displaySelector then
		ActionSelector:draw()
	end

	if WaveInfoImage.displayImage then
		WaveInfoImage:draw()
	end
end

function UIManager:displayActionSelector()
	ActionSelector.displaySelector = true
end

function UIManager:hideActionSelector()
	ActionSelector.displaySelector = false
end

function UIManager:displayWaveSelector()
	WaveSelector.displaySelector = true
end

function UIManager:hideWaveSelector()
	WaveSelector.displaySelector = false
end

function UIManager:displayPlayerOrderDisplay()
	PlayerOrderDisplay.displayThis = true
end

function UIManager:displayCharacterSelector()
	CharacterSelector.displaySelector = true
end

function UIManager:hideCharacterSelector()
	CharacterSelector.displaySelector = false
end

function UIManager:displayWaveImage()
	WaveInfoImage.displayImage = true
end


function UIManager:mouseClickEvent(x, y)
	if WaveInfoImage:mouseClick(x, y) then
		return true
	end
	if CharacterSelector:mouseClick(x, y) then
		return true
	end
	if WaveSelector:mouseClick(x, y) then
		return true
	end
	if ActionSelector:mouseClick(x, y) then
		return true
	end
	return false
end

function UIManager:rollDice()
	OrderSelector:rollDice()
end

function UIManager:unlockWaveButton()
	WaveInfoImage.buttonLocked = false
end
