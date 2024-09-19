local love = love

-- controlling constants
MODE = "auto" -- auto or manual
SCALE = 1
BALL_RADIUS = 15 * SCALE
NUM_ROWS = 11
NUM_PINS_EVEN = 10
NUM_PINS_ODD = 11

-- pin constants
PIN_RADIUS = BALL_RADIUS / 1.5
DISTANCE_BETWEEN_PINS = BALL_RADIUS * 4 + PIN_RADIUS * 2
DISTANCE_BETWEEN_ROWS = BALL_RADIUS * 4

ballX = 0
current_run = ""


-- bin constants
NUM_BINS = NUM_PINS_ODD
BIN_HEIGHT = 10
BIN_SEPERATOR_WIDTH = PIN_RADIUS * 2
BIN_SEPERATOR_HEIGHT = BALL_RADIUS * 4
BIN_WIDTH = 4 * BALL_RADIUS + PIN_RADIUS * 2

-- walls
WALL_WIDTH = BIN_SEPERATOR_WIDTH
WALL_SEGMENT_WIDTH = DISTANCE_BETWEEN_PINS / 2 - PIN_RADIUS
WALL_SEGMENT_HEIGHT = DISTANCE_BETWEEN_ROWS - BALL_RADIUS

WORLD_WIDTH = 2 * WALL_WIDTH + NUM_BINS * BIN_WIDTH + (NUM_BINS - 1) * BIN_SEPERATOR_WIDTH + WALL_SEGMENT_WIDTH * 2
WORLD_HEIGHT = (NUM_ROWS + 3) * DISTANCE_BETWEEN_ROWS + BIN_SEPERATOR_HEIGHT


--
PREGAME_STATE = "PG"
INGAME_STATE = "IG"
POSTGAME_STATE = "PO"
CURRENT_STATE = PREGAME_STATE
if MODE == "auto" then
	CURRENT_STATE = POSTGAME_STATE
end

-- objects
bins = {}
pins = {}
seperators = {}
seperatorPins = {}
walls = {}
wallSegments = {}
ball = {}
scores = {}
for i = 1, NUM_BINS + 1, 1 do
	scores["bin" .. i] = 0
end

function createWallSegment(y, side)
	local height = WALL_SEGMENT_HEIGHT
	local width = WALL_SEGMENT_WIDTH

	if side == "left" then
		local body = love.physics.newBody(world, WALL_WIDTH, y, "static")
		local shape = love.physics.newPolygonShape(0, -height, width, 0, 0, height) -- Triangle vertices
		local fixture = love.physics.newFixture(body, shape)
		fixture:setUserData("wall")
		table.insert(walls, { body = body, shape = shape, fixture = fixture })
	elseif side == "right" then
		local body = love.physics.newBody(world, WORLD_WIDTH - WALL_WIDTH, y, "static")
		local shape = love.physics.newPolygonShape(0, -height, -width, 0, 0, height) -- Triangle vertices
		local fixture = love.physics.newFixture(body, shape)
		fixture:setUserData("wall")
		table.insert(walls, { body = body, shape = shape, fixture = fixture })
	end
end

local function createBinSeperator(x, y)
	local body = love.physics.newBody(world, x + BIN_SEPERATOR_WIDTH / 2, y - BIN_SEPERATOR_HEIGHT / 2, "static")
	local shape = love.physics.newRectangleShape(BIN_SEPERATOR_WIDTH, BIN_SEPERATOR_HEIGHT)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setUserData("sep")
	return { body = body, shape = shape, fixture = fixture }
end


local function createBinGround(x, y, width, owner, binNum)
	local body = love.physics.newBody(world, x + width / 2, y - BIN_HEIGHT / 2, "static")
	local shape = love.physics.newRectangleShape(width, BIN_HEIGHT)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setUserData("bin" .. binNum)
	return { body = body, shape = shape, fixture = fixture, owner = owner, value = 50 }
end

local function createBin(x, y, width, owner, binNum)
	local bin = createBinGround(x, y, width, owner, binNum)
	table.insert(bins, bin)
	local sep = createBinSeperator(x + width, y)
	table.insert(seperators, sep)
	local sepPin = createBinSeperatorPin(x + width + BIN_SEPERATOR_WIDTH / 2, y - BIN_SEPERATOR_HEIGHT, binNum)
	table.insert(seperatorPins, sepPin)
	return width + BIN_SEPERATOR_WIDTH
end

function createBinSeperatorPin(x, y, name)
	return createPin(x, y, "pinSep" .. name)
end

local function createLastBin(x, y, width, owner, binNum)
	local bin = createBinGround(x, y, width, owner, binNum)
	table.insert(bins, bin)
	return width
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

local function createBins(startX, startY, numBins)
	local x = startX
	local y = startY
	local j
	for i = 1, numBins - 1, 1 do
		local w = createBin(x, y, BIN_WIDTH, i + 1, i)
		x = x + w
		j = i
	end
	createLastBin(x, y, BIN_WIDTH, j + 2, j + 1)
end

local function drawBins()
	love.graphics.setColor(1, 0, 0)
	middle_bin = (NUM_PINS_EVEN / 2 + 2)
	for _, bin in ipairs(bins) do
		-- on the left side of the middle
		if bin.owner < middle_bin then
			if math.fmod(bin.owner, 2) == 1 then
				love.graphics.setColor(1, 0, 0)
			else
				love.graphics.setColor(0, 1, 0)
			end
		elseif bin.owner > middle_bin then
			if math.fmod(bin.owner, 2) == 1 then
				love.graphics.setColor(0, 1, 0)
			else
				love.graphics.setColor(1, 0, 0)
			end
		else
			love.graphics.setColor(0, 0, 1)
		end
		love.graphics.polygon("fill", bin.body:getWorldPoints(bin.shape:getPoints()))
	end


	love.graphics.setColor(0.5, 0, 0)
	for _, s in ipairs(seperators) do
		love.graphics.polygon("fill", s.body:getWorldPoints(s.shape:getPoints()))
	end
	drawSeperatorPins()
end


local function createWallBoundaries(wall_rect_width)
	local wall_rect_height = WORLD_HEIGHT
	local left_rect_start = 0
	local right_rect_start = NUM_BINS * BIN_WIDTH + (NUM_BINS - 1) * BIN_SEPERATOR_WIDTH + WALL_WIDTH * 2 +
		WALL_SEGMENT_WIDTH * 2

	local left_body = love.physics.newBody(world, left_rect_start + wall_rect_width / 2,
		wall_rect_height - wall_rect_height / 2, "static")
	local left_shape = love.physics.newRectangleShape(wall_rect_width, wall_rect_height)
	local left_fixture = love.physics.newFixture(left_body, left_shape)
	left_fixture:setUserData("leftwall")

	local right_body = love.physics.newBody(world, right_rect_start - wall_rect_width / 2,
		wall_rect_height - wall_rect_height / 2, "static")
	local right_shape = love.physics.newRectangleShape(wall_rect_width, wall_rect_height)
	local right_fixture = love.physics.newFixture(right_body, right_shape)
	right_fixture:setUserData("rightwall")

	local floor_body = love.physics.newBody(world, left_rect_start - wall_rect_width / 2,
		wall_rect_height + WALL_WIDTH / 2, "static")
	local floor_shape = love.physics.newRectangleShape(WORLD_WIDTH * 2 + WALL_WIDTH, WALL_WIDTH)
	local floor_fixture = love.physics.newFixture(floor_body, floor_shape)
	floor_fixture:setUserData("floor")

	table.insert(walls, { body = left_body, shape = left_shape, fixture = left_fixture })
	table.insert(walls, { body = right_body, shape = right_shape, fixture = right_fixture })
	table.insert(walls, { body = floor_body, shape = floor_shape, fixture = floor_fixture })
end

local function drawWalls()
	love.graphics.setColor(0.5, 0, 0)
	for _, wall in ipairs(walls) do
		love.graphics.polygon("fill", wall.body:getWorldPoints(wall.shape:getPoints()))
	end
end

local function printScores()
	for name, score in pairs(scores) do
		print(string.format("%10s | %d", name, score))
	end
end

local function getHeightOfFirstPinRow()
	return WORLD_HEIGHT / 6
end

function createPin(x, y, name)
	local body = love.physics.newBody(world, x, y, "static")
	local shape = love.physics.newCircleShape(PIN_RADIUS)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setUserData(name)
	fixture:setRestitution(0.4)
	return { body = body, shape = shape, fixture = fixture }
end

function createWallDividers(y, side)
	local x
	local height = y
	if side == "left" then
		x = WALL_WIDTH + WALL_SEGMENT_WIDTH
	elseif side == "right" then
		x = WORLD_WIDTH - WALL_SEGMENT_WIDTH
	end

	local body = love.physics.newBody(world, x - BIN_SEPERATOR_WIDTH / 2, height + ((WORLD_HEIGHT - y) / 2), "static")
	local shape = love.physics.newRectangleShape(BIN_SEPERATOR_WIDTH, WORLD_HEIGHT - y)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setUserData("wallsep")
	return { body = body, shape = shape, fixture = fixture }
end

local function createPins()
	local startingHeight = getHeightOfFirstPinRow()
	local y = startingHeight

	for row = 1, NUM_ROWS do
		if row % 2 == 1 then
			local x = WALL_WIDTH + BIN_WIDTH - PIN_RADIUS
			for j = 1, NUM_PINS_ODD do
				local pin = createPin(x, y, "pinR" .. row .. "C" .. j)
				table.insert(pins, pin)
				x = x + DISTANCE_BETWEEN_PINS + PIN_RADIUS * 2
			end
			-- even row
		else
			createWallSegment(y, "left")
			local x = WALL_WIDTH + BIN_WIDTH * 3 / 2 + BIN_SEPERATOR_WIDTH / 2 - PIN_RADIUS
			for j = 1, NUM_PINS_EVEN do
				local pin = createPin(x, y, "pinR" .. row .. "C" .. j)
				table.insert(pins, pin)
				x = x + DISTANCE_BETWEEN_PINS + PIN_RADIUS * 2
			end
			createWallSegment(y, "right")

			if row == NUM_ROWS - 1 then
				local a = createWallDividers(y, "left")
				table.insert(walls, a)
				a = createWallDividers(y, "right")
				table.insert(walls, a)
			end
		end
		y = y + DISTANCE_BETWEEN_ROWS
	end
end

local function drawPins()
	love.graphics.setColor(1, 0, 0)
	for _, pin in ipairs(pins) do
		love.graphics.circle("fill", pin.body:getX(), pin.body:getY(), pin.shape:getRadius())
	end
end

function drawSeperatorPins()
	love.graphics.setColor(0.5, 0, 0)
	for _, pin in ipairs(seperatorPins) do
		love.graphics.circle("fill", pin.body:getX(), pin.body:getY(), pin.shape:getRadius())
	end
end

local function createBall()
	ball.body = love.physics.newBody(world, love.graphics.getWidth() / 2, 0 + BALL_RADIUS, "dynamic")
	ball.shape = love.physics.newCircleShape(BALL_RADIUS)
	ball.fixture = love.physics.newFixture(ball.body, ball.shape)
	ball.fixture:setUserData("ball")
	-- ball.fixture:setRestitution(0.926)
	ball.fixture:setRestitution(0.49)
end

local function drawBall()
	love.graphics.setColor(0.76, 0.18, 0.05)
	love.graphics.circle("fill", ball.body:getX(),
		ball.body:getY(), ball.shape:getRadius())
end

function love.load()
	love.physics.setMeter(128)
	world = love.physics.newWorld(0, 9.81 * 64, true)
	love.graphics.setBackgroundColor(0.41, 0.53, 0.97)
	print("width: " .. WORLD_WIDTH)
	love.window.setMode(WORLD_WIDTH, 650)
	world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	createBins(0 + WALL_WIDTH + WALL_SEGMENT_WIDTH, WORLD_HEIGHT, NUM_BINS)
	createWallBoundaries(WALL_WIDTH)
	createPins()
	BALL_RADIUS = BALL_RADIUS - 0.5 -- make it slightly smaller so it doesnt get stuck
	createBall()
end

function love.draw()
	drawWalls()
	drawBins()
	drawBall()
	drawPins()
end

local function updatePreGame()
	if love.keyboard.isDown("right") then
		if ball.body:getX() + BALL_RADIUS < WORLD_WIDTH - WALL_WIDTH * 2 then
			ball.body:setX(ball.body:getX() + WORLD_WIDTH / 70)
		end
	elseif love.keyboard.isDown("left") then
		if ball.body:getX() - BALL_RADIUS > WALL_WIDTH * 2 then
			ball.body:setX(ball.body:getX() - WORLD_WIDTH / 70)
		end
	elseif love.keyboard.isDown("down") then
		CURRENT_STATE = INGAME_STATE
		ballX = ball.body:getX()
	end
end

local function updateScore(binName)
	-- for _, bin in ipairs(bins) do
	-- 	if binName == bin.fixture:getUserData() then
	-- 		print(bin.owner)
	-- 		print(string.format("user %s scores %d", bin.owner, bin.value))
	-- 		scores[bin.owner] = scores[bin.owner] + bin.value
	-- 	end
	-- end
	print(ballX .. " " .. binName)
	print(current_run)
	local f = io.open("result.dat", "a")
	io.output(f)
	io.write(ballX .. "," .. binName .. "," .. "'" .. current_run .. "'" .. "\n")
	io.close(f)
end

local function updateInGame(dt)
	world:update(dt)
	if love.keyboard.isDown("space") then
		CURRENT_STATE = PREGAME_STATE
		resetBall()
	end
end

function resetBall()
	ball.body:setPosition(WORLD_WIDTH / 2, 0 + BALL_RADIUS)
	ball.body:setLinearVelocity(0, 0)
end

function resetBallAuto()
	x = math.random(WALL_WIDTH + BALL_RADIUS, WORLD_WIDTH - BALL_RADIUS)
	ballX = x
	ball.body:setPosition(x, 0 + BALL_RADIUS)
	ball.body:setLinearVelocity(0, 0)
end

function updatePostGame()
	if MODE == "auto" then
		updatePostGameAuto()
	else
		if love.keyboard.isDown("space") then
			CURRENT_STATE = PREGAME_STATE
			resetBall()
		end
	end
end

function updatePostGameAuto()
	CURRENT_STATE = INGAME_STATE
	resetBallAuto()
	current_run = ""
end

function love.update(dt)
	if CURRENT_STATE == PREGAME_STATE then
		updatePreGame()
	elseif CURRENT_STATE == INGAME_STATE then
		updateInGame(dt)
	elseif CURRENT_STATE == POSTGAME_STATE then
		updatePostGame()
	end
end

function string.startsWith(str, prefix)
	return str:sub(1, #prefix) == prefix
end

local function checkForPostgameCondition(obj1, obj2)
	local a = obj1:getUserData()
	local b = obj2:getUserData()
	if a == "ball" and string.startsWith(b, "bin") then
		updateScore(b)
		CURRENT_STATE = POSTGAME_STATE
	elseif b == "ball" and string.startsWith(a, "bin") then
		updateScore(a)
		CURRENT_STATE = POSTGAME_STATE
	end
end

function beginContact(a, b, coll)
	checkForPostgameCondition(a, b)
	current_run = current_run .. a:getUserData() .. "|"
end

function endContact(a, b, coll)
end

function preSolve(a, b, coll)

end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)

end
