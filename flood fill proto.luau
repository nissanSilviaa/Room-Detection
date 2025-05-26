local nodesFolder = workspace:WaitForChild("placeditems"):WaitForChild("nodes")
local stepSize = 4

-- Step 1: Collect nodes by grid position into lists (to handle duplicates)
local rawNodes = {}
for _, node in pairs(nodesFolder:GetChildren()) do
	if node:IsA("BasePart") then
		local pos = node.Position
		local key = string.format("%d,%d", pos.X, pos.Z)
		if not rawNodes[key] then
			rawNodes[key] = {}
		end
		table.insert(rawNodes[key], node)
	end
end

local function getNeighborKeys(x, z)
	return {
		string.format("%d,%d", x - stepSize, z),
		string.format("%d,%d", x + stepSize, z),
		string.format("%d,%d", x, z - stepSize),
		string.format("%d,%d", x, z + stepSize),
	}
end

local nodeMap = {}
for key, nodeList in pairs(rawNodes) do
	local x, z = key:match("([^,]+),([^,]+)")
	x, z = tonumber(x), tonumber(z)

	local neighbors = getNeighborKeys(x, z)
	local validNeighborCount = 0
	local seenPositions = {}

	for _, neighborKey in pairs(neighbors) do
		if rawNodes[neighborKey] and #rawNodes[neighborKey] > 0 then
			if not seenPositions[neighborKey] then
				validNeighborCount += 1
				seenPositions[neighborKey] = true
			end
		end
	end

	if validNeighborCount >= 2 then
		nodeMap[key] = nodeList[1] -- Use first node at that position
	end
end

-- Step 4: Visualize outcast (invalid) nodes
for key, nodeList in pairs(rawNodes) do
	if not nodeMap[key] then
		for _, node in pairs(nodeList) do
			local marker = Instance.new("Part")
			marker.Size = Vector3.new(2, 1, 2)
			marker.Position = node.Position + Vector3.new(0, 1, 0)
			marker.Anchored = true
			marker.BrickColor = BrickColor.new("Bright red")
			marker.Transparency = 0.2
			marker.Material = Enum.Material.Neon
			marker.CanCollide = false
			marker.Name = "OutcastMarker"
			marker.Parent = workspace
		end
	end
end

-- Step 5: Custom directional rectangle trace
local visited = {}
local groups = {}

local directions = {
	Vector2.new(stepSize, 0),
	Vector2.new(0, stepSize),
	Vector2.new(-stepSize, 0),
	Vector2.new(0, -stepSize),
}

local opposites = {
	["4,0"] = "-4,0", ["-4,0"] = "4,0",
	["0,4"] = "0,-4", ["0,-4"] = "0,4",
}

local function traceRectangle(startKey)
	local x, z = startKey:match("([^,]+),([^,]+)")
	x, z = tonumber(x), tonumber(z)

	for _, dir in ipairs(directions) do
		local dx, dz = dir.X, dir.Y
		local directionKey = dx .. "," .. dz
		local oppositeKey = opposites[directionKey]

		-- Step 1: Trace full line in first direction
		local line = {}
		local cx, cz = x, z

		while true do
			local key = cx .. "," .. cz
			if not nodeMap[key] or visited[key] then break end

			table.insert(line, {x = cx, z = cz})
			cx += dx
			cz += dz
		end

		-- Step 2: Try perpendicular directions from entire line
		for _, perpDir in ipairs(directions) do
			local pdx, pdz = perpDir.X, perpDir.Y
			local perpKey = pdx .. "," .. pdz

			if perpKey ~= directionKey and perpKey ~= oppositeKey then
				local fullGroup = {}
				local valid = true

				for _, pos in ipairs(line) do
					local px, pz = pos.x, pos.z

					while true do
						local key = px .. "," .. pz
						if nodeMap[key] and not visited[key] then
							table.insert(fullGroup, nodeMap[key])
							px += pdx
							pz += pdz
						else
							break
						end
					end

				end

				if #fullGroup >= 4 then
					-- Mark all as visited
					for _, part in ipairs(fullGroup) do
						local px = math.floor(part.Position.X / stepSize + 0.5)
						local pz = math.floor(part.Position.Z / stepSize + 0.5)
						visited[px .. "," .. pz] = true
					end
					return fullGroup
				end
			end
		end
	end

	return nil
end



-- Step 6: Run tracer on all nodes
for key in pairs(nodeMap) do
	if not visited[key] then
		local group = traceRectangle(key)
		if group then
			table.insert(groups, group)

			-- Print dimensions of the detected rectangle
			local minX, maxX = math.huge, -math.huge
			local minZ, maxZ = math.huge, -math.huge

			for _, node in ipairs(group) do
				local pos = node.Position
				minX = math.min(minX, pos.X)
				maxX = math.max(maxX, pos.X)
				minZ = math.min(minZ, pos.Z)
				maxZ = math.max(maxZ, pos.Z)
			end

			local sizeX = (maxX - minX) + stepSize
			local sizeZ = (maxZ - minZ) + stepSize

			print(string.format("Detected Room Size: (%.1f, 1, %.1f)", sizeX, sizeZ))
		end
	end
end


-- Step 7: Create parts for each group
for _, group in pairs(groups) do
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local centerY = group[1].Position.Y

	for _, node in pairs(group) do
		local pos = node.Position
		minX = math.min(minX, pos.X)
		maxX = math.max(maxX, pos.X)
		minZ = math.min(minZ, pos.Z)
		maxZ = math.max(maxZ, pos.Z)
	end

	local sizeX = math.floor((maxX - minX) / stepSize + 1)
	local sizeZ = math.floor((maxZ - minZ) / stepSize + 1)

	local centerX = math.floor((minX + maxX) / 2 / stepSize + 0.5) * stepSize
	local centerZ = math.floor((minZ + maxZ) / 2 / stepSize + 0.5) * stepSize
	local centerPosition = Vector3.new(centerX, centerY, centerZ)

	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new((sizeX * stepSize)-3.4, 1, (sizeZ * stepSize)-3.3)
	part.Position = centerPosition + Vector3.new(-0.45, part.Size.Y / 2, 1.95)
	part.BrickColor = BrickColor.Random()
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Name = "BuildZone"
	part.Parent = workspace
end
