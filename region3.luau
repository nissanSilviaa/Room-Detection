local nodesFolder = workspace:WaitForChild("placeditems"):WaitForChild("nodes")
local stepSize = 4

-- Gather all node parts into a map
local nodeMap = {}
for _, node in pairs(nodesFolder:GetChildren()) do
	if node:IsA("BasePart") then
		local x = math.round(node.Position.X / stepSize)
		local z = math.round(node.Position.Z / stepSize)
		local key = x .. "," .. z
		nodeMap[key] = node
	end
end

local visited = {}
local groups = {}

-- Helper to build Region3 from 2 Vector3 points
local function createRegion3FromBounds(minVec, maxVec)
	local size = maxVec - minVec
	local center = minVec + size / 2
	return Region3.new(minVec, maxVec):ExpandToGrid(stepSize)
end

-- Main detection loop
for key, node in pairs(nodeMap) do
	if not visited[key] then
		local origin = node.Position
		local minBound = origin - Vector3.new(16, 10, 16)
		local maxBound = origin + Vector3.new(16, 10, 16)
		local region = createRegion3FromBounds(minBound, maxBound)

		local partsInRegion = workspace:GetPartBoundsInBox(region.CFrame, region.Size)

		local group = {}
		local groupKeyMap = {}

		for _, part in ipairs(partsInRegion) do
			if part:IsA("BasePart") and part:IsDescendantOf(nodesFolder) then
				local x = math.round(part.Position.X / stepSize)
				local z = math.round(part.Position.Z / stepSize)
				local partKey = x .. "," .. z
				if nodeMap[partKey] and not visited[partKey] then
					visited[partKey] = true
					groupKeyMap[partKey] = true
					table.insert(group, part)
				end
			end
		end

		if #group >= 3 then
			table.insert(groups, group)
			local roomColor = BrickColor.Random()
			for _, part in ipairs(group) do
				part.BrickColor = roomColor
			end
			-- Debug: Print detected room size
			local minX, maxX = math.huge, -math.huge
			local minZ, maxZ = math.huge, -math.huge
			for _, p in ipairs(group) do
				minX = math.min(minX, p.Position.X)
				maxX = math.max(maxX, p.Position.X)
				minZ = math.min(minZ, p.Position.Z)
				maxZ = math.max(maxZ, p.Position.Z)
			end
			local sizeX = (maxX - minX) + stepSize
			local sizeZ = (maxZ - minZ) + stepSize
			print(string.format("Detected Room Size: (%.1f, 1, %.1f)", sizeX, sizeZ))
		end
	end
end

-- Visualize each room
for _, group in ipairs(groups) do
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local y = group[1].Position.Y

	for _, node in ipairs(group) do
		local pos = node.Position
		minX = math.min(minX, pos.X)
		maxX = math.max(maxX, pos.X)
		minZ = math.min(minZ, pos.Z)
		maxZ = math.max(maxZ, pos.Z)
	end

	local sizeX = (maxX - minX) + stepSize
	local sizeZ = (maxZ - minZ) + stepSize
	local center = Vector3.new((minX + maxX)/2, y, (minZ + maxZ)/2)

	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(sizeX-3.4, 1, sizeZ-3.4)
	part.Position = center + Vector3.new(0, 0.5, 0)
	part.BrickColor = BrickColor.Random()
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Name = "BuildZone"
	part.Parent = workspace
end
