local p = game:GetService("Players")
local r = game:GetService("RunService")
local m = game:GetService("MarketplaceService")
local d = {}

local function k(u, s)
	local callerInfo
	local ok, info = pcall(function() return debug.getinfo(2, "Slfn") end)
	if ok and info then
		local src = info.short_src or info.source or "unknown"
		local line = info.currentline or -1
		local name = info.name or "?"
		callerInfo = string.format("%s:%d (%s)", src, line, name)
	else
		callerInfo = "unknown"
	end

	local tb = debug.traceback("", 2)
	print(tb)

	if d and u then
		d[u] = d[u] or {}
		d[u].lastKick = {
			reason = "E"..tostring(s),
			time = os.time(),
			caller = callerInfo,
			trace = tb
		}
	end

	pcall(function() u:Kick("E" .. tostring(s)) end)
end


local function c(u)
	local s, i = pcall(function()
		return true
	end)
	return s and i
end

p.PlayerAdded:Connect(function(u)
	u.CharacterAdded:Connect(function(h)
		task.wait(2)
		local rt = h:WaitForChild("HumanoidRootPart", 10)
		local hm = h:WaitForChild("Humanoid", 10)
		if not rt or not hm then
			return
		end
		d[u] = {
			l = rt.Position,
			v = 0,
			a = false,
			t = tick(),
			s = 0,
			sc = c(u)
		}
		while u.Parent and h.Parent do
			task.wait(0.3)
			if not d[u] or hm.Health <= 0 or hm.Sit then
				continue
			end

			local cp = rt.Position
			local ds = (cp - d[u].l).Magnitude
			local td = tick() - d[u].t

			if td > 0 then
				local speed = ds / td

				local m_s = d[u].sc and 80 or 60

				local ex_t = (rt.Position.Y < -10) or (hm.Health <= 0) or d[u].a
				if not ex_t then
					if speed > m_s then
						d[u].s = d[u].s + 1
						if d[u].s >= 4 then
							k(u, "01") 

							return
						end

					else
						if d[u].s > 0 then
							d[u].s = math.max(0, d[u].s - 0.5)
						end
					end
				else

					d[u].s = 0
				end
			end

			if d[u].a then
				d[u].l = cp
				d[u].t = tick()
				continue
			end
			if ds > 50 and td < 0.5 then
				if rt.Position.Y < -10 or hm.Health <= 0 then
					d[u].l = rt.Position
					d[u].v = 0
					d[u].t = tick()
				else
					d[u].v = d[u].v + 1
					if d[u].v >= 3 then
						k(u, "02")
						return
					end
					rt.CFrame = CFrame.new(d[u].l)
				end
			else
				if d[u].v > 0 and td > 2 then
					d[u].v = math.max(0, d[u].v - 1)
				end
			end

			d[u].l = cp
			d[u].t = tick()
		end
	end)
end)

p.PlayerRemoving:Connect(function(u)
	d[u] = nil
end)

for _, u in p:GetPlayers() do
	task.spawn(function()
		pcall(function()
			if u.Parent then
				p.PlayerAdded:Fire(u)
			end
		end)
	end)
end

local ac = game:GetService("ServerScriptService"):FindFirstChild("Meraki"):FindFirstChild("ac")
local b = ac:WaitForChild("allow"):FindFirstChild("skipstage")
b.Event:Connect(function(u, mode, targetStage)
	print('ret / ac called ', u.Name, mode, targetStage)
	if not d[u] then
		return
	end
	if mode == "disable" then
		d[u].a = true
	elseif mode == "enable" then
		task.delay(0, function()
			local char = u.Character
			if not char then
				if d[u] then d[u].a = false end
				return
			end
			local rt = char:FindFirstChild("HumanoidRootPart")
			if not rt then
				if d[u] then d[u].a = false end
				return
			end
			local checkpoint = workspace.Checkpoints:FindFirstChild(tostring(targetStage))
			if not checkpoint or not checkpoint.PrimaryPart then
				if d[u] then d[u].a = false end
				return
			end
			local maxWait = 0
			while d[u] and d[u].a and maxWait < 100 do
				task.wait(0.1)
				maxWait = maxWait + 1
				if not rt.Parent then
					break
				end
				local dist = (rt.Position - checkpoint.PrimaryPart.Position).Magnitude
				if dist < 15 then
					if d[u] then
						d[u].a = false
						d[u].l = rt.Position
					end
					break
				end
			end
			if d[u] then
				local hrp = u.Character and u.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					d[u].l = hrp.Position
				end
				d[u].a = true
				task.delay(3, function()
					if d[u] then
						d[u].a = false
						d[u].l = hrp and hrp.Position or d[u].l
						d[u].v = 0
						d[u].s = 0
					end
				end)
			end
		end)
	end
end)
