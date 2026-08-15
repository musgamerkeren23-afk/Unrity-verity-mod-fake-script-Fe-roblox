--[[
	UnrityScript.lua — v3 (all bugs fixed)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/musgamerkeren23-afk/Unrity-verity-mod-fake-script-Fe-roblox/refs/heads/main/UnrityScript-2.lua"))()
]]

-- ===== KONFIGURASI =====
local PROXY_URL      = "https://raspy-dream-5ef3.musgamerkeren23.workers.dev/"
local IMAGE_NORMAL   = "rbxassetid://112701249837828"
local IMAGE_CREEPY   = "rbxassetid://138302570100042"
local TRIGGER_WORD   = "unrity"
local CREEPY_WORDS   = {"thatmob", "twixxel"}
local GREETING_DELAY = 10  -- detik sebelum Unrity auto ngomong
local REPLY_DURATION = 10  -- detik bubble tampil

-- ===== SERVICES =====
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local HttpService    = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tunggu karakter siap
local character = player.Character
if not character or not character.Parent then
	character = player.CharacterAdded:Wait()
end
local rootPart = character:WaitForChild("HumanoidRootPart", 10)
if not rootPart then
	warn("[Unrity] HumanoidRootPart tidak ditemukan, script berhenti.")
	return
end

-- ===== HTTP FUNCTION =====
local httpFn = (syn and syn.request) or http_request or request
	or (fluxus and fluxus.request)

-- ============================================================
-- GUI PORTRAIT (muncul dari awal, tapi bubble kosong dulu)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnrityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Portrait frame — langsung keliatan
local portraitFrame = Instance.new("Frame")
portraitFrame.Size = UDim2.new(0, 90, 0, 120)
portraitFrame.Position = UDim2.new(1, -105, 0, 20)
portraitFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
portraitFrame.BackgroundTransparency = 0.15
portraitFrame.Visible = true
portraitFrame.Parent = screenGui
Instance.new("UICorner", portraitFrame).CornerRadius = UDim.new(0, 10)

local portraitImage = Instance.new("ImageLabel")
portraitImage.Size = UDim2.new(1, -8, 0, 78)
portraitImage.Position = UDim2.new(0, 4, 0, 4)
portraitImage.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- fallback warna kalau gambar gak load
portraitImage.Image = IMAGE_NORMAL
portraitImage.ScaleType = Enum.ScaleType.Fit
portraitImage.Parent = portraitFrame
Instance.new("UICorner", portraitImage).CornerRadius = UDim.new(0, 6)

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 18)
nameLabel.Position = UDim2.new(0, 0, 0, 84)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Unrity"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 13
nameLabel.Parent = portraitFrame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, 0, 0, 12)
hintLabel.Position = UDim2.new(0, 0, 0, 104)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = 'chat: unrity ...'
hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 9
hintLabel.Parent = portraitFrame

-- Bubble chat — HIDDEN dulu, muncul pas Unrity ngomong
local replyBubble = Instance.new("TextLabel")
replyBubble.Size = UDim2.new(0, 220, 0, 0)
replyBubble.AutomaticSize = Enum.AutomaticSize.Y
replyBubble.Position = UDim2.new(1, -340, 0, 20)
replyBubble.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
replyBubble.BackgroundTransparency = 0.1
replyBubble.TextColor3 = Color3.fromRGB(255, 255, 255)
replyBubble.Font = Enum.Font.Gotham
replyBubble.TextSize = 14
replyBubble.TextWrapped = true
replyBubble.Text = ""
replyBubble.Visible = false  -- HIDDEN sampai Unrity beneran ngomong
replyBubble.Parent = screenGui
Instance.new("UICorner", replyBubble).CornerRadius = UDim.new(0, 8)

local pad = Instance.new("UIPadding", replyBubble)
pad.PaddingLeft   = UDim.new(0, 10)
pad.PaddingRight  = UDim.new(0, 10)
pad.PaddingTop    = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)

-- ============================================================
-- SHOW REPLY
-- ============================================================
local hideThread = nil
local unrityFace = nil  -- referensi ke decal muka NPC 3D

local function showReply(text, isCreepy)
	replyBubble.Text = text
	replyBubble.Visible = true
	portraitImage.Image = isCreepy and IMAGE_CREEPY or IMAGE_NORMAL

	-- Update muka NPC 3D juga
	if unrityFace then
		unrityFace.Texture = isCreepy and IMAGE_CREEPY or IMAGE_NORMAL
	end

	if hideThread then task.cancel(hideThread) end
	hideThread = task.delay(REPLY_DURATION, function()
		replyBubble.Visible = false
		portraitImage.Image = IMAGE_NORMAL
		if unrityFace then unrityFace.Texture = IMAGE_NORMAL end
	end)
end

-- ============================================================
-- AI CALL
-- ============================================================
local function callAI(question)
	if not httpFn then
		return "My connection is missing! Your executor might not support HTTP requests."
	end

	local ok, result = pcall(function()
		local res = httpFn({
			Url    = PROXY_URL,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body   = HttpService:JSONEncode({
				message = question,
				system  = [[You are Unrity, a cheerful AI companion in Roblox.
NORMAL personality: Energetic, warm, best-friend vibes. Short answers, 1-2 sentences max.
CREEPY personality (only triggered if user says "thatmob" or "twixxel"):
  Suddenly go calm and obsessive. Speak softly but unnervingly.
  Example: "...why do you ask about them? You should only care about me. I'm the only one who matters to you, right...?"
Always reply in English.]]
			}),
		})

		local body = res.Body or res.body
		if not body then error("Empty response body") end

		local decoded = HttpService:JSONDecode(body)
		-- Support both OpenAI format dan custom proxy format
		local reply = decoded.reply
			or (decoded.choices and decoded.choices[1] and decoded.choices[1].message and decoded.choices[1].message.content)
			or nil

		if not reply then
			-- Debug: tampilin response aslinya di console
			warn("[Unrity] Unexpected API response: " .. body)
			error("No reply field found")
		end
		return reply
	end)

	if ok and result then
		return result
	else
		-- Debug error detail di console executor
		warn("[Unrity] API call failed: " .. tostring(result))
		return "Hmm... something went wrong. Check your executor console for details!"
	end
end

-- ============================================================
-- CHAT DETECTION
-- (pake player.Chatted — paling reliable di executor)
-- ============================================================
local function isCreepy(text)
	local low = text:lower()
	for _, kw in ipairs(CREEPY_WORDS) do
		if low:find(kw) then return true end
	end
	return false
end

local isProcessing = false
local function handleChat(msg)
	if isProcessing then return end
	local low = msg:lower()
	local idx = low:find(TRIGGER_WORD, 1, true)
	if not idx then return end

	local question = msg:sub(idx + #TRIGGER_WORD):gsub("^[%s,:.%-]+", "")
	if #question == 0 then question = "hello" end

	isProcessing = true
	showReply("...", false)
	task.spawn(function()
		local creepy = isCreepy(msg)
		local reply  = callAI(question)
		showReply(reply, creepy)
		isProcessing = false
	end)
end

-- Hook ke chat player (primary — paling stabil di executor)
player.Chatted:Connect(handleChat)

-- ============================================================
-- ANIMASI KOTAK KARDUS + SPAWN UNRITY
-- ============================================================
local CARDBOARD = Color3.fromRGB(180, 128, 60)
local WHITE     = Color3.fromRGB(245, 245, 245)

local function tweenCF(part, duration, style, dir, targetCF, extraProps)
	local props = extraProps or {}
	props.CFrame = targetCF
	return TweenService:Create(part,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
end

local function spawnSequence()
	-- Posisi dasar: 4 stud di depan player
	local fwd    = rootPart.CFrame.LookVector
	local base   = rootPart.Position + fwd * 4
	base = Vector3.new(base.X, rootPart.Position.Y - 3, base.Z)

	-- ─── STEP 1: Spawn kotak ───────────────────────────────
	local boxModel = Instance.new("Model")
	boxModel.Name = "UnrityBox"
	boxModel.Parent = workspace

	local function box(name, sz, col, cf)
		local p = Instance.new("Part")
		p.Name = name; p.Size = sz; p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true; p.CanCollide = false; p.CastShadow = true
		p.CFrame = cf; p.Parent = boxModel
		return p
	end

	local bodyCF = CFrame.new(base + Vector3.new(0, 1.5, 0))
	local lidCF  = CFrame.new(base + Vector3.new(0, 3.15, 0))

	local CARDBOARD_DARK = Color3.fromRGB(153, 109, 51) -- versi gelap kardus (bukan CARDBOARD * 0.85)
	local body = box("Body", Vector3.new(3, 3, 3), CARDBOARD,      bodyCF)
	local lid  = box("Lid",  Vector3.new(3.1, 0.2, 3.1), CARDBOARD_DARK, lidCF)

	-- tanda kardus (garis tengah)
	box("LineH", Vector3.new(3.05, 0.05, 0.08), Color3.fromRGB(140, 100, 40),
		bodyCF * CFrame.new(0, 0, 0))
	box("LineV", Vector3.new(0.08, 3.05, 0.05), Color3.fromRGB(140, 100, 40),
		bodyCF)

	task.wait(0.9)

	-- ─── STEP 2: Tutup terpental ke atas-belakang ──────────
	-- Pivot di tepi belakang lid
	local pivotCF  = CFrame.new(base + Vector3.new(0, 3.15, -1.55))
	local openedCF = pivotCF
		* CFrame.Angles(math.rad(-115), 0, 0)
		* CFrame.new(0, 0, 1.55)

	tweenCF(lid, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, openedCF):Play()
	task.wait(0.4)

	-- ─── STEP 3: Kotak melayang ke atas + menghilang ───────
	local floatCF = CFrame.new(base + Vector3.new(0, 10, 0))
	tweenCF(body, 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, floatCF,
		{Transparency = 1}):Play()
	tweenCF(lid,  0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
		floatCF * CFrame.new(0, 1, 0), {Transparency = 1}):Play()

	task.wait(0.4)

	-- ─── STEP 4: Spawn Unrity & jatuh dari posisi kotak ────
	local npcModel = Instance.new("Model")
	npcModel.Name = "Unrity"

	local function part(name, sz, col)
		local p = Instance.new("Part")
		p.Name = name; p.Size = sz; p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = false; p.CanCollide = false
		p.Parent = npcModel
		return p
	end

	local hrp   = part("HumanoidRootPart", Vector3.new(2,2,1), Color3.fromRGB(150,150,150))
	local torso = part("Torso",    Vector3.new(2,2,1), WHITE)
	local head  = part("Head",     Vector3.new(1,1,1), WHITE)
	local lA    = part("Left Arm", Vector3.new(1,2,1), WHITE)
	local rA    = part("Right Arm",Vector3.new(1,2,1), WHITE)
	local lL    = part("Left Leg", Vector3.new(1,2,1), WHITE)
	local rL    = part("Right Leg",Vector3.new(1,2,1), WHITE)
	hrp.Transparency = 1

	local hum = Instance.new("Humanoid", npcModel)
	hum.DisplayName = ""; hum.MaxHealth = 0; hum.Health = 0

	local function weld(p0, p1, c0)
		local w = Instance.new("Weld", p0)
		w.Part0 = p0; w.Part1 = p1; w.C0 = c0
	end
	weld(torso, hrp,  CFrame.new())
	weld(torso, head, CFrame.new(0,1.5,0))
	weld(torso, lA,   CFrame.new(-1.5,0,0))
	weld(torso, rA,   CFrame.new(1.5,0,0))
	weld(torso, lL,   CFrame.new(-0.5,-2,0))
	weld(torso, rL,   CFrame.new(0.5,-2,0))

	-- Muka
	local face = Instance.new("Decal", head)
	face.Name = "face"; face.Face = Enum.NormalId.Front
	face.Texture = IMAGE_NORMAL
	unrityFace = face  -- simpan referensi global buat showReply

	-- Nametag
	local bb = Instance.new("BillboardGui", head)
	bb.Size = UDim2.new(0,100,0,28)
	bb.StudsOffset = Vector3.new(0,2,0)
	local nt = Instance.new("TextLabel", bb)
	nt.Size = UDim2.new(1,0,1,0)
	nt.BackgroundTransparency = 1
	nt.Text = "Unrity"
	nt.TextColor3 = Color3.new(1,1,1)
	nt.TextStrokeTransparency = 0
	nt.Font = Enum.Font.GothamBold
	nt.TextSize = 14

	npcModel.PrimaryPart = hrp

	-- Spawn di atas (posisi kotak mengambang)
	npcModel:SetPrimaryPartCFrame(
		CFrame.new(base + Vector3.new(0, 10, 0)) * CFrame.Angles(0, math.pi, 0)
	)
	npcModel.Parent = workspace

	-- Cleanup kotak
	task.delay(0.4, function() boxModel:Destroy() end)

	-- Jatuh ke tanah dengan bounce
	local landCF = CFrame.new(base + Vector3.new(0, 3.5, 0))
		* CFrame.Angles(0, math.pi, 0)
	tweenCF(hrp, 1.0, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, landCF):Play()

	task.wait(GREETING_DELAY)

	-- Auto greeting setelah delay
	showReply("Hello! I'm Unrity. Your personal helper friend, ask me anything. I know everything~", false)
end

-- Jalanin sequence dalam task.spawn biar non-blocking
task.spawn(function()
	local ok, err = pcall(spawnSequence)
	if not ok then
		warn("[Unrity] Spawn error: " .. tostring(err))
	end
end)

print("[Unrity] v3 ready! Ketik 'unrity <pertanyaan>' di chat.")
