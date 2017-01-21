Tile = {}
Tile.type = "Tile"
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
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.sprite, self.x, self.y)
	end
	if text then
		love.graphics.print(text, self.x, self.y)
	end
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

	table.insert(Island.list, newIsland)

	return newIsland
end

Bridge = {}
Bridge.type = "Bridge"
Bridge.list = {}
setmetatable(Bridge, Tile_mt)
Bridge_mt = {__index = Bridge}

function Bridge:new(tile)
	if not tile then
		return nil
	end
	local newBridge = tile
	setmetatable(newBridge, Bridge_mt)

	love.graphics.setCanvas(newBridge.canvas)
	love.graphics.circle("fill", newBridge.size, newBridge.size, 15)
	love.graphics.setCanvas()

	table.insert(Bridge.list, newBridge)

	return newBridge
end

Map = {}
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
					local x, y = newMap:tile_to_pixel(i, j)
					newMap.tiles[i][j] = Tile:new(x, y, tileSize, i, j)
				end
			end
		end
	end

	return newMap
end

function Map:buildIsland(q, r, numBlockers)
	self.tiles[q][r] = Island:new(self.tiles[q][r], numBlockers)
end

function Map:buildBridge(q, r)
	self.tiles[q][r] = Bridge:new(self.tiles[q][r])
end

function Map:pixel_to_tile(x, y)
    local q = (x * math.sqrt(3)/3 - y / 3) / self.tileSize
    local r = y * 2/3 / self.tileSize
    local dx, dy = self:hex_round(q, r)
    if self.tiles[dx] then
    	if self.tiles[dx][dy] then
    		return self.tiles[dx][dy]
    	end
    end
end

function Map:tile_to_pixel(q, r)
    x = self.tileSize * math.sqrt(3) * (q + r/2)
    y = self.tileSize * 3/2 * r
    return x, y
end

function Map:hex_round(x, y)
    return Map:cube_to_hex(Map:cube_round(Map:hex_to_cube(x, y)))
end

function Map:hex_to_cube(x, y)
    return x, y, -x-y
end


function Map:cube_to_hex(x, y, z)
    return x, y
end

function Map:cube_round(x, y, z)
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

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end