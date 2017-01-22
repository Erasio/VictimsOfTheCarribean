function love.load()
	-- Initialize Random number generator... don't ask.
	math.randomseed(os.time())
	math.random()
	math.random()
	math.random()
	-- ...just don't.

	require "tiles"
	require "camera"
	require "player"
	require "time"
	require "UI"

	love.window.setMode(1280, 720)

	background = love.graphics.newImage("img/ocean_map.png")
	tileGraphics = {}

	table.insert(tileGraphics, love.graphics.newImage("img/tile_island_1.png"))
	table.insert(tileGraphics, love.graphics.newImage("img/tile_sand_1.png"))
	table.insert(tileGraphics, love.graphics.newImage("img/tile_sand_wasser_1.png"))
	table.insert(tileGraphics, love.graphics.newImage("img/tile_bridge.png"))


	UIManager:init()
	PlayerManager:startGame()
end

function love.update(dt)
	Time:update(dt)
	UIManager:update()

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
	local x, y = PlayerManager.map:tileToPixel(0, 0)
	love.graphics.draw(background, x - 1000, y - 1000)
	if PlayerManager.map then
		PlayerManager.map:draw()
	end
	if highlightedTile then
		highlightedTile:draw()
	end
	if PlayerManager.initDone then
		PlayerManager:draw()
	end
	camera:unset()

	UIManager:draw()
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
	elseif key == "g" then
		PlayerManager:startGame()
	end
end

function love.mousemoved( x, y, dx, dy, istouch )
	updateMousePosition(x, y)
end

function love.mousepressed(x, y, button, isTouch)
	if not UIManager:mouseClickEvent(x, y) then
		local clickTile = PlayerManager.map:pixelToTile(x, y)
		print("Q: " .. tostring(clickTile.ax) .. ", R: " .. tostring(clickTile.ay))
	end
end

function updateMousePosition(x, y)
	if x == nil or y == nil then
		print("nil")
		return 
	end
	x = x * camera.scaleX + camera.x
	y = y * camera.scaleY + camera.y 
	--local returnTile = PlayerManager.map:pixelToTile(x, y)
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
