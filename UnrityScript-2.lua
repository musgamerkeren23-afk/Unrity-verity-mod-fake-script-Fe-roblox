--[[
	UnrityScript.lua
	Cara pake: loadstring dari raw GitHub URL lewat executor (kayak script hub lainnya)

	Konsep:
	- Player ngetik pertanyaan di chat Roblox biasa, diawalin kata "unrity"
	  contoh: "unrity halo apa kabar" atau "unrity, kamu tau thatmob gak?"
	- Script nangkep chat itu, kirim ke AI API (via proxy server lo),
	  terus jawabannya ditampilin di GUI portrait Unrity (pojok layar)
	- Kalau pertanyaan ngandung kata trigger (thatmob/twixxel),
	  portrait berubah jadi ekspresi serem

	⚠️ WAJIB DIISI SEBELUM DIPAKE:
	1. PROXY_URL     -> URL proxy server lo (yang nyimpen API key AI dengan aman)
	2. IMAGE_NORMAL  -> Roblox Asset ID gambar wajah Unrity normal (rbxassetid://...)
	3. IMAGE_CREEPY  -> Roblox Asset ID gambar wajah Unrity serem
	   (upload gambar portrait ke Roblox lewat roblox.com/create dulu buat dapetin ID-nya)
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== KONFIGURASI =====
local PROXY_URL = "https://raspy-dream-5ef3.musgamerkeren23.workers.dev/"
local IMAGE_NORMAL = "rbxassetid://112701249837828" -- ganti dengan asset ID wajah normal
local IMAGE_CREEPY = "rbxassetid://138302570100042" -- ganti dengan asset ID wajah serem
local TRIGGER_WORD = "unrity" -- kata pemicu di chat, mis: "unrity ..."
local CREEPY_KEYWORDS = { "thatmob", "twixxel" }
local REPLY_DISPLAY_SECONDS = 8

-- ===== CARI FUNGSI HTTP YANG TERSEDIA DI EXECUTOR =====
local function getHttpRequestFn()
	if syn and syn.request then
		return syn.request
	elseif http_request then
		return http_request
	elseif request then
		return request
	elseif fluxus and fluxus.request then
		return fluxus.request
	end
	return nil
end

local httpRequest = getHttpRequestFn()

-- ===== BIKIN GUI PORTRAIT UNRITY =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnrityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local portraitFrame = Instance.new("Frame")
portraitFrame.Size = UDim2.new(0, 90, 0, 110)
portraitFrame.Position = UDim2.new(1, -110, 0, 20) -- pojok kanan atas
portraitFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
portraitFrame.BackgroundTransparency = 0.15
portraitFrame.Visible = false
portraitFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = portraitFrame

local portraitImage = Instance.new("ImageLabel")
portraitImage.Size = UDim2.new(1, -10, 0, 70)
portraitImage.Position = UDim2.new(0, 5, 0, 5)
portraitImage.BackgroundTransparency = 1
portraitImage.Image = IMAGE_NORMAL
portraitImage.Parent = portraitFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 16)
nameLabel.Position = UDim2.new(0, 0, 0, 76)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Unrity"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 12
nameLabel.Parent = portraitFrame

local replyBubble = Instance.new("TextLabel")
replyBubble.Size = UDim2.new(0, 220, 0, 0)
replyBubble.AutomaticSize = Enum.AutomaticSize.Y
replyBubble.Position = UDim2.new(1, -330, 0, 20)
replyBubble.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
replyBubble.BackgroundTransparency = 0.15
replyBubble.TextColor3 = Color3.fromRGB(255, 255, 255)
replyBubble.Font = Enum.Font.Gotham
replyBubble.TextSize = 14
replyBubble.TextWrapped = true
replyBubble.Text = ""
replyBubble.Visible = false
replyBubble.Parent = screenGui

local bubbleCorner = Instance.new("UICorner")
bubbleCorner.CornerRadius = UDim.new(0, 8)
bubbleCorner.Parent = replyBubble

local bubblePadding = Instance.new("UIPadding")
bubblePadding.PaddingLeft = UDim.new(0, 10)
bubblePadding.PaddingRight = UDim.new(0, 10)
bubblePadding.PaddingTop = UDim.new(0, 8)
bubblePadding.PaddingBottom = UDim.new(0, 8)
bubblePadding.Parent = replyBubble

-- ===== HELPER: cek kata trigger serem =====
local function containsCreepyKeyword(text)
	local lowerText = string.lower(text)
	for _, keyword in ipairs(CREEPY_KEYWORDS) do
		if string.find(lowerText, keyword) then
			return true
		end
	end
	return false
end

-- ===== HELPER: panggil AI proxy =====
local function callAI(question)
	if not httpRequest then
		return "Executor lo gak support HTTP request, gak bisa nyambung ke AI :("
	end

	local success, result = pcall(function()
		local response = httpRequest({
			Url = PROXY_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = game:GetService("HttpService"):JSONEncode({
				message = question,
				system = "Kamu adalah Unrity, AI companion ramah di Roblox. Jawab singkat 1-2 kalimat, natural.",
			}),
		})
		local body = response.Body or response.body
		local decoded = game:GetService("HttpService"):JSONDecode(body)
		return decoded.reply
	end)

	if success and result then
		return result
	end
	return "Hmm, aku lagi susah mikir sekarang. Coba tanya lagi ya!"
end

-- ===== TAMPILIN JAWABAN =====
local hideThread = nil
local function showReply(text, isCreepy)
	portraitFrame.Visible = true
	replyBubble.Visible = true
	replyBubble.Text = text
	portraitImage.Image = isCreepy and IMAGE_CREEPY or IMAGE_NORMAL

	if hideThread then
		task.cancel(hideThread)
	end
	hideThread = task.delay(REPLY_DISPLAY_SECONDS, function()
		replyBubble.Visible = false
		portraitImage.Image = IMAGE_NORMAL
	end)
end

-- ===== HANDLE PERTANYAAN =====
local isProcessing = false
local function handleQuestion(rawMessage)
	if isProcessing then
		return
	end

	local lowerMsg = string.lower(rawMessage)
	local triggerStart = string.find(lowerMsg, TRIGGER_WORD, 1, true)
	if not triggerStart then
		return
	end

	-- ambil teks setelah kata "unrity"
	local question = string.sub(rawMessage, triggerStart + #TRIGGER_WORD)
	question = question:gsub("^[%s,:%-]+", "") -- buang spasi/koma di awal

	if #question == 0 then
		question = "halo"
	end

	isProcessing = true
	local isCreepy = containsCreepyKeyword(rawMessage)
	local reply = callAI(question)
	showReply(reply, isCreepy)
	isProcessing = false
end

-- ===== HOOK KE CHAT ROBLOX =====
-- Coba pake TextChatService (chat system baru)
local success = pcall(function()
	local generalChannel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5)
	if generalChannel then
		generalChannel.MessageReceived:Connect(function(textChatMessage)
			if textChatMessage.TextSource and textChatMessage.TextSource.UserId == player.UserId then
				handleQuestion(textChatMessage.Text)
			end
		end)
	end
end)

-- Fallback ke sistem chat lama kalau TextChatService gak ada
if not success then
	player.Chatted:Connect(function(message)
		handleQuestion(message)
	end)
end

print("[Unrity] Script ready. Ketik 'unrity <pertanyaan>' di chat buat ngobrol.")
