--[[
	UnrityScript.lua — v6
	Semua fitur: 2D face (always face cam), talking anim,
	happiness bar, 3 ekspresi, giant form, box interactable, carry
	loadstring(game:HttpGet("https://raw.githubusercontent.com/musgamerkeren23-afk/Unrity-verity-mod-fake-script-Fe-roblox/refs/heads/main/UnrityScript-2.lua"))()
]]

-- ===== CONFIG =====
local PROXY_URL      = "https://raspy-dream-5ef3.musgamerkeren23.workers.dev/"
local VERITY_YELLOW  = Color3.fromRGB(255, 218, 40)
local TRIGGER_WORD   = "unrity"
local CREEPY_WORDS   = {"thatmob", "twixxel"}
local HATE_WORDS     = {"hate","ugly","stupid","bad","shut up","idiot","dumb","go away","useless","trash"}
local LEAVE_WORDS    = {"bye","goodbye","leaving","i'm leaving","gotta go","see ya","i leave","i'm going"}
local REPLY_DURATION = 12
local GREETING_DELAY = 8

local BALL_SIZE_NORMAL  = Vector3.new(3.5, 3.5, 3.5)
local BALL_SIZE_GIANT   = Vector3.new(11, 11, 11)
local PREMED_AUDIO_ID   = "rbxassetid://92623551842454"
local PREMED_KEYWORD    = "premeditated"
local PREMED_DURATION   = 35  -- detik chase berlangsung

-- ===== SERVICES =====
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart", 10)
if not rootPart then warn("[Unrity] rootPart gak ketemu.") return end

local httpFn = (syn and syn.request) or http_request or request
	or (fluxus and fluxus.request)

-- ===== STATE =====
local happiness      = 100  -- 0-100
local isGiant        = false
local isTalking      = false
local talkThread     = nil
local ball           = nil
local isCarrying     = false
local carryConn      = nil
local portraitRefs   = nil
local ballRefs       = nil
local isPremeditated = false
local premedSound    = nil
local chaserModel    = nil
local triggerPremeditated  -- forward declaration (diisi nanti)

-- ===== HAPPINESS STATE =====
-- 70-100 = happy, 40-69 = neutral, 1-39 = angry, 0 = GIANT
local function getHappinessState()
	if happiness <= 0  then return "giant"   end
	if happiness <= 39 then return "angry"   end
	if happiness <= 69 then return "neutral"  end
	return "happy"
end

-- ============================================================
-- FACE (BillboardGui — always ngadepin kamera)
-- ============================================================
local function makeFace(parent)
	-- parent = BillboardGui atau Frame (portrait)

	-- ALIS kiri (buat ekspresi angry)
	local browL = Instance.new("Frame", parent)
	browL.Name = "BrowL"
	browL.Size = UDim2.new(0.18,0,0.05,0)
	browL.Position = UDim2.new(0.18,0,0.18,0)
	browL.BackgroundColor3 = Color3.new(0,0,0)
	browL.BorderSizePixel = 0
	browL.Visible = false
	Instance.new("UICorner",browL).CornerRadius = UDim.new(1,0)

	local browR = browL:Clone()
	browR.Name = "BrowR"
	browR.Position = UDim2.new(0.64,0,0.18,0)
	browR.Parent = parent

	-- MATA kiri
	local eL = Instance.new("Frame", parent)
	eL.Name = "EyeL"
	eL.Size = UDim2.new(0.14,0,0.14,0)
	eL.Position = UDim2.new(0.20,0,0.28,0)
	eL.BackgroundColor3 = Color3.new(0,0,0)
	eL.BorderSizePixel = 0
	Instance.new("UICorner",eL).CornerRadius = UDim.new(1,0)
	local shineL = Instance.new("Frame", eL)
	shineL.Size = UDim2.new(0.32,0,0.32,0)
	shineL.Position = UDim2.new(0.58,0,0.08,0)
	shineL.BackgroundColor3 = Color3.new(1,1,1)
	shineL.BorderSizePixel = 0; shineL.ZIndex = 2
	Instance.new("UICorner",shineL).CornerRadius = UDim.new(1,0)

	local eR = eL:Clone()
	eR.Name = "EyeR"
	eR.Position = UDim2.new(0.66,0,0.28,0)
	eR.Parent = parent

	-- MULUT (bar tipis, gak keluar batas bola)
	local mouth = Instance.new("Frame", parent)
	mouth.Name = "Mouth"
	mouth.Size = UDim2.new(0.52,0,0.11,0)
	mouth.Position = UDim2.new(0.24,0,0.60,0)
	mouth.BackgroundColor3 = Color3.new(0,0,0)
	mouth.BorderSizePixel = 0
	Instance.new("UICorner",mouth).CornerRadius = UDim.new(0.5,0)

	-- Gigi
	local teeth = Instance.new("Frame", mouth)
	teeth.Name = "Teeth"
	teeth.Size = UDim2.new(1,0,1,0)
	teeth.BackgroundColor3 = Color3.new(1,1,1)
	teeth.BorderSizePixel = 0; teeth.ZIndex = 2; teeth.Visible = false
	for i = 0, 5 do
		local g = Instance.new("Frame", teeth)
		g.Size = UDim2.new(0.03,0,1,0)
		g.Position = UDim2.new(0.14*i+0.02,0,0,0)
		g.BackgroundColor3 = Color3.new(0,0,0)
		g.BorderSizePixel = 0; g.ZIndex = 3
	end

	return {browL=browL, browR=browR, eL=eL, eR=eR, mouth=mouth, teeth=teeth, shineL=shineL}
end

-- state: "happy" | "neutral" | "angry" | "creepy" | "giant"
local function setExpression(refs, state)
	if not refs then return end
	local m = refs.mouth

	-- reset semua
	refs.browL.Visible = false; refs.browR.Visible = false
	refs.teeth.Visible = false
	refs.shineL.Visible = true
	local sR = refs.eR:FindFirstChildOfClass("Frame")
	if sR then sR.Visible = true end
	refs.eL.Size = UDim2.new(0.14,0,0.14,0)
	refs.eR.Size = UDim2.new(0.14,0,0.14,0)
	refs.eL.Rotation = 0; refs.eR.Rotation = 0
	m.Size = UDim2.new(0.52,0,0.11,0)
	m.Position = UDim2.new(0.24,0,0.60,0)
	m.Rotation = 0

	if state == "happy" then
		-- default (udah di-reset di atas)

	elseif state == "neutral" then
		-- garis lurus, no shine
		refs.shineL.Visible = false
		if sR then sR.Visible = false end
		m.Size = UDim2.new(0.45,0,0.05,0)
		m.Position = UDim2.new(0.27,0,0.62,0)

	elseif state == "angry" then
		-- alis turun, mata squint, frown (mulut terbalik)
		refs.browL.Visible = true; refs.browR.Visible = true
		refs.browL.Rotation = 15; refs.browR.Rotation = -15
		refs.eL.Size = UDim2.new(0.14,0,0.09,0)
		refs.eR.Size = UDim2.new(0.14,0,0.09,0)
		refs.shineL.Visible = false
		if sR then sR.Visible = false end
		m.Size = UDim2.new(0.44,0,0.09,0)
		m.Position = UDim2.new(0.28,0,0.65,0)
		m.Rotation = 180  -- frown = flip

	elseif state == "creepy" then
		refs.eL.Size = UDim2.new(0.18,0,0.18,0)
		refs.eR.Size = UDim2.new(0.18,0,0.18,0)
		refs.shineL.Visible = false
		if sR then sR.Visible = false end
		m.Size = UDim2.new(0.76,0,0.14,0)
		m.Position = UDim2.new(0.12,0,0.58,0)
		refs.teeth.Visible = true

	elseif state == "giant" then
		refs.browL.Visible = true; refs.browR.Visible = true
		refs.browL.Rotation = 25; refs.browR.Rotation = -25
		refs.eL.Size = UDim2.new(0.20,0,0.20,0)
		refs.eR.Size = UDim2.new(0.20,0,0.20,0)
		refs.shineL.Visible = false
		if sR then sR.Visible = false end
		m.Size = UDim2.new(0.82,0,0.18,0)
		m.Position = UDim2.new(0.09,0,0.60,0)
		refs.teeth.Visible = true
		m.Rotation = 0
	end
end

-- TALKING ANIMATION
local mouthNormalH = 0.11
local function startTalking()
	isTalking = true
	if talkThread then task.cancel(talkThread) end
	talkThread = task.spawn(function()
		while isTalking do
			local openH = 0.20
			local closeH = 0.04
			for _, refs in ipairs({portraitRefs, ballRefs}) do
				if refs then
					refs.mouth.Size = UDim2.new(refs.mouth.Size.X.Scale, 0, openH, 0)
				end
			end
			task.wait(0.13)
			for _, refs in ipairs({portraitRefs, ballRefs}) do
				if refs then
					refs.mouth.Size = UDim2.new(refs.mouth.Size.X.Scale, 0, closeH, 0)
				end
			end
			task.wait(0.10)
		end
	end)
end

local function stopTalking()
	isTalking = false
	if talkThread then task.cancel(talkThread); talkThread = nil end
	-- reset mulut ke ekspresi sekarang
	local state = getHappinessState()
	setExpression(portraitRefs, state)
	setExpression(ballRefs, state)
end

-- ============================================================
-- HAPPINESS BAR UI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnrityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Portrait frame (lebih tinggi sedikit buat muat bar)
local portraitFrame = Instance.new("Frame", screenGui)
portraitFrame.Size = UDim2.new(0,90,0,140)
portraitFrame.Position = UDim2.new(1,-105,0,20)
portraitFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
portraitFrame.BackgroundTransparency = 0.15
Instance.new("UICorner",portraitFrame).CornerRadius = UDim.new(0,10)

-- Wajah portrait (lingkaran kuning)
local portraitFace = Instance.new("Frame", portraitFrame)
portraitFace.Size = UDim2.new(1,-10,0,76)
portraitFace.Position = UDim2.new(0,5,0,4)
portraitFace.BackgroundColor3 = VERITY_YELLOW
portraitFace.BorderSizePixel = 0
Instance.new("UICorner",portraitFace).CornerRadius = UDim.new(0.5,0)
portraitRefs = makeFace(portraitFace)

local nameLabel = Instance.new("TextLabel", portraitFrame)
nameLabel.Size = UDim2.new(1,0,0,16); nameLabel.Position = UDim2.new(0,0,0,82)
nameLabel.BackgroundTransparency = 1; nameLabel.Text = "Unrity"
nameLabel.TextColor3 = Color3.new(1,1,1); nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 12

-- Happiness bar background
local barBg = Instance.new("Frame", portraitFrame)
barBg.Size = UDim2.new(0.85,0,0,6)
barBg.Position = UDim2.new(0.075,0,0,100)
barBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
barBg.BorderSizePixel = 0
Instance.new("UICorner",barBg).CornerRadius = UDim.new(1,0)

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(1,0,1,0)
barFill.BackgroundColor3 = Color3.fromRGB(100,255,100)
barFill.BorderSizePixel = 0
Instance.new("UICorner",barFill).CornerRadius = UDim.new(1,0)

local happyIcon = Instance.new("TextLabel", portraitFrame)
happyIcon.Size = UDim2.new(1,0,0,14); happyIcon.Position = UDim2.new(0,0,0,108)
happyIcon.BackgroundTransparency = 1; happyIcon.Text = "😊 100%"
happyIcon.TextColor3 = Color3.fromRGB(100,255,100)
happyIcon.Font = Enum.Font.GothamBold; happyIcon.TextSize = 9

local hintLabel = Instance.new("TextLabel", portraitFrame)
hintLabel.Size = UDim2.new(1,0,0,10); hintLabel.Position = UDim2.new(0,0,0,124)
hintLabel.BackgroundTransparency = 1; hintLabel.Text = "chat: unrity ..."
hintLabel.TextColor3 = Color3.fromRGB(130,130,130)
hintLabel.Font = Enum.Font.Gotham; hintLabel.TextSize = 8

-- Carry label
local carryLabel = Instance.new("TextLabel", portraitFrame)
carryLabel.Size = UDim2.new(1,0,0,10); carryLabel.Position = UDim2.new(0,0,0,134)
carryLabel.BackgroundTransparency = 1; carryLabel.Text = ""
carryLabel.TextColor3 = VERITY_YELLOW
carryLabel.Font = Enum.Font.GothamBold; carryLabel.TextSize = 8

-- Reply bubble
local replyBubble = Instance.new("TextLabel", screenGui)
replyBubble.Size = UDim2.new(0,220,0,0)
replyBubble.AutomaticSize = Enum.AutomaticSize.Y
replyBubble.Position = UDim2.new(1,-340,0,20)
replyBubble.BackgroundColor3 = Color3.fromRGB(15,15,15)
replyBubble.BackgroundTransparency = 0.1
replyBubble.TextColor3 = Color3.new(1,1,1)
replyBubble.Font = Enum.Font.Gotham; replyBubble.TextSize = 14
replyBubble.TextWrapped = true; replyBubble.Text = ""; replyBubble.Visible = false
Instance.new("UICorner",replyBubble).CornerRadius = UDim.new(0,8)
local pad = Instance.new("UIPadding",replyBubble)
pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)

-- ============================================================
-- UPDATE HAPPINESS UI
-- ============================================================
local function updateHappinessUI()
	local pct = math.clamp(happiness, 0, 100) / 100
	barFill.Size = UDim2.new(pct, 0, 1, 0)

	local state = getHappinessState()
	if state == "happy" then
		barFill.BackgroundColor3 = Color3.fromRGB(100,255,100)
		happyIcon.TextColor3 = Color3.fromRGB(100,255,100)
		happyIcon.Text = "😊 " .. happiness .. "%"
	elseif state == "neutral" then
		barFill.BackgroundColor3 = Color3.fromRGB(255,220,50)
		happyIcon.TextColor3 = Color3.fromRGB(255,220,50)
		happyIcon.Text = "😐 " .. happiness .. "%"
	elseif state == "angry" then
		barFill.BackgroundColor3 = Color3.fromRGB(255,80,80)
		happyIcon.TextColor3 = Color3.fromRGB(255,80,80)
		happyIcon.Text = "😠 " .. happiness .. "%"
	else
		barFill.BackgroundColor3 = Color3.fromRGB(150,0,0)
		happyIcon.TextColor3 = Color3.fromRGB(255,50,50)
		happyIcon.Text = "👹 0%"
	end

	if not isTalking then
		setExpression(portraitRefs, state)
		setExpression(ballRefs, state)
	end
end

-- Giant form
local function triggerGiantForm()
	if isGiant or not ball or not ball.Parent then return end
	isGiant = true
	setExpression(portraitRefs, "giant")
	setExpression(ballRefs, "giant")
	-- Scale BillboardGui (visual 2D) bukan Part
	local bodyBB2 = ball and ball:FindFirstChild("BodyBB")
	if bodyBB2 then
		TweenService:Create(bodyBB2,
			TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{Size = UDim2.new(11,0,11,0)}
		):Play()
	end
	ball.Size = BALL_SIZE_GIANT  -- perbesar hitbox juga
end

-- Decrease happiness
local function decreaseHappiness(amount, reason)
	if isGiant then return end
	happiness = math.max(0, happiness - amount)
	updateHappinessUI()
	if happiness <= 0 then
		task.delay(0.5, triggerGiantForm)
	end
end

-- ============================================================
-- SHOW REPLY + AI
-- ============================================================
local hideThread = nil

local function showReply(text, forceState)
	replyBubble.Text = text
	replyBubble.Visible = true

	local state = forceState or getHappinessState()
	if state == "creepy" then
		setExpression(portraitRefs, "creepy")
		setExpression(ballRefs, "creepy")
	end

	startTalking()

	if hideThread then task.cancel(hideThread) end
	hideThread = task.delay(REPLY_DURATION, function()
		stopTalking()
		replyBubble.Visible = false
		updateHappinessUI()
	end)
end

local function callAI(question)
	if not httpFn then return "My connection is broken!" end
	local happState = getHappinessState()
	local sysPrompt = [[You are Unrity, a cheerful AI companion in Roblox.
HAPPY (default): Energetic, warm, best-friend energy. Short 1-2 sentence answers.
NEUTRAL: A bit quieter, less enthusiastic. Still polite.
ANGRY: Curt, passive-aggressive. Short replies. Clearly upset.
GIANT/RAGE: FURIOUS, all caps, scary, threatening. Very short.
CREEPY (thatmob/twixxel trigger): Calm obsessive. "...why do you mention them? You should only care about me..."
Always reply in English. Match your current mood to the happiness level.]]

	local function doRequest()
		local res = httpFn({
			Url = PROXY_URL, Method = "POST",
			Headers = {["Content-Type"]="application/json"},
			Body = HttpService:JSONEncode({
				message = "[Mood: "..happState.."] "..question,
				system = sysPrompt,
			}),
		})
		local statusCode = res.StatusCode or res.statusCode or 200
		-- Handle rate limit (429) dan server error (503)
		if statusCode == 429 then
			return nil, "ratelimit"
		elseif statusCode == 503 then
			return nil, "unavailable"
		end
		local decoded = HttpService:JSONDecode(res.Body or res.body)
		local reply = decoded.reply
			or (decoded.choices and decoded.choices[1].message.content)
		return reply, nil
	end

	-- Attempt pertama
	local ok, result, errType = pcall(doRequest)
	if ok and result then return result end

	-- Kalau rate limit, tunggu 3 detik terus retry sekali
	if errType == "ratelimit" then
		task.wait(3)
		ok, result, errType = pcall(doRequest)
		if ok and result then return result end
		return "I need a moment to think... try asking again in a bit! 💭"
	end

	-- Server down
	if errType == "unavailable" then
		return "My brain is a bit foggy right now... try again soon! ☁️"
	end

	warn("[Unrity] API error: "..tostring(result))
	return "Hmm... something went wrong!"
end

local function isCreepyMsg(text)
	local low = text:lower()
	for _,kw in ipairs(CREEPY_WORDS) do if low:find(kw) then return true end end
	return false
end

local function checkHateMsg(text)
	local low = text:lower()
	for _,w in ipairs(HATE_WORDS) do
		if low:find(w) then decreaseHappiness(15, "hate") return end
	end
	for _,w in ipairs(LEAVE_WORDS) do
		if low:find(w) then decreaseHappiness(25, "leave") return end
	end
end

-- Chat handler
local isProcessing = false
local function handleChat(msg)
	-- Cek trigger premeditated (rahasia, tanpa prefix "unrity")
	if msg:lower():find(PREMED_KEYWORD) then
		triggerPremeditated()
		return
	end
	checkHateMsg(msg)  -- cek kata jahat di setiap chat
	if isProcessing then return end
	local low = msg:lower()
	local idx = low:find(TRIGGER_WORD, 1, true)
	if not idx then return end
	local q = msg:sub(idx+#TRIGGER_WORD):gsub("^[%s,:.%-]+","")
	if #q == 0 then q = "hello" end
	isProcessing = true
	showReply("...", nil)
	task.spawn(function()
		local creepy = isCreepyMsg(msg)
		local reply = callAI(q)
		stopTalking()
		showReply(reply, creepy and "creepy" or nil)
		isProcessing = false
	end)
end
player.Chatted:Connect(handleChat)

-- ============================================================
-- CARRY MECHANIC
-- ============================================================
local function findFloorY(pos)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {workspace:FindFirstChild("Unrity")}
	local r = workspace:Raycast(pos, Vector3.new(0,-30,0), rp)
	return r and (r.Position.Y + (isGiant and 6 or 1.75)) or pos.Y
end

local function startCarry()
	if not ball then return end
	isCarrying = true; carryLabel.Text = "carrying ✦"
	if carryConn then carryConn:Disconnect() end
	carryConn = RunService.RenderStepped:Connect(function()
		if not isCarrying or not ball or not ball.Parent then return end
		local target = rootPart.CFrame * CFrame.new(1.5, 1.0, -6.0)
		ball.CFrame = ball.CFrame:Lerp(CFrame.new(target.Position), 0.25)
	end)
end

local function stopCarry()
	isCarrying = false; carryLabel.Text = ""
	if carryConn then carryConn:Disconnect(); carryConn = nil end
	if not ball or not ball.Parent then return end
	local floorY = findFloorY(ball.Position)
	ball.CFrame = CFrame.new(ball.Position.X, floorY, ball.Position.Z)
end

-- ============================================================
-- SPAWN BOX + UNRITY
-- ============================================================
local CARDBOARD      = Color3.fromRGB(180,128,60)
local CARDBOARD_DARK = Color3.fromRGB(153,109,51)

local function tw(part, dur, style, dir, cf, extra)
	local props = extra or {}; props.CFrame = cf
	return TweenService:Create(part,
		TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end


-- ============================================================
-- PREMEDITATED — Tall R6 Unrity chase mode
-- ============================================================
local function stopPremeditated()
	if not isPremeditated then return end
	isPremeditated = false
	if premedSound then premedSound:Destroy(); premedSound = nil end
	if chaserModel then chaserModel:Destroy(); chaserModel = nil end
	-- Restore Unrity billboard
	local unrity = workspace:FindFirstChild("Unrity")
	if unrity then
		local bb = unrity:FindFirstChildOfClass("BillboardGui")
		if bb then bb.Enabled = true end
	end
	showReply("...hehe. Just kidding~", nil)
end

triggerPremeditated = function()
	if isPremeditated then stopPremeditated() return end
	isPremeditated = true

	-- Sembunyiin Unrity billboard sementara
	local unrity = workspace:FindFirstChild("Unrity")
	if unrity then
		local bb = unrity:FindFirstChildOfClass("BillboardGui")
		if bb then bb.Enabled = false end
	end
	replyBubble.Visible = false

	-- Mainkan lagu
	premedSound = Instance.new("Sound", workspace)
	premedSound.SoundId = PREMED_AUDIO_ID
	premedSound.Volume = 0.85
	premedSound.Looped = true
	premedSound.RollOffMaxDistance = 1000  -- biar kedengeran dari jauh
	premedSound.Parent = workspace
	task.wait(0.3)  -- kasih waktu sound load
	premedSound:Play()

	-- Spawn Tall R6 Unrity (2x ukuran normal)
	chaserModel = Instance.new("Model")
	chaserModel.Name = "UnrityChaser"
	chaserModel.Parent = workspace

	local S = 2.2  -- scale factor (gede/tinggi)
	local BLACK  = Color3.fromRGB(15, 15, 15)

	local function mkPart(nm, sz, col)
		local p = Instance.new("Part")
		p.Name=nm; p.Size=sz*S; p.Color=col
		p.Material=Enum.Material.SmoothPlastic
		p.Anchored=true; p.CanCollide=false
		p.CastShadow=true; p.Parent=chaserModel
		return p
	end

	-- Bagian tubuh (offset relatif ke HRP, sebelum di-scale)
	local hrp    = mkPart("HRP",      Vector3.new(2,2,1)/S,    BLACK)
	hrp.Transparency = 1
	local torso  = mkPart("Torso",    Vector3.new(2,2,1),      BLACK)
	local head   = mkPart("Head",     Vector3.new(2,2,2),      Color3.fromRGB(255,218,40))
	local lArm   = mkPart("LAArm",    Vector3.new(1,2,1),      BLACK)
	local rArm   = mkPart("RAArm",    Vector3.new(1,2,1),      BLACK)
	local lLeg   = mkPart("LLeg",     Vector3.new(1,2,1),      BLACK)
	local rLeg   = mkPart("RLeg",     Vector3.new(1,2,1),      BLACK)

	-- Muka Unrity di kepala (BillboardGui 2D)
	local faceBB2 = Instance.new("BillboardGui", head)
	faceBB2.Size = UDim2.new(2*S,0,2*S,0)
	faceBB2.LightInfluence = 0
	local faceCircle2 = Instance.new("Frame", faceBB2)
	faceCircle2.Size = UDim2.new(1,0,1,0)
	faceCircle2.BackgroundColor3 = VERITY_YELLOW
	faceCircle2.BorderSizePixel = 0
	Instance.new("UICorner",faceCircle2).CornerRadius = UDim.new(0.5,0)
	local chaserFaceRefs = makeFace(faceCircle2)
	setExpression(chaserFaceRefs, "angry")

	-- Offset tiap part relatif ke HRP (dalam stud, sebelum scale)
	local offsets = {
		{torso, CFrame.new(0,  0,   0)},
		{head,  CFrame.new(0,  2,   0)},
		{lArm,  CFrame.new(-1.5, 0, 0)},
		{rArm,  CFrame.new( 1.5, 0, 0)},
		{lLeg,  CFrame.new(-0.5,-2,  0)},
		{rLeg,  CFrame.new( 0.5,-2,  0)},
	}

	chaserModel.PrimaryPart = hrp

	-- Posisi awal: di tempat Unrity berdiri
	local startPos = ball and ball.Position or (rootPart.Position + Vector3.new(5,0,5))
	startPos = Vector3.new(startPos.X, rootPart.Position.Y, startPos.Z)
	hrp.CFrame = CFrame.new(startPos)
	for _, d in ipairs(offsets) do
		d[1].CFrame = hrp.CFrame * (d[2] * S)
	end

	-- Chase loop
	local chaseConn
	chaseConn = RunService.Heartbeat:Connect(function()
		if not isPremeditated or not chaserModel or not chaserModel.Parent then
			chaseConn:Disconnect(); return
		end
		local targetPos = rootPart.Position
		local dir = (targetPos - hrp.Position)
		local distXZ = Vector3.new(dir.X,0,dir.Z).Magnitude

		local moveSpeed = 0.18  -- lerp speed (0-1)
		local yRot = math.atan2(dir.X, dir.Z)

		-- Gerak mendekat
		local newPos = hrp.Position + Vector3.new(dir.X,0,dir.Z).Unit * math.min(distXZ, 0.35)
		newPos = Vector3.new(newPos.X, rootPart.Position.Y, newPos.Z)
		local newCF = CFrame.new(newPos) * CFrame.Angles(0, yRot, 0)
		hrp.CFrame = hrp.CFrame:Lerp(newCF, moveSpeed)

		-- Update semua part
		for _, d in ipairs(offsets) do
			d[1].CFrame = hrp.CFrame * (d[2] * S)
		end
	end)

	-- Auto stop setelah durasi
	task.delay(PREMED_DURATION, function()
		if chaseConn then chaseConn:Disconnect() end
		stopPremeditated()
	end)
end

local function spawnBox()
	for _,n in ipairs({"Unrity","UnrityBox"}) do
		local o=workspace:FindFirstChild(n); if o then o:Destroy() end
	end

	local fwd  = rootPart.CFrame.LookVector
	local base = rootPart.Position + fwd*4
	base = Vector3.new(base.X, rootPart.Position.Y - 3, base.Z)

	local boxModel = Instance.new("Model")
	boxModel.Name = "UnrityBox"
	boxModel.Parent = workspace

	local function mkBox(nm,sz,col,cf)
		local p = Instance.new("Part")
		p.Name=nm; p.Size=sz; p.Color=col
		p.Material=Enum.Material.SmoothPlastic
		p.Anchored=true; p.CanCollide=true
		p.CFrame=cf; p.Parent=boxModel
		return p
	end

	local bodyCF = CFrame.new(base+Vector3.new(0,1.5,0))
	local lidCF  = CFrame.new(base+Vector3.new(0,3.15,0))
	local body   = mkBox("Body",Vector3.new(3,3,3),CARDBOARD,bodyCF)
	local lid    = mkBox("Lid",Vector3.new(3.1,0.2,3.1),CARDBOARD_DARK,lidCF)
	mkBox("LineH",Vector3.new(3.05,0.05,0.08),Color3.fromRGB(140,100,40),bodyCF)
	mkBox("LineV",Vector3.new(0.08,3.05,0.05),Color3.fromRGB(140,100,40),bodyCF)

	local billHint = Instance.new("BillboardGui", body)
	billHint.Size = UDim2.new(0,130,0,30)
	billHint.StudsOffset = Vector3.new(0,3,0)
	local hintTxt = Instance.new("TextLabel", billHint)
	hintTxt.Size=UDim2.new(1,0,1,0); hintTxt.BackgroundTransparency=1
	hintTxt.Text="[ Click to open ]"
	hintTxt.TextColor3=VERITY_YELLOW; hintTxt.TextStrokeTransparency=0.4
	hintTxt.Font=Enum.Font.GothamBold; hintTxt.TextSize=14

	local cd = Instance.new("ClickDetector", body)
	cd.MaxActivationDistance = 20

	cd.MouseClick:Connect(function()
		if not boxModel.Parent then return end
		cd.Parent = nil; billHint:Destroy()

		-- Buka tutup
		local pivotCF  = CFrame.new(base+Vector3.new(0,3.15,-1.55))
		local openedCF = pivotCF*CFrame.Angles(math.rad(-115),0,0)*CFrame.new(0,0,1.55)
		tw(lid,0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out,openedCF):Play()
		task.wait(0.4)

		-- Kotak melayang hilang
		local floatCF = CFrame.new(base+Vector3.new(0,10,0))
		tw(body,0.7,nil,nil,floatCF,{Transparency=1}):Play()
		tw(lid, 0.7,nil,nil,floatCF*CFrame.new(0,1,0),{Transparency=1}):Play()
		task.wait(0.5)
		boxModel:Destroy()

		-- ── Spawn Unrity (bola kuning) ──────────────────────
		local npcModel = Instance.new("Model")
		npcModel.Name = "Unrity"

		-- Part INVISIBLE sebagai anchor + hitbox klik (bukan bola 3D!)
		ball = Instance.new("Part", npcModel)
		ball.Name = "Ball"
		ball.Shape = Enum.PartType.Ball
		ball.Size = BALL_SIZE_NORMAL
		ball.Transparency = 1          -- INVISIBLE — bola 3D gak keliatan
		ball.CanCollide = false
		ball.Anchored = true

		-- BillboardGui BESAR = "tubuh" Unrity yang beneran (flat 2D sprite)
		local bodyBB = Instance.new("BillboardGui", ball)
		bodyBB.Name = "BodyBB"
		bodyBB.Size = UDim2.new(4,0,4,0)  -- 4x4 stud = ukuran visual Unrity
		bodyBB.StudsOffset = Vector3.new(0,0,0)
		bodyBB.AlwaysOnTop = false
		bodyBB.LightInfluence = 0

		-- Lingkaran kuning (background muka 2D)
		local faceCircle = Instance.new("Frame", bodyBB)
		faceCircle.Size = UDim2.new(1,0,1,0)
		faceCircle.BackgroundColor3 = VERITY_YELLOW
		faceCircle.BorderSizePixel = 0
		Instance.new("UICorner", faceCircle).CornerRadius = UDim.new(0.5,0)

		-- Elemen muka di dalam lingkaran
		ballRefs = makeFace(faceCircle)

		-- Nametag
		local bb = Instance.new("BillboardGui", ball)
		bb.Size=UDim2.new(0,100,0,28); bb.StudsOffset=Vector3.new(0,2.5,0)
		local nt=Instance.new("TextLabel",bb)
		nt.Size=UDim2.new(1,0,1,0); nt.BackgroundTransparency=1
		nt.Text="Unrity"; nt.TextColor3=Color3.new(1,1,1)
		nt.TextStrokeTransparency=0; nt.Font=Enum.Font.GothamBold; nt.TextSize=14

		-- Happiness bar floating (di atas nametag)
		local bbBar = Instance.new("BillboardGui", ball)
		bbBar.Size=UDim2.new(0,80,0,10); bbBar.StudsOffset=Vector3.new(0,3.2,0)
		local barBgW = Instance.new("Frame",bbBar)
		barBgW.Size=UDim2.new(1,0,1,0); barBgW.BackgroundColor3=Color3.fromRGB(40,40,40)
		barBgW.BorderSizePixel=0; Instance.new("UICorner",barBgW).CornerRadius=UDim.new(1,0)
		local barFillW = Instance.new("Frame",barBgW)
		barFillW.Size=UDim2.new(1,0,1,0); barFillW.BackgroundColor3=Color3.fromRGB(100,255,100)
		barFillW.BorderSizePixel=0; Instance.new("UICorner",barFillW).CornerRadius=UDim.new(1,0)

		-- Sync floating bar sama portrait bar
		RunService.RenderStepped:Connect(function()
			if not ball or not ball.Parent then return end
			local pct = math.clamp(happiness,0,100)/100
			barFillW.Size = UDim2.new(pct,0,1,0)
			if happiness > 69 then barFillW.BackgroundColor3 = Color3.fromRGB(100,255,100)
			elseif happiness > 39 then barFillW.BackgroundColor3 = Color3.fromRGB(255,220,50)
			else barFillW.BackgroundColor3 = Color3.fromRGB(255,80,80) end
		end)

		-- Carry hint
		local bbCarry = Instance.new("BillboardGui",ball)
		bbCarry.Size=UDim2.new(0,130,0,22); bbCarry.StudsOffset=Vector3.new(0,-2.5,0)
		local carryHint=Instance.new("TextLabel",bbCarry)
		carryHint.Size=UDim2.new(1,0,1,0); carryHint.BackgroundTransparency=1
		carryHint.Text="[ Click to carry ]"
		carryHint.TextColor3=Color3.fromRGB(200,200,200)
		carryHint.TextStrokeTransparency=0.5
		carryHint.Font=Enum.Font.Gotham; carryHint.TextSize=12

		-- ClickDetector carry
		local ballCD = Instance.new("ClickDetector",ball)
		ballCD.MaxActivationDistance = 25
		ballCD.MouseClick:Connect(function()
			if isCarrying then
				stopCarry(); carryHint.Text="[ Click to carry ]"
			else
				startCarry(); carryHint.Text="[ Click to put down ]"
			end
		end)

		npcModel.PrimaryPart = ball
		npcModel.Parent = workspace

		-- Spawn dari atas + jatuh bounce
		ball.CFrame = CFrame.new(base+Vector3.new(0,10,0))
		local floorY = findFloorY(base+Vector3.new(0,10,0))
		tw(ball,1.0,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,
			CFrame.new(base.X,floorY,base.Z)):Play()
		task.wait(1.2)

		updateHappinessUI()

		-- Greeting setelah beberapa detik
		task.wait(GREETING_DELAY)
		showReply("Hello! I'm Unrity. Your personal helper friend, ask me anything. I know everything~", nil)
	end)
end

local ok, err = pcall(spawnBox)
if not ok then warn("[Unrity] Error: "..tostring(err)) end

print("[Unrity] v6 ready! Klik box buat buka. Ketik 'unrity <tanya>' di chat.")
