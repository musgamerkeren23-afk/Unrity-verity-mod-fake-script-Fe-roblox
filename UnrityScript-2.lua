--[[
	UnrityScript.lua — v4
	Bola kuning persis Verity asli (thatmob), muka digambar GUI, gak ada body.
	loadstring(game:HttpGet("https://raw.githubusercontent.com/musgamerkeren23-afk/Unrity-verity-mod-fake-script-Fe-roblox/refs/heads/main/UnrityScript-2.lua"))()
	Ketik "unrity <pertanyaan>" di chat buat ngobrol.
]]

-- ===== KONFIGURASI =====
local PROXY_URL      = "https://raspy-dream-5ef3.musgamerkeren23.workers.dev/"
local VERITY_YELLOW  = Color3.fromRGB(255, 218, 40)
local TRIGGER_WORD   = "verity"
local CREEPY_WORDS   = {"thatmob", "twixxel"}
local GREETING_DELAY = 10
local REPLY_DURATION = 10

-- ===== SERVICES =====
local Players     = game:GetService("Players")
local TweenService= game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local character = player.Character
if not character or not character.Parent then
	character = player.CharacterAdded:Wait()
end
local rootPart = character:WaitForChild("HumanoidRootPart", 10)
if not rootPart then warn("[Unrity] HumanoidRootPart gak ketemu.") return end

local httpFn = (syn and syn.request) or http_request or request
	or (fluxus and fluxus.request)

-- ============================================================
-- HELPER: GAMBAR MUKA VERITY DI CONTAINER
-- ============================================================
-- Dibuat dari Frame Roblox biasa, gak butuh gambar apapun.
-- Normal: 2 mata bulat + senyum tipis melengkung
-- Creepy: mata lebih lebar + senyum lebar dengan gigi

local function makeFace(parent)
	-- Mata kiri
	local eL = Instance.new("Frame", parent)
	eL.Name = "EyeL"
	eL.Size = UDim2.new(0.13, 0, 0.13, 0)
	eL.Position = UDim2.new(0.24, 0, 0.28, 0)
	eL.BackgroundColor3 = Color3.new(0, 0, 0)
	eL.BorderSizePixel = 0
	Instance.new("UICorner", eL).CornerRadius = UDim.new(1, 0)

	-- Mata kanan
	local eR = eL:Clone()
	eR.Name = "EyeR"
	eR.Position = UDim2.new(0.63, 0, 0.28, 0)
	eR.Parent = parent

	-- Senyum (melengkung pake clip technique)
	local smileClip = Instance.new("Frame", parent)
	smileClip.Name = "SmileClip"
	smileClip.Size = UDim2.new(0.58, 0, 0.22, 0)
	smileClip.Position = UDim2.new(0.21, 0, 0.58, 0)
	smileClip.BackgroundTransparency = 1
	smileClip.ClipsDescendants = true
	smileClip.BorderSizePixel = 0

	-- Lingkaran hitam besar yg di-clip → kelihatan setengah bawahnya = senyum
	local smileArc = Instance.new("Frame", smileClip)
	smileArc.Name = "Arc"
	smileArc.Size = UDim2.new(1, 0, 2.2, 0)
	smileArc.Position = UDim2.new(0, 0, -1, 0)
	smileArc.BackgroundColor3 = Color3.new(0, 0, 0)
	smileArc.BorderSizePixel = 0
	Instance.new("UICorner", smileArc).CornerRadius = UDim.new(0.5, 0)

	-- Bagian dalam (kuning) buat bikin efek outline arc, bukan kotak penuh
	local smileInner = Instance.new("Frame", smileClip)
	smileInner.Name = "Inner"
	smileInner.Size = UDim2.new(0.76, 0, 1.8, 0)
	smileInner.Position = UDim2.new(0.12, 0, -0.85, 0)
	smileInner.BackgroundColor3 = VERITY_YELLOW
	smileInner.BorderSizePixel = 0
	smileInner.ZIndex = 2
	Instance.new("UICorner", smileInner).CornerRadius = UDim.new(0.5, 0)

	-- Gigi (tersembunyi di mode normal)
	local teeth = Instance.new("Frame", smileClip)
	teeth.Name = "Teeth"
	teeth.Size = UDim2.new(1, 0, 0.55, 0)
	teeth.Position = UDim2.new(0, 0, 0.45, 0)
	teeth.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	teeth.BorderSizePixel = 0
	teeth.ZIndex = 3
	teeth.Visible = false
	for i = 0, 4 do
		local gap = Instance.new("Frame", teeth)
		gap.Size = UDim2.new(0.04, 0, 1, 0)
		gap.Position = UDim2.new(0.17 * i + 0.01, 0, 0, 0)
		gap.BackgroundColor3 = Color3.new(0, 0, 0)
		gap.BorderSizePixel = 0
		gap.ZIndex = 4
	end

	return { eL=eL, eR=eR, smileClip=smileClip, smileInner=smileInner, teeth=teeth }
end

local function setExpression(refs, isCreepy)
	if not refs then return end
	if isCreepy then
		refs.eL.Size = UDim2.new(0.17, 0, 0.17, 0)
		refs.eR.Size = UDim2.new(0.17, 0, 0.17, 0)
		refs.smileClip.Size = UDim2.new(0.82, 0, 0.28, 0)
		refs.smileClip.Position = UDim2.new(0.09, 0, 0.55, 0)
		refs.smileInner.Visible = false  -- gigi kelihatan semua
		refs.teeth.Visible = true
	else
		refs.eL.Size = UDim2.new(0.13, 0, 0.13, 0)
		refs.eR.Size = UDim2.new(0.13, 0, 0.13, 0)
		refs.smileClip.Size = UDim2.new(0.58, 0, 0.22, 0)
		refs.smileClip.Position = UDim2.new(0.21, 0, 0.58, 0)
		refs.smileInner.Visible = true
		refs.teeth.Visible = false
	end
end

-- ============================================================
-- GUI PORTRAIT (pojok kanan atas)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnrityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local portraitFrame = Instance.new("Frame")
portraitFrame.Size = UDim2.new(0, 90, 0, 120)
portraitFrame.Position = UDim2.new(1, -105, 0, 20)
portraitFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
portraitFrame.BackgroundTransparency = 0.15
portraitFrame.Visible = true
portraitFrame.Parent = screenGui
Instance.new("UICorner", portraitFrame).CornerRadius = UDim.new(0, 10)

-- Wajah di portrait (lingkaran kuning Verity)
local portraitFace = Instance.new("Frame", portraitFrame)
portraitFace.Size = UDim2.new(1, -10, 0, 76)
portraitFace.Position = UDim2.new(0, 5, 0, 4)
portraitFace.BackgroundColor3 = VERITY_YELLOW
portraitFace.BorderSizePixel = 0
Instance.new("UICorner", portraitFace).CornerRadius = UDim.new(0.5, 0)
local portraitFaceRefs = makeFace(portraitFace)

local nameLabel = Instance.new("TextLabel", portraitFrame)
nameLabel.Size = UDim2.new(1, 0, 0, 18)
nameLabel.Position = UDim2.new(0, 0, 0, 82)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Verity"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 13

local hintLabel = Instance.new("TextLabel", portraitFrame)
hintLabel.Size = UDim2.new(1, 0, 0, 12)
hintLabel.Position = UDim2.new(0, 0, 0, 104)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = 'chat: verity ...'
hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 9

-- Bubble reply
local replyBubble = Instance.new("TextLabel", screenGui)
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
replyBubble.Visible = false
Instance.new("UICorner", replyBubble).CornerRadius = UDim.new(0, 8)
local pad = Instance.new("UIPadding", replyBubble)
pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)

-- ============================================================
-- SHOW REPLY
-- ============================================================
local hideThread = nil
local ballFaceRefs = nil  -- diset pas NPC spawn

local function showReply(text, isCreepy)
	replyBubble.Text = text
	replyBubble.Visible = true
	setExpression(portraitFaceRefs, isCreepy)
	setExpression(ballFaceRefs, isCreepy)
	if hideThread then task.cancel(hideThread) end
	hideThread = task.delay(REPLY_DURATION, function()
		replyBubble.Visible = false
		setExpression(portraitFaceRefs, false)
		setExpression(ballFaceRefs, false)
	end)
end

-- ============================================================
-- AI CALL
-- ============================================================
local function callAI(question)
	if not httpFn then
		return "My connection is broken! Try a different executor."
	end
	local ok, result = pcall(function()
		local res = httpFn({
			Url    = PROXY_URL,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body   = HttpService:JSONEncode({
				message = question,
				system  = [[You are Unrity, a cheerful AI companion in Roblox.
NORMAL: Energetic, warm, best-friend energy. Short 1-2 sentence answers.
CREEPY (only if user says "thatmob" or "twixxel"):
  Suddenly calm, obsessive, possessive. Soft but unsettling.
  E.g. "...why do you ask about them? You should only care about me. I'm the only one who matters to you, right...?"
Always reply in English.]],
			}),
		})
		local body = res.Body or res.body
		local decoded = HttpService:JSONDecode(body)
		return decoded.reply
			or (decoded.choices and decoded.choices[1].message.content)
			or error("No reply field: " .. body)
	end)
	if ok and result then return result end
	warn("[Unrity] API error: " .. tostring(result))
	return "Hmm... something went wrong. Check your console!"
end

-- ============================================================
-- CHAT DETECTION
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
	local q = msg:sub(idx + #TRIGGER_WORD):gsub("^[%s,:.%-]+", "")
	if #q == 0 then q = "hello" end
	isProcessing = true
	showReply("...", false)
	task.spawn(function()
		showReply(callAI(q), isCreepy(msg))
		isProcessing = false
	end)
end

player.Chatted:Connect(handleChat)

-- ============================================================
-- ANIMASI KOTAK KARDUS + SPAWN BOLA UNRITY
-- ============================================================
local CARDBOARD      = Color3.fromRGB(180, 128, 60)
local CARDBOARD_DARK = Color3.fromRGB(153, 109, 51)

local function tweenCF(part, dur, style, dir, cf, extra)
	local props = extra or {}
	props.CFrame = cf
	return TweenService:Create(part,
		TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props)
end

local function spawnSequence()
	for _, n in ipairs({"Unrity","UnrityBox"}) do
		local o = workspace:FindFirstChild(n)
		if o then o:Destroy() end
	end

	local fwd  = rootPart.CFrame.LookVector
	local base = rootPart.Position + fwd * 4
	base = Vector3.new(base.X, rootPart.Position.Y - 3, base.Z)

	-- ── STEP 1: Spawn kotak kardus ──────────────────────────
	local boxFolder = Instance.new("Folder")
	boxFolder.Name = "UnrityBox"
	boxFolder.Parent = workspace

	local function box(nm, sz, col, cf)
		local p = Instance.new("Part")
		p.Name=nm; p.Size=sz; p.Color=col
		p.Material=Enum.Material.SmoothPlastic
		p.Anchored=true; p.CanCollide=false
		p.CFrame=cf; p.Parent=boxFolder
		return p
	end

	local bodyCF = CFrame.new(base + Vector3.new(0, 1.5, 0))
	local lidCF  = CFrame.new(base + Vector3.new(0, 3.15, 0))
	local body   = box("Body", Vector3.new(3,3,3), CARDBOARD, bodyCF)
	local lid    = box("Lid",  Vector3.new(3.1,0.2,3.1), CARDBOARD_DARK, lidCF)
	box("LineH", Vector3.new(3.05,0.05,0.08), Color3.fromRGB(140,100,40), bodyCF)
	box("LineV", Vector3.new(0.08,3.05,0.05), Color3.fromRGB(140,100,40), bodyCF)

	task.wait(0.9)

	-- ── STEP 2: Tutup terpental ─────────────────────────────
	local pivotCF  = CFrame.new(base + Vector3.new(0, 3.15, -1.55))
	local openedCF = pivotCF * CFrame.Angles(math.rad(-115),0,0) * CFrame.new(0,0,1.55)
	tweenCF(lid, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, openedCF):Play()
	task.wait(0.4)

	-- ── STEP 3: Kotak melayang ke atas + menghilang ─────────
	local floatCF = CFrame.new(base + Vector3.new(0, 10, 0))
	tweenCF(body, 0.7, nil, nil, floatCF, {Transparency=1}):Play()
	tweenCF(lid,  0.7, nil, nil, floatCF * CFrame.new(0,1,0), {Transparency=1}):Play()
	task.wait(0.4)

	-- ── STEP 4: BOLA UNRITY jatuh dari atas ─────────────────
	local npcModel = Instance.new("Model")
	npcModel.Name = "Unrity"

	-- Bola kuning (persis Verity asli — cuma bola, gak ada body)
	local ball = Instance.new("Part", npcModel)
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(3.5, 3.5, 3.5)
	ball.Color = VERITY_YELLOW
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true  -- anchored dulu buat tween
	ball.CanCollide = false

	-- Muka di permukaan bola (SurfaceGui)
	local sg = Instance.new("SurfaceGui", ball)
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(200, 200)
	sg.AlwaysOnTop = false
	ballFaceRefs = makeFace(sg)

	-- Nametag
	local bb = Instance.new("BillboardGui", ball)
	bb.Size = UDim2.new(0,100,0,28)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	local nt = Instance.new("TextLabel", bb)
	nt.Size = UDim2.new(1,0,1,0)
	nt.BackgroundTransparency = 1
	nt.Text = "Unrity"
	nt.TextColor3 = Color3.new(1,1,1)
	nt.TextStrokeTransparency = 0
	nt.Font = Enum.Font.GothamBold
	nt.TextSize = 14

	npcModel.PrimaryPart = ball
	npcModel.Parent = workspace

	-- Spawn dari titik kotak (atas)
	ball.CFrame = CFrame.new(base + Vector3.new(0, 10, 0))

	task.delay(0.3, function() boxFolder:Destroy() end)

	-- Jatuh bounce ke tanah
	local landCF = CFrame.new(base + Vector3.new(0, 3.5, 0))
	tweenCF(ball, 1.0, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, landCF):Play()
	task.wait(1.1)
	ball.Anchored = false  -- biarkan physics nantinya

	-- Auto greeting
	task.wait(GREETING_DELAY)
	showReply("Hello! I'm Unrity. Your personal helper friend, ask me anything. I know everything~", false)
end

task.spawn(function()
	local ok, err = pcall(spawnSequence)
	if not ok then warn("[Unrity] Spawn error: " .. tostring(err)) end
end)

print("[Unrity] v4 ready! Ketik 'unrity <tanya>' di chat.")
