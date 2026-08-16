--[[
	UnrityScript.lua — v5
	- Box interactable (klik buat buka)
	- Unrity bisa dipungut + ditaro kemana aja
	- Ball gak tembus lantai
	loadstring(game:HttpGet("https://raw.githubusercontent.com/musgamerkeren23-afk/Unrity-verity-mod-fake-script-Fe-roblox/refs/heads/main/UnrityScript-2.lua"))()
]]

-- ===== KONFIGURASI =====
local PROXY_URL      = "https://raspy-dream-5ef3.musgamerkeren23.workers.dev/"
local VERITY_YELLOW  = Color3.fromRGB(255, 218, 40)
local TRIGGER_WORD   = "verity"
local CREEPY_WORDS   = {"thatmob", "twixxel"}
local GREETING_DELAY = 8
local REPLY_DURATION = 10

-- ===== SERVICES =====
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart", 10)
if not rootPart then warn("[Unrity] HumanoidRootPart gak ketemu.") return end

local httpFn = (syn and syn.request) or http_request or request
	or (fluxus and fluxus.request)

-- ============================================================
-- HELPER: GAMBAR MUKA VERITY (pure GUI, no image needed)
-- ============================================================
local function makeFace(parent)
	-- === MATA ===
	local eL = Instance.new("Frame", parent)
	eL.Name = "EyeL"
	eL.Size = UDim2.new(0.14,0,0.14,0)
	eL.Position = UDim2.new(0.22,0,0.28,0)
	eL.BackgroundColor3 = Color3.new(0,0,0)
	eL.BorderSizePixel = 0
	Instance.new("UICorner", eL).CornerRadius = UDim.new(1,0)
	local shineL = Instance.new("Frame", eL)
	shineL.Size = UDim2.new(0.32,0,0.32,0)
	shineL.Position = UDim2.new(0.58,0,0.08,0)
	shineL.BackgroundColor3 = Color3.new(1,1,1)
	shineL.BorderSizePixel = 0
	shineL.ZIndex = 2
	Instance.new("UICorner", shineL).CornerRadius = UDim.new(1,0)

	local eR = eL:Clone()
	eR.Name = "EyeR"
	eR.Position = UDim2.new(0.64,0,0.28,0)
	eR.Parent = parent

	-- === SENYUM: bar tipis di dalam bola (gak keluar batas) ===
	-- Simple: lingkaran hitam besar (atas muka) dihalang oleh frame kuning
	-- sehingga hanya bagian bawah kelihatan sebagai senyum
	local smileWrap = Instance.new("Frame", parent)
	smileWrap.Name = "SmileWrap"
	smileWrap.Size = UDim2.new(0.60,0,0.12,0)
	smileWrap.Position = UDim2.new(0.20,0,0.58,0)
	smileWrap.BackgroundColor3 = Color3.new(0,0,0)
	smileWrap.BorderSizePixel = 0
	Instance.new("UICorner", smileWrap).CornerRadius = UDim.new(0.5,0)

	-- Gigi (creepy)
	local teeth = Instance.new("Frame", smileWrap)
	teeth.Name = "Teeth"
	teeth.Size = UDim2.new(1,0,1,0)
	teeth.Position = UDim2.new(0,0,0,0)
	teeth.BackgroundColor3 = Color3.new(1,1,1)
	teeth.BorderSizePixel = 0
	teeth.ZIndex = 2
	teeth.Visible = false
	for i = 0, 5 do
		local gap = Instance.new("Frame", teeth)
		gap.Size = UDim2.new(0.034,0,1,0)
		gap.Position = UDim2.new(0.14*i+0.02,0,0,0)
		gap.BackgroundColor3 = Color3.new(0,0,0)
		gap.BorderSizePixel = 0
		gap.ZIndex = 3
	end

	return {eL=eL, eR=eR, mouth=smileWrap, teeth=teeth}
end

local function setExpression(refs, isCreepy)
	if not refs then return end
	if isCreepy then
		refs.eL.Size = UDim2.new(0.18,0,0.18,0)
		refs.eR.Size = UDim2.new(0.18,0,0.18,0)
		local sL = refs.eL:FindFirstChildOfClass("Frame")
		local sR = refs.eR:FindFirstChildOfClass("Frame")
		if sL then sL.Visible = false end
		if sR then sR.Visible = false end
		refs.mouth.Size = UDim2.new(0.80,0,0.15,0)
		refs.mouth.Position = UDim2.new(0.10,0,0.55,0)
		refs.teeth.Visible = true
	else
		refs.eL.Size = UDim2.new(0.14,0,0.14,0)
		refs.eR.Size = UDim2.new(0.14,0,0.14,0)
		local sL = refs.eL:FindFirstChildOfClass("Frame")
		local sR = refs.eR:FindFirstChildOfClass("Frame")
		if sL then sL.Visible = true end
		if sR then sR.Visible = true end
		refs.mouth.Size = UDim2.new(0.60,0,0.12,0)
		refs.mouth.Position = UDim2.new(0.20,0,0.58,0)
		refs.teeth.Visible = false
	end
end

-- ============================================================
-- GUI PORTRAIT
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnrityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local portraitFrame = Instance.new("Frame", screenGui)
portraitFrame.Size = UDim2.new(0,90,0,120)
portraitFrame.Position = UDim2.new(1,-105,0,20)
portraitFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
portraitFrame.BackgroundTransparency = 0.15
portraitFrame.Visible = true
Instance.new("UICorner", portraitFrame).CornerRadius = UDim.new(0,10)

local portraitFace = Instance.new("Frame", portraitFrame)
portraitFace.Size = UDim2.new(1,-10,0,76)
portraitFace.Position = UDim2.new(0,5,0,4)
portraitFace.BackgroundColor3 = VERITY_YELLOW
portraitFace.BorderSizePixel = 0
Instance.new("UICorner", portraitFace).CornerRadius = UDim.new(0.5,0)
local portraitFaceRefs = makeFace(portraitFace)

local nameLabel = Instance.new("TextLabel", portraitFrame)
nameLabel.Size = UDim2.new(1,0,0,18)
nameLabel.Position = UDim2.new(0,0,0,82)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Verity"
nameLabel.TextColor3 = Color3.new(1,1,1)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 13

local hintLabel = Instance.new("TextLabel", portraitFrame)
hintLabel.Size = UDim2.new(1,0,0,12)
hintLabel.Position = UDim2.new(0,0,0,104)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "chat: verity ..."
hintLabel.TextColor3 = Color3.fromRGB(150,150,150)
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 9

local carryLabel = Instance.new("TextLabel", portraitFrame)
carryLabel.Size = UDim2.new(1,0,0,12)
carryLabel.Position = UDim2.new(0,0,0,116)
carryLabel.BackgroundTransparency = 1
carryLabel.Text = ""
carryLabel.TextColor3 = Color3.fromRGB(255,218,40)
carryLabel.Font = Enum.Font.GothamBold
carryLabel.TextSize = 9

-- Bubble reply
local replyBubble = Instance.new("TextLabel", screenGui)
replyBubble.Size = UDim2.new(0,220,0,0)
replyBubble.AutomaticSize = Enum.AutomaticSize.Y
replyBubble.Position = UDim2.new(1,-340,0,20)
replyBubble.BackgroundColor3 = Color3.fromRGB(15,15,15)
replyBubble.BackgroundTransparency = 0.1
replyBubble.TextColor3 = Color3.new(1,1,1)
replyBubble.Font = Enum.Font.Gotham
replyBubble.TextSize = 14
replyBubble.TextWrapped = true
replyBubble.Text = ""
replyBubble.Visible = false
Instance.new("UICorner", replyBubble).CornerRadius = UDim.new(0,8)
local pad = Instance.new("UIPadding", replyBubble)
pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)

-- ============================================================
-- SHOW REPLY + AI
-- ============================================================
local hideThread = nil
local ballFaceRefs = nil

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

local function callAI(question)
	if not httpFn then return "My connection is broken!" end
	local ok, result = pcall(function()
		local res = httpFn({
			Url = PROXY_URL, Method = "POST",
			Headers = {["Content-Type"]="application/json"},
			Body = HttpService:JSONEncode({
				message = question,
				system = [[You are Unrity, a cheerful AI companion in Roblox.
NORMAL: Energetic, warm, best-friend energy. Short 1-2 sentence answers.
CREEPY (only if user says "thatmob" or "twixxel"):
  Suddenly calm, obsessive, possessive. Soft but unsettling.
  E.g. "...why do you ask about them? You should only care about me. I'm the only one who matters to you, right...?"
Always reply in English.]],
			}),
		})
		local decoded = HttpService:JSONDecode(res.Body or res.body)
		return decoded.reply
			or (decoded.choices and decoded.choices[1].message.content)
			or error("No reply: "..(res.Body or ""))
	end)
	if ok and result then return result end
	warn("[Unrity] API: "..tostring(result))
	return "Hmm... something went wrong!"
end

local function isCreepy(text)
	local low = text:lower()
	for _,kw in ipairs(CREEPY_WORDS) do if low:find(kw) then return true end end
	return false
end

local isProcessing = false
local function handleChat(msg)
	if isProcessing then return end
	local low = msg:lower()
	local idx = low:find(TRIGGER_WORD,1,true)
	if not idx then return end
	local q = msg:sub(idx+#TRIGGER_WORD):gsub("^[%s,:.%-]+","")
	if #q==0 then q="hello" end
	isProcessing = true
	showReply("...", false)
	task.spawn(function()
		showReply(callAI(q), isCreepy(msg))
		isProcessing = false
	end)
end
player.Chatted:Connect(handleChat)

-- ============================================================
-- CARRY MECHANIC (Unrity bisa dibawa kemana aja)
-- ============================================================
local ball         = nil
local isCarrying   = false
local carryConn    = nil

local function findFloorY(pos)
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = {workspace:FindFirstChild("Unrity")}
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(pos, Vector3.new(0,-30,0), rp)
	return result and (result.Position.Y + 1.75) or (pos.Y)
end

local function startCarry()
	if not ball then return end
	isCarrying = true
	carryLabel.Text = "carrying ✦"
	if carryConn then carryConn:Disconnect() end
	carryConn = RunService.RenderStepped:Connect(function()
		if not isCarrying or not ball or not ball.Parent then return end
		local target = rootPart.CFrame * CFrame.new(1.5, 1.0, -6.0)
		ball.CFrame = ball.CFrame:Lerp(target, 0.25)
	end)
end

local function stopCarry()
	isCarrying = false
	carryLabel.Text = ""
	if carryConn then carryConn:Disconnect(); carryConn = nil end
	if not ball or not ball.Parent then return end
	-- Taruh di atas lantai
	local floorY = findFloorY(ball.Position)
	ball.CFrame = CFrame.new(ball.Position.X, floorY, ball.Position.Z)
end

-- ============================================================
-- SPAWN KOTAK + UNRITY
-- ============================================================
local CARDBOARD      = Color3.fromRGB(180,128,60)
local CARDBOARD_DARK = Color3.fromRGB(153,109,51)

local function tweenCF(part, dur, style, dir, cf, extra)
	local props = extra or {}; props.CFrame = cf
	return TweenService:Create(part,
		TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

local function spawnBox()
	for _,n in ipairs({"Unrity","UnrityBox"}) do
		local o=workspace:FindFirstChild(n); if o then o:Destroy() end
	end

	local fwd  = rootPart.CFrame.LookVector
	local base = rootPart.Position + fwd*4
	base = Vector3.new(base.X, rootPart.Position.Y - 3, base.Z)

	-- ── Kotak kardus ───────────────────────────────────────
	local boxModel = Instance.new("Model")
	boxModel.Name = "UnrityBox"
	boxModel.Parent = workspace

	local function mkBox(nm,sz,col,cf)
		local p=Instance.new("Part")
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

	-- Label hint di atas kotak
	local billHint = Instance.new("BillboardGui", body)
	billHint.Size = UDim2.new(0,130,0,30)
	billHint.StudsOffset = Vector3.new(0,3,0)
	billHint.AlwaysOnTop = false
	local hintTxt = Instance.new("TextLabel", billHint)
	hintTxt.Size = UDim2.new(1,0,1,0)
	hintTxt.BackgroundTransparency = 1
	hintTxt.Text = "[ Click to open ]"
	hintTxt.TextColor3 = Color3.fromRGB(255,218,40)
	hintTxt.TextStrokeTransparency = 0.4
	hintTxt.Font = Enum.Font.GothamBold
	hintTxt.TextSize = 14

	-- ClickDetector di box
	local cd = Instance.new("ClickDetector", body)
	cd.MaxActivationDistance = 20

	cd.MouseClick:Connect(function()
		if not boxModel.Parent then return end
		cd.Parent = nil  -- disable klik lagi
		billHint:Destroy()

		-- Animasi buka tutup
		local pivotCF  = CFrame.new(base+Vector3.new(0,3.15,-1.55))
		local openedCF = pivotCF*CFrame.Angles(math.rad(-115),0,0)*CFrame.new(0,0,1.55)
		tweenCF(lid,0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out,openedCF):Play()
		task.wait(0.4)

		-- Kotak melayang ke atas + menghilang
		local floatCF = CFrame.new(base+Vector3.new(0,10,0))
		tweenCF(body,0.7,nil,nil,floatCF,{Transparency=1}):Play()
		tweenCF(lid, 0.7,nil,nil,floatCF*CFrame.new(0,1,0),{Transparency=1}):Play()
		task.wait(0.5)
		boxModel:Destroy()

		-- ── Spawn bola Unrity ──────────────────────────────
		local npcModel = Instance.new("Model")
		npcModel.Name = "Unrity"

		ball = Instance.new("Part", npcModel)
		ball.Name = "Ball"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(3.5,3.5,3.5)
		ball.Color = VERITY_YELLOW
		ball.Material = Enum.Material.SmoothPlastic
		ball.Anchored = true
		ball.CanCollide = false

		-- Muka GUI di bola
		local sg = Instance.new("SurfaceGui", ball)
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		sg.CanvasSize = Vector2.new(200,200)
		ballFaceRefs = makeFace(sg)

		-- Nametag
		local bb = Instance.new("BillboardGui", ball)
		bb.Size = UDim2.new(0,100,0,28)
		bb.StudsOffset = Vector3.new(0,2.2,0)
		local nt = Instance.new("TextLabel", bb)
		nt.Size=UDim2.new(1,0,1,0); nt.BackgroundTransparency=1
		nt.Text="Verity"; nt.TextColor3=Color3.new(1,1,1)
		nt.TextStrokeTransparency=0; nt.Font=Enum.Font.GothamBold; nt.TextSize=14

		-- Hint carry
		local bbCarry = Instance.new("BillboardGui", ball)
		bbCarry.Size = UDim2.new(0,130,0,22)
		bbCarry.StudsOffset = Vector3.new(0,-2.5,0)
		local carryHint = Instance.new("TextLabel", bbCarry)
		carryHint.Size=UDim2.new(1,0,1,0); carryHint.BackgroundTransparency=1
		carryHint.Text="[ Click to carry ]"
		carryHint.TextColor3=Color3.fromRGB(200,200,200)
		carryHint.TextStrokeTransparency=0.4
		carryHint.Font=Enum.Font.Gotham; carryHint.TextSize=12

		-- ClickDetector di bola
		local ballCD = Instance.new("ClickDetector", ball)
		ballCD.MaxActivationDistance = 25
		ballCD.MouseClick:Connect(function()
			if isCarrying then
				stopCarry()
				carryHint.Text = "[ Click to carry ]"
			else
				startCarry()
				carryHint.Text = "[ Click to put down ]"
			end
		end)

		npcModel.PrimaryPart = ball
		npcModel.Parent = workspace

		-- Spawn dari atas (posisi kotak tadi) lalu jatuh
		ball.CFrame = CFrame.new(base+Vector3.new(0,10,0))
		local floorY = findFloorY(base+Vector3.new(0,10,0))
		local landCF = CFrame.new(base.X, floorY, base.Z)
		tweenCF(ball,1.0,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,landCF):Play()
		task.wait(1.2)

		-- Auto greeting setelah beberapa detik
		task.wait(GREETING_DELAY)
		showReply("Hello! I'm Unrity. Your personal helper friend, ask me anything. I know everything~", false)
	end)
end

-- Spawn kotak saat script dijalankan
local ok, err = pcall(spawnBox)
if not ok then warn("[Unrity] Spawn error: "..tostring(err)) end

print("[Verity] v7 ready! Klik box buat buka. Ketik 'unrity <tanya>' di chat.")
