Tile = {}
Tile.type = "Tile"
Tile.highlighted = {}
Tile_mt = {__index = Tile}

function Tile:new(x, y, size, ax, ay)
	local newTile = {}
	setmetatable(newTile, Tile_mt)

	newTile.x = x or 0
	newTile.y = y or 0
	newTile.ax = ax
	newTile.ay = ay
	newTile.size = size or 50
	newTile.canvas = love.graphics.newCanvas(size * 2, size * 2)
	newTile.color = {255, 255, 255}
	love.graphics.setCanvas(newTile.canvas)
	for i=1, 6 do
		local x1, y1 = Tile:corner(size, size, size, i - 1)
		local x2, y2 = Tile:corner(size, size, size, i)
		love.graphics.line(x1, y1, x2, y2)
	end
	love.graphics.setCanvas()

	return newTile
end

function Tile:draw(text)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.canvas, self.x - self.size, self.y - self.size)
	if self.sprite then
		if self.highlightBool then
			print("hello?")
			love.graphics.setColor(100, 255, 255)
		else
			love.graphics.setColor(255, 255, 255)
		end
		love.graphics.draw(self.sprite, self.x - 50, self.y - 50, 0, 0.5)
	end
	if text then
		love.graphics.print(text, self.x, self.y)
	end

	

	-- love.graphics.setColor(255, 255, 255, 255)

	-- if self.type == "Island" then
	-- 	love.graphics.draw(tileGraphics[1], self.x - 50, self.y - 50, 0.523599, 0.5)
	-- elseif self.type == "Sandbank" then
	-- 	if self.sandbankActive then
	-- 		love.graphics.draw(tileGraphics[2], self.x, self.y, 0, 0.5)
	-- 	else 
	-- 		love.graphics.draw(tileGraphics[3], self.x, self.y, 0, 0.5)
	-- 	end
	-- elseif self.type == "Bridge" then
	-- 	love.graphics.draw(tileGraphics[4], self.x, self.y0, 0.5)
	-- end
end

function Tile:highlight()
	self.highlightBool = true
	table.insert(Tile.highlighted, self)
end

function Tile.unhighlihgtAll()
	for k, tile in pairs(Tile.highlighted) do
		tile.highlightBool = nil
	end
	Tile.highlighted = {}
end

function Tile:corner(x, y, size, i)
    angle_deg = 60 * i + 30 
    angle_rad = math.pi / 180 * angle_deg
    return x + size * math.cos(angle_rad), y + size * math.sin(angle_rad)
end

Island = {}
Island.type = "Island"
Island.list = {}
setmetatable(Island, Tile_mt)
Island_mt = {__index = Island}

function Island:new(tile, numBlockers)
	numBlockers = numBlockers or 2
	if not tile then
		return nil 
	end

	local newIsland = tile 
	setmetatable(newIsland, Island_mt)
	newIsland.blockers = {}
	for i = 1, 6 do
		newIsland.blockers[i] = false
	end
	newIsland.characters = {}

	local directions = {1, 2, 3, 4, 5, 6}

	love.graphics.setCanvas(newIsland.canvas)

	for i = 1, numBlockers do
		local randNum = round(math.random(#directions - 1) + 0.5)
		newIsland.blockers[directions[randNum]] = true

		local x1, y1 = newIsland:corner(newIsland.size, newIsland.size, newIsland.size - 5, directions[randNum] - 1)
		local x2, y2 = newIsland:corner(newIsland.size, newIsland.size, newIsland.size - 5, directions[randNum])
		love.graphics.line(x1, y1, x2, y2)

		table.remove(directions, randNum)
	end	

	love.graphics.setCanvas()

	newIsland.color = {255, 0, 0}

	newIsland.sprite = tileGraphics[1]

	table.insert(Island.list, newIsland)

	return newIsland
end

function Island:addBreaker(direction)
	self.blockers[direction] = true
end

function Island:breakerDirections()
	results = {}
	for k, v in pairs(self.blockers) do
		if v == false then
			table.insert(results, k)
		end
	end
	if #results >= 1 then
		return results
	end
end

function Island:flush()
	for k, player in ipairs(PlayerManager.players) do
		for k, character in ipairs(player.characters) do
			if character.q == self.ax and character.r == self.ay then
				character.q = player.q
				character.r = player.r
			end
		end
	end
end

Bridge = {}
Bridge.type = "Bridge"
Bridge.list = {}
Bridge.sprite = {}
setmetatable(Bridge, Tile_mt)
Bridge_mt = {__index = Bridge}

function Bridge:new(tile)
	if not tile then
		return nil
	end
	local newBridge = tile
	setmetatable(newBridge, Bridge_mt)
	newBridge.bridgeActive = false
	newBridge.color = {0, 0, 255}
	newBridge.walkToTiles = {}
	for i = -1, 1 do
		for j = -1, 1 do
			local tile = Map.map:getTile(newBridge.ax + i, newBridge.ay + j)
			if tile then
				if tile.type == "Island" then
					table.insert(newBridge.walkToTiles, tile)
				end
			end
		end
	end

	newBridge.sprite = tileGraphics[4]

	table.insert(Bridge.list, newBridge)

	return newBridge
end

function Bridge:draw()
	if self.active then
		-- TODO draw bridge
	end
end

Sandbank = {}
setmetatable(Sandbank, Tile_mt)
Sandbank.type = "Sandbank"
Sandbank.list = {}
Sandbank.sprite = {}
Sandbank_mt = {__index = Sandbank}

function Sandbank:new(tile)
	if not tile then
		return nil
	end

	local newSandbank = tile
	setmetatable(newSandbank, Sandbank_mt)
	newSandbank.bridgeActive = false
	newSandbank.sandbankActive = false
	newSandbank.color = {255, 255, 0}
	newSandbank.walkToTiles = {}
	for i = -1, 1 do
		for j = -1, 1 do
			local tile = Map.map:getTile(newSandbank.ax + i, newSandbank.ay + j)
			if tile then
				if tile.type == "Island" then
					table.insert(newSandbank.walkToTiles, tile)
				end
			end
		end
	end

	table.insert(self.list, newSandbank)
	return newSandbank
end

function Sandbank:draw()
	if self.highlightBool then
		love.graphics.setColor(100, 255, 255)
	else
		love.graphics.setColor(255, 255, 255)
	end
	if self.bridgeActive then
		-- TODO draw bridge
		love.graphics.draw(tileGraphics[4], self.x - 50, self.y - 50, 0, 0.5)

	elseif self.sandbankActive then
		-- TODO draw sandbank
		love.graphics.draw(tileGraphics[2], self.x - 50, self.y - 50, 0, 0.5)
	else
		-- TODO draw underwater sandbank
		love.graphics.draw(tileGraphics[3], self.x - 50, self.y - 50, 0, 0.5)
	end
end

Startpoint = {}
Startpoint.type = "Startpoint"
Startpoint.list = {}
Startpoint.sprite = {}
Startpoint_mt = {__index = Startpoint}

function Startpoint:new(tile)
	if not tile then
		return nil
	end

	local newStartpoint = tile
	setmetatable(newStartpoint, Startpoint_mt)
	newStartpoint.bridgeActive = false
	newStartpoint.sandbankActive = false
	newStartpoint.color = {255, 255, 0}
	newStartpoint.reachableBridges = {}
	table.insert(self.list, newStartpoint)
	return newStartpoint
end

function Startpoint:addReachableBridge(tile)
	table.insert(self.reachableBridges, tile)
end

function Startpoint:draw()
	-- TODO draw startpoint
end


Map = {}
Map.map = {}
Map_mt = {__index = Map}

function Map:new(radius, tileSize)
	radius = radius or 8
	tileSize = tileSize or 50

	local newMap = {}
	setmetatable(newMap, Map_mt)
	newMap.tileSize = tileSize
	newMap.tiles = {}
	for i = -radius, radius do
		newMap.tiles[i] = {}
	end

	width = tileSize * 2
	height = math.sqrt(3) / 2 * width
	horiz = width * 3/4
	vert = height / 2

	for i = -radius, radius do
		for j = -radius, radius do
			for k = -radius, radius do
				if i + j + k == 0 then
					local x, y = newMap:tileToPixel(i, j)
					newMap.tiles[i][j] = Tile:new(x, y, tileSize, i, j)
				end
			end
		end
	end

	Map.map = newMap

	local tempStartPoint = {}
	tempStartPoint = Startpoint:new(newMap:getTile(8, -5))
	Island:new(newMap:getTile(6, -6), 4)
	Island:new(newMap:getTile(6, -4), 2)
	Island:new(newMap:getTile(6, -2), 4)
	Island:new(newMap:getTile(4, -4), 2)
	Island:new(newMap:getTile(4, -2), 2)
	Island:new(newMap:getTile(2, -2), 0)
	Sandbank:new(newMap:getTile(6, -5))
	Sandbank:new(newMap:getTile(6, -3))
	Sandbank:new(newMap:getTile(5, -5))
	Sandbank:new(newMap:getTile(5, -2))
	Bridge:new(newMap:getTile(7, -6))
	Bridge:new(newMap:getTile(7, -5))
	Bridge:new(newMap:getTile(7, -4))
	Bridge:new(newMap:getTile(7, -3))
	Bridge:new(newMap:getTile(5, -4))
	Bridge:new(newMap:getTile(5, -3))
	Bridge:new(newMap:getTile(4, -3))
	Bridge:new(newMap:getTile(3, -3))
	Bridge:new(newMap:getTile(3, -2))
	Bridge:new(newMap:getTile(1, -1))
	tempStartPoint:addReachableBridge(newMap:getTile(7, -6))
	tempStartPoint:addReachableBridge(newMap:getTile(7, -5))
	tempStartPoint:addReachableBridge(newMap:getTile(7, -4))
	tempStartPoint:addReachableBridge(newMap:getTile(7, -3))


	tempStartPoint = Startpoint:new(newMap:getTile(3, 5))
	Island:new(newMap:getTile(0, 6), 4)
	Island:new(newMap:getTile(4, 2), 2)
	Island:new(newMap:getTile(2, 4), 4)
	Island:new(newMap:getTile(0, 4), 2)
	Island:new(newMap:getTile(2, 2), 2)
	Island:new(newMap:getTile(0, 2), 0)
	Sandbank:new(newMap:getTile(0, 5))
	Sandbank:new(newMap:getTile(1, 5))
	Sandbank:new(newMap:getTile(3, 3))
	Sandbank:new(newMap:getTile(3, 2))
	Bridge:new(newMap:getTile(4, 3))
	Bridge:new(newMap:getTile(3, 4))
	Bridge:new(newMap:getTile(2, 5))
	Bridge:new(newMap:getTile(1, 6))
	Bridge:new(newMap:getTile(1, 4))
	Bridge:new(newMap:getTile(2, 3))
	Bridge:new(newMap:getTile(1, 3))
	Bridge:new(newMap:getTile(1, 2))
	Bridge:new(newMap:getTile(0, 3))
	Bridge:new(newMap:getTile(0, 1))
	tempStartPoint:addReachableBridge(newMap:getTile(4, 3))
	tempStartPoint:addReachableBridge(newMap:getTile(3, 4))
	tempStartPoint:addReachableBridge(newMap:getTile(2, 5))
	tempStartPoint:addReachableBridge(newMap:getTile(1, 6))


	tempStartPoint = Startpoint:new(newMap:getTile(-8, 5))
	Island:new(newMap:getTile(-4, 4), 2)
	Island:new(newMap:getTile(-6, 2), 2)
	Island:new(newMap:getTile(-6, 6), 4)
	Island:new(newMap:getTile(-6, 4), 2)
	Island:new(newMap:getTile(-4, 2), 4)
	Island:new(newMap:getTile(-2, 2), 0)
	Sandbank:new(newMap:getTile(-6, 5))
	Sandbank:new(newMap:getTile(-5, 5))
	Sandbank:new(newMap:getTile(-6, 3))
	Sandbank:new(newMap:getTile(-5, 2))
	Bridge:new(newMap:getTile(-5, 3))
	Bridge:new(newMap:getTile(-5, 4))
	Bridge:new(newMap:getTile(-4, 3))
	Bridge:new(newMap:getTile(-3, 2))
	Bridge:new(newMap:getTile(-3, 3))
	Bridge:new(newMap:getTile(-1, 1))
	Bridge:new(newMap:getTile(-7, 3))
	Bridge:new(newMap:getTile(-7, 4))
	Bridge:new(newMap:getTile(-7, 5))
	Bridge:new(newMap:getTile(-7, 6))
	tempStartPoint:addReachableBridge(newMap:getTile(-7, 6))
	tempStartPoint:addReachableBridge(newMap:getTile(-7, 5))
	tempStartPoint:addReachableBridge(newMap:getTile(-7, 4))
	tempStartPoint:addReachableBridge(newMap:getTile(-7, 3))

	tempStartPoint = Startpoint:new(newMap:getTile(-3, -5))
	Island:new(newMap:getTile(-2, -4), 2)
	Island:new(newMap:getTile(-4, -2), 4)
	Island:new(newMap:getTile(-2, -2), 2)
	Island:new(newMap:getTile(0, -6), 4)
	Island:new(newMap:getTile(0, -4), 2)
	Island:new(newMap:getTile(0, -2), 0)
	Sandbank:new(newMap:getTile(-3, -3))
	Sandbank:new(newMap:getTile(-3, -2))
	Sandbank:new(newMap:getTile(-1, -5))
	Sandbank:new(newMap:getTile(0, -5))
	Bridge:new(newMap:getTile(-4, -3))
	Bridge:new(newMap:getTile(-3, -4))
	Bridge:new(newMap:getTile(-2, -5))
	Bridge:new(newMap:getTile(-1, -6))
	Bridge:new(newMap:getTile(-2, -3))
	Bridge:new(newMap:getTile(-1, -4))
	Bridge:new(newMap:getTile(1, -3))
	Bridge:new(newMap:getTile(0, -3))
	Bridge:new(newMap:getTile(-1, -2))
	Bridge:new(newMap:getTile(0, -1))
	tempStartPoint:addReachableBridge(newMap:getTile(-4, -3))
	tempStartPoint:addReachableBridge(newMap:getTile(-3, -4))
	tempStartPoint:addReachableBridge(newMap:getTile(-2, -5))
	tempStartPoint:addReachableBridge(newMap:getTile(-1, -6))

	local jgds = newMap:getTile(0, -5)
	jgds:highlight()
	jgds = newMap:getTile(2, 4)
	jgds:highlight()
	jgds = newMap:getTile(3, 3)
	jgds:highlight()

	print("highlight: ", #Tile.highlighted)

	return newMap
end

function Map:draw()
	if self.tiles then
		for k, v in pairs(self.tiles) do
			for l, tile in pairs(v) do
				tile:draw(tostring(k) .. " " .. tostring(l))
			end
		end
	end
end

function Map:wave(direction)
	for k, bridge in ipairs(Bridge.list) do
		bridge.bridgeActive = false
	end
	for k, isle in ipairs(Island.list) do
		if not isle.blockers[direction] then
			isle.flush()
		end
	end
end

function Map:hideSandbanks()
	for k, v in ipairs(Sandbank.list) do
		v.sandbankActive = false
	end
end

function Map:getSpawnPoint(i)
	local tile = Startpoint.list[i]
	return tile.ax, tile.ay
end

function Map:buildIsland(q, r, numBlockers)
	self.tiles[q][r] = Island:new(self.tiles[q][r], numBlockers)
end

function Map:buildBridge(q, r)
	self.tiles[q][r] = Bridge:new(self.tiles[q][r])
end

function Map:getTile(q, r)
	if self.tiles then
		if self.tiles[q] then
			if self.tiles[q][r] then
				return self.tiles[q][r]
			end
		end
	end
end

function Map:pixelToTile(x, y)
    local q = (x * math.sqrt(3)/3 - y / 3) / self.tileSize
    local r = y * 2/3 / self.tileSize
    local dx, dy = self:hexRound(q, r)
    if self.tiles[dx] then
    	if self.tiles[dx][dy] then
    		return self.tiles[dx][dy]
    	end
    end
end

function Map:hexRound(x, y)
    return Map:cubeToHex(Map:cubeRound(Map:hexToCube(x, y)))
end

function Map:tileToPixel(q, r)
    x = self.tileSize * math.sqrt(3) * (q + r/2)
    y = self.tileSize * 3/2 * r
    return x, y
end

function Map:hexToCube(x, y)
    return x, y, -x-y
end


function Map:cubeToHex(x, y, z)
    return x, y
end

function Map:cubeRound(x, y, z)
    local rx = round(x)
    local ry = round(y)
    local rz = round(z)

    local x_diff = math.abs(rx - x)
    local y_diff = math.abs(ry - y)
    local z_diff = math.abs(rz - z)

    if x_diff > y_diff and x_diff > z_diff then
        rx = -ry-rz
    elseif y_diff > z_diff then
        ry = -rx-rz
    else
        rz = -rx-ry
    end

    return rx, ry, rz
end

function Map:cube_add(x1, y1, z1, x2, y2, z2)
	return x1 + x2, y1 + y2, z1 + z2
end

function Map:cube_distance(x1, y1, z1, x2, y2, z2)
	return (math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)) / 2
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
