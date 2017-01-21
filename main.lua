function love.load()
	-- Initialize Random number generator... don't ask.
	math.randomseed(os.time())
	math.random()
	math.random()
	math.random()
	-- ...just don't.

	require "tiles"
	require "camera"

	myMap = Map:new()
	myMap:buildIsland(0, 0, 3)
	myMap:buildBridge(0, 1)
end

function love.update(dt)
	if love.keyboard.isDown("a") then
		camera:move(-50 * dt * camera.scaleX, 0)
		updateMousePosition(love.mouse.getPosition())
	end
	if love.keyboard.isDown("d") then
		camera:move(50 * dt * camera.scaleX, 0)
		updateMousePosition(love.mouse.getPosition())
	end
	if love.keyboard.isDown("w") then
		camera:move(0, -50 * dt * camera.scaleY)
		updateMousePosition(love.mouse.getPosition())
	end
	if love.keyboard.isDown("s") then
		camera:move(0, 50 * dt * camera.scaleY)
		updateMousePosition(love.mouse.getPosition())
	end
end

function love.draw()
	camera:set()
	for k, v in pairs(myMap.tiles) do
		for l, tile in pairs(v) do
			tile:draw()
		end
	end
	if highlightedTile then
		highlightedTile:draw()
	end
	camera:unset()
end

function love.keypressed(key, scancode, isrepeat)
	if key == "q" then
		camera:setScale(camera.scaleX + 1, camera.scaleY + 1)
	elseif key == "e" then
		camera:setScale(camera.scaleX - 1, camera.scaleY - 1)
	elseif key == "i" then
		if highlightedTile then
			print(highlightedTile.type)
		end
	end
end

function love.mousemoved( x, y, dx, dy, istouch )
	updateMousePosition(x, y)
end

function updateMousePosition(x, y)
	if x == nil or y == nil then
		return 
	end
	x = x * camera.scaleX + camera.x
	y = y * camera.scaleY + camera.y 
	local returnTile = myMap:pixel_to_tile(x, y)
	if not returnTile then
		if highlightedTile then
			highlightedTile.color = {255, 255, 255}
			highlightedTile = nil
		end
		return
	end
	--print(returnTile.ax, returnTile.ay)
	if highlightedTile then
		if highlightedTile == returnTile then
			return
		else
			highlightedTile.color = {255, 255, 255}
		end
	end
	returnTile.color = {0, 255, 0}
	highlightedTile = returnTile
end
