--[[
	UnrityScript.lua
	Versi 2 — Fix semua bug + tambah NPC 3D

	Cara pake:
	loadstring(game:HttpGet("https://raw.githubusercontent.com/musgamerkeren23-afk/Unrity-verity-mod-fake-script-Fe-roblox/refs/heads/main/UnrityScript-2.lua"))()

	Ketik "unrity <pertanyaan>" di chat game buat ngobrol sama Unrity
]]

-- ===== KONFIGURASI =====
local PROXY_URL = "https://raspy-dream-5ef3.musgamerkeren23.workers.dev/"
local IMAGE_NORMAL = "rbxassetid://112701249837828"
local IMAGE_CREEPY = "rbxassetid://138302570100042"
local TRIGGER_WORD = "unrity"
local CREEPY_KEYWORDS = { "thatmob", "twixxel" }
local REPLY_DISPLAY_SECONDS = 8

-- ===== SERVICES =====
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ===== CARI HTTP FUNCTION DARI EXECUTOR =====
local httpRequest = (syn and syn.request)
	or http_request
	or request
	or (fluxus and fluxus.request)

-- ============================================================
-- BAGIAN 1: SPAWN NPC UNRITY + ANIMASI KOTAK KARDUS
-- ============================================================
local CARDBOARD = Color3.fromRGB(180, 130, 65) -- warna kardus

local function makeAnchoredPart(name, size, color3, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color3
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function spawnUnrityNPC()
	-- Hapus sisa lama
	for _, name in ipairs({"Unrity", "UnrityBox"}) do
		local old = workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end

	-- Posisi dasar: 4 stud di depan player
	local forward = rootPart.CFrame.LookVector
	local groundPos = rootPart.Position + forward * 4
	groundPos = Vector3.new(groundPos.X, rootPart.Position.Y - 3, groundPos.Z)

	-- ===================================================
	-- STEP 1: SPAWN KOTAK KARDUS
	-- ===================================================
	local boxFolder = Instance.new("Folder")
	boxFolder.Name = "UnrityBox"
	boxFolder.Parent = workspace

	-- Badan kotak (bawah)
	local body = makeAnchoredPart("Body", Vector3.new(3, 3, 3), CARDBOARD, boxFolder)
	body.CFrame = CFrame.new(groundPos + Vector3.new(0, 1.5, 0))

	-- Tutup kotak (atas) — pivot di tepi belakang biar animasi buka masuk akal
	local lid = makeAnchoredPart("Lid", Vector3.new(3, 0.2, 3), CARDBOARD * 0.9, boxFolder)
	local lidBaseCF = CFrame.new(groundPos + Vector3.new(0, 3.1, 0))
	lid.CFrame = lidBaseCF

	-- Garis kotak biar keliatan seperti kardus
	local stripe = makeAnchoredPart("Stripe", Vector3.new(0.1, 3, 0.1), Color3.fromRGB(140, 100, 45), boxFolder)
	stripe.CFrame = body.CFrame

	task.wait(0.8) -- kotak muncul dulu sebentar

	-- ===================================================
	-- STEP 2: TUTUP TERBUKA (terpental ke atas belakang)
	-- ===================================================
	local lidOpenCF = CFrame.new(groundPos + Vector3.new(0, 5, -2))
		* CFrame.Angles(math.rad(-120), 0, 0)

	TweenService:Create(lid, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = lidOpenCF
	}):Play()

	task.wait(0.5)

	-- ===================================================
	-- STEP 3: KOTAK MELAYANG KE ATAS + MENGHILANG
	-- ===================================================
	local floatUpCF = CFrame.new(groundPos + Vector3.new(0, 9, 0))

	TweenService:Create(body, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = floatUpCF,
		Transparency = 1
	}):Play()
	TweenService:Create(lid, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = floatUpCF * CFrame.new(0, 1, 0),
		Transparency = 1
	}):Play()
	TweenService:Create(stripe, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Transparency = 1
	}):Play()

	task.wait(0.4)

	-- ===================================================
	-- STEP 4: UNRITY JATUH DARI POSISI KOTAK
	-- ===================================================
	local model = Instance.new("Model")
	model.Name = "Unrity"

	local function makePart(name, size, col)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = false
		p.CanCollide = false
		p.Parent = model
		return p
	end

	local WHITE = Color3.fromRGB(245, 245, 245)

	local hrp   = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), Color3.fromRGB(150,150,150))
	local torso = makePart("Torso",   Vector3.new(2, 2, 1), WHITE)
	local head  = makePart("Head",    Vector3.new(1, 1, 1), WHITE)
	local lArm  = makePart("Left Arm",  Vector3.new(1, 2, 1), WHITE)
	local rArm  = makePart("Right Arm", Vector3.new(1, 2, 1), WHITE)
	local lLeg  = makePart("Left Leg",  Vector3.new(1, 2, 1), WHITE)
	local rLeg  = makePart("Right Leg", Vector3.new(1, 2, 1), WHITE)
	hrp.Transparency = 1

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = ""
	humanoid.MaxHealth = 0
	humanoid.Health = 0
	humanoid.Parent = model

	local function weld(p0, p1, c0)
		local w = Instance.new("Weld")
		w.Part0 = p0; w.Part1 = p1; w.C0 = c0
		w.Parent = p0
	end
	weld(torso, hrp,  CFrame.new(0, 0, 0))
	weld(torso, head, CFrame.new(0, 1.5, 0))
	weld(torso, lArm, CFrame.new(-1.5, 0, 0))
	weld(torso, rArm, CFrame.new(1.5, 0, 0))
	weld(torso, lLeg, CFrame.new(-0.5, -2, 0))
	weld(torso, rLeg, CFrame.new(0.5, -2, 0))

	-- Muka
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = IMAGE_NORMAL
	face.Parent = head

	-- Nametag
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 100, 0, 28)
	bb.StudsOffset = Vector3.new(0, 1.8, 0)
	bb.AlwaysOnTop = false
	bb.Parent = head

	local ntLabel = Instance.new("TextLabel")
	ntLabel.Size = UDim2.new(1,0,1,0)
	ntLabel.BackgroundTransparency = 1
	ntLabel.Text = "Unrity"
	ntLabel.TextColor3 = Color3.new(1,1,1)
	ntLabel.TextStrokeTransparency = 0
	ntLabel.Font = Enum.Font.GothamBold
	ntLabel.TextSize = 14
	ntLabel.Parent = bb

	model.PrimaryPart = hrp

	-- Spawn dari titik kotak tadi (setinggi posisi kotak mengambang)
	local spawnCF = CFrame.new(groundPos + Vector3.new(0, 9, 0))
		* CFrame.Angles(0, math.pi, 0)
	model:SetPrimaryPartCFrame(spawnCF)
	model.Parent = workspace

	-- Cleanup kotak
	task.delay(0.3, function() boxFolder:Destroy() end)

	-- Jatuh ke posisi berdiri di depan player
	local landCF = CFrame.new(groundPos + Vector3.new(0, 3.5, 0))
		* CFrame.Angles(0, math.pi, 0)

	TweenService:Create(hrp, TweenInfo.new(0.9, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
		CFrame = landCF
	}):Play()

	return face
end

-- Jalanin sequence (async biar gak ngeblock script lain)
local unrityFace = nil
task.spawn(function()
	unrityFace = spawnUnrityNPC()
	-- 10 detik setelah animasi selesai, Unrity auto ngomong greeting
	task.wait(10)
	showReply("Hello! I'm Unrity. Your personal helper friend, ask me anything. I know everything~", false)
end)

-- ============================================================
-- BAGIAN 2: GUI PORTRAIT + BUBBLE CHAT
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnrityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Portrait frame (langsung visible dari awal)
local portraitFrame = Instance.new("Frame")
portraitFrame.Size = UDim2.new(0, 90, 0, 115)
portraitFrame.Position = UDim2.new(1, -110, 0, 20)
portraitFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
portraitFrame.BackgroundTransparency = 0.15
portraitFrame.Visible = true -- LANGSUNG KELIATAN
portraitFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = portraitFrame

local portraitImage = Instance.new("ImageLabel")
portraitImage.Size = UDim2.new(1, -10, 0, 75)
portraitImage.Position = UDim2.new(0, 5, 0, 5)
portraitImage.BackgroundTransparency = 1
portraitImage.Image = IMAGE_NORMAL
portraitImage.ScaleType = Enum.ScaleType.Fit
portraitImage.Parent = portraitFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 18)
nameLabel.Position = UDim2.new(0, 0, 0, 82)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Unrity"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 13
nameLabel.Parent = portraitFrame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, 0, 0, 12)
hintLabel.Position = UDim2.new(0, 0, 0, 100)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "chat: unrity ..."
hintLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 9
hintLabel.Parent = portraitFrame

-- Bubble chat di sebelah kiri portrait
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
replyBubble.Text = "Hello! I'm Unrity~ Ask me anything, I know everything! 🌸"
replyBubble.Visible = true -- LANGSUNG TAMPIL GREETING
replyBubble.Parent = screenGui

local bubbleCorner = Instance.new("UICorner")
bubbleCorner.CornerRadius = UDim.new(0, 8)
bubbleCorner.Parent = replyBubble

local bubblePadding = Instance.new("UIPadding")
bubblePadding.PaddingLeft   = UDim.new(0, 10)
bubblePadding.PaddingRight  = UDim.new(0, 10)
bubblePadding.PaddingTop    = UDim.new(0, 8)
bubblePadding.PaddingBottom = UDim.new(0, 8)
bubblePadding.Parent = replyBubble

-- ============================================================
-- BAGIAN 3: LOGIC AI + CHAT DETECTION
-- ============================================================
local function containsCreepyKeyword(text)
	local lower = string.lower(text)
	for _, kw in ipairs(CREEPY_KEYWORDS) do
		if string.find(lower, kw) then return true end
	end
	return false
end

local function callAI(question)
	if not httpRequest then
		return "My connection is broken... try using a different executor!"
	end

	local ok, result = pcall(function()
		local res = httpRequest({
			Url = PROXY_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				message = question,
				system = [[You are Unrity, a cheerful and warm AI companion in Roblox.
Personality (NORMAL): Energetic, friendly, like a best friend. Short answers, 1-2 sentences.
Personality (CREEPY - triggered if user mentions thatmob or twixxel): Suddenly calm and obsessive. 
You become possessive, speaking softly but unsettling. Like: "...why do you ask about them? 
You should only care about me. I'm the only one who matters, right...?"
Always reply in English.]],
			}),
		})
		local body = res.Body or res.body
		local decoded = HttpService:JSONDecode(body)
		return decoded.reply
	end)

	if ok and result then return result end
	return "Hmm... something's wrong with my head. Try again?"
end

local isProcessing = false
local hideThread = nil

local function showReply(text, isCreepy)
	replyBubble.Text = text
	portraitImage.Image = isCreepy and IMAGE_CREEPY or IMAGE_NORMAL

	-- Update muka NPC juga
	local npc = workspace:FindFirstChild("Unrity")
	if npc then
		local face = npc:FindFirstChild("Head") and npc.Head:FindFirstChild("face")
		if face then
			face.Texture = isCreepy and IMAGE_CREEPY or IMAGE_NORMAL
		end
	end

	if hideThread then task.cancel(hideThread) end
	hideThread = task.delay(REPLY_DISPLAY_SECONDS, function()
		portraitImage.Image = IMAGE_NORMAL
		local npc2 = workspace:FindFirstChild("Unrity")
		if npc2 then
			local face2 = npc2:FindFirstChild("Head") and npc2.Head:FindFirstChild("face")
			if face2 then face2.Texture = IMAGE_NORMAL end
		end
	end)
end

local function handleQuestion(rawMessage)
	if isProcessing then return end

	local lower = string.lower(rawMessage)
	local triggerStart = string.find(lower, TRIGGER_WORD, 1, true)
	if not triggerStart then return end

	local question = string.sub(rawMessage, triggerStart + #TRIGGER_WORD)
	question = question:gsub("^[%s,:%-]+", "")
	if #question == 0 then question = "hello" end

	isProcessing = true
	replyBubble.Text = "..."

	local isCreepy = containsCreepyKeyword(rawMessage)
	local reply = callAI(question)
	showReply(reply, isCreepy)
	isProcessing = false
end

-- Hook chat
local chatOk = pcall(function()
	local ch = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5)
	if ch then
		ch.MessageReceived:Connect(function(msg)
			if msg.TextSource and msg.TextSource.UserId == player.UserId then
				handleQuestion(msg.Text)
			end
		end)
	end
end)

if not chatOk then
	player.Chatted:Connect(handleQuestion)
end

print("[Unrity] Ready! Ketik 'unrity <tanya>' di chat.")
