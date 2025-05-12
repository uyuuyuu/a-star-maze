-- A* pathfinding demo (with step recording)
-- Maze dimensions (must be odd)
local maze_width, maze_height = 128, 72
local width, height = maze_width, maze_height

-- Constants
local WALL = 1
local PATH = 0

-- Initialize maze with all walls
local maze = {}
local function init_maze()
	 for y = 1, maze_height do
			maze[y] = {}
			for x = 1, maze_width do
				 maze[y][x] = WALL
			end
	 end
end

-- Check if position is within bounds
local function in_bounds(x, y)
    return x >= 1 and x <= maze_width and y >= 1 and y <= maze_height
end

-- Shuffle direction array
local function shuffle_directions(dirs)
    for i = #dirs, 2, -1 do
        local j = love.math.random(i)
        dirs[i], dirs[j] = dirs[j], dirs[i]
    end
end

-- Recursive maze generation
local function gen_maze(x, y)
    maze[y][x] = PATH

    local directions = {
        { dx = 0, dy = -1 }, -- up
        { dx = 0, dy = 1 },  -- down
        { dx = -1, dy = 0 }, -- left
        { dx = 1, dy = 0 }   -- right
    }
    shuffle_directions(directions)

    for _, dir in ipairs(directions) do
        local nx = x + dir.dx * 2
        local ny = y + dir.dy * 2
        if in_bounds(nx, ny) and maze[ny][nx] == WALL then
            maze[y + dir.dy][x + dir.dx] = PATH -- Remove wall between
            gen_maze(nx, ny)      -- Recurse
        end
    end
end

local cellSize = 15

local start = {x = 1, y = 1}
local goal  = {x = width - 1, y = height - 1}

-- local path = {}
-- local steps = {}
local step_index = 0
local path_found = false

local visible_steps = {}
local step_timer = 0
local step_delay = 0
local step_index = 0

-- Simple queue simulating a priority queue
local function insert_open(open, node)
    table.insert(open, node)
    table.sort(open, function(a, b) return a.f < b.f end)
end

local function heuristic(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

local function neighbors(p)
    local dirs = {
        {x = 0, y = -1}, {x = 0, y = 1},
        {x = -1, y = 0}, {x = 1, y = 0},
    }
    local result = {}
    for _, d in ipairs(dirs) do
        local nx, ny = p.x + d.x, p.y + d.y
        if nx >= 1 and nx <= width and ny >= 1 and ny <= height and maze[ny][nx] == 0 then
            table.insert(result, {x = nx, y = ny})
        end
    end
    return result
end

local function node_key(p)
    return p.x .. "," .. p.y
end

local function equal(a, b)
    return a.x == b.x and a.y == b.y
end

local function a_star(start, goal)
    local open = {}
    local visited = {}
    local came_from = {}
    local g_score = {}
    local f_score = {}

    local function key(n) return node_key(n) end

    g_score[key(start)] = 0
    f_score[key(start)] = heuristic(start, goal)
    insert_open(open, {node = start, g = 0, f = f_score[key(start)]})

    local search_steps = {}

    while #open > 0 do
        local current = table.remove(open, 1).node
        local ck = key(current)

        if equal(current, goal) then
            local total_path = {current}
            while came_from[ck] do
                current = came_from[ck]
                ck = key(current)
                table.insert(total_path, 1, current)
            end
            return total_path, search_steps
        end

        visited[ck] = true

        for _, neighbor in ipairs(neighbors(current)) do
            local nk = key(neighbor)
            if not visited[nk] then
                local tentative_g = g_score[ck] + 1
                if g_score[nk] == nil or tentative_g < g_score[nk] then
                    came_from[nk] = current
                    g_score[nk] = tentative_g
                    f_score[nk] = tentative_g + heuristic(neighbor, goal)
                    insert_open(open, {
                        node = neighbor,
                        g = g_score[nk],
                        f = f_score[nk]
                    })
                    table.insert(search_steps, {x = neighbor.x, y = neighbor.y})
                end
            end
        end
    end
    return nil, search_steps
end

-- Assumes path is the final path, steps are the search order
-- Build animation_steps: search steps first (blue), then path (green)
function build_animation_steps(path, steps)
    local animation_steps = {}
    -- local visited = {}

    -- Add search steps (blue)
		if steps then
			 for _, node in ipairs(steps) do
					table.insert(animation_steps, { node = node, color = { 0, 0, 1 } }) -- Blue
			 end
		end
    -- Add path steps (green), avoid duplicate drawing
		if path then
			 for i = #path, 1, -1 do
					local node = path[i]
					table.insert(animation_steps, { node = node, color = { 0, 1, 0 } }) -- Green
			 end
		end

    return animation_steps
end

local function resetGame()
	 math.randomseed(os.time())
	 init_maze()
	 gen_maze(1, 1)
	 revealed_path = {}
	 current_step_index = 0
	 step_timer = 0
	 local path, steps = a_star(start, goal)
	 animation_steps = build_animation_steps(path, steps)

	 step_index = 0
	 path_found = false
	 visible_steps = {}
	 step_timer = 0
	 step_delay = 0
	 step_index = 0
end

function love.load()
	 love.timer.sleep(15)
	 resetGame()
end

function love.update(dt)
    step_timer = step_timer + dt
    if step_index < #animation_steps and step_timer >= step_delay then
        step_index = step_index + 1
        table.insert(visible_steps, animation_steps[step_index])
        step_timer = 0
    end
		if step_index == #animation_steps then
			 love.timer.sleep(3)
			 resetGame()
		end
end

function love.draw()
    for y = 1, height do
        for x = 1, width do
            if maze[y][x] == 1 then
                love.graphics.setColor(0.2, 0.2, 0.2)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.rectangle("fill", (x-1)*cellSize, (y-1)*cellSize, cellSize, cellSize)
        end
    end

		-- Start and goal
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", (start.x-1)*cellSize, (start.y-1)*cellSize, cellSize, cellSize)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", (goal.x-1)*cellSize, (goal.y-1)*cellSize, cellSize, cellSize)

    -- Draw step-by-step path
    for _, s in ipairs(visible_steps) do
        local r, g, b = unpack(s.color)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", (s.node.x-1)*cellSize, (s.node.y-1)*cellSize, cellSize, cellSize)
    end
end

function love.keypressed(key)
    if key == "r" then
        resetGame()
    end
end
