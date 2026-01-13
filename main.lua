local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local player = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- 1. HỆ THỐNG LƯU TRỮ THEO USERNAME
local fileName = "CayThue_V5_Data_" .. player.Name .. ".txt"

_G.Data = {
    IsRecording = false,
    TargetLevel = 0,
    StartLevel = player.Data.Level.Value,
    LastLevel = player.Data.Level.Value, -- Dùng để check lv nhảy
    StartBeli = player.Data.Beli.Value,
    LastBeli = player.Data.Beli.Value, -- Dùng để check tiền triệu
    TotalSeconds = 0,
    FruitCount = 0,
    TotalVND = 0
}

local function Save()
    if writefile then writefile(fileName, HttpService:JSONEncode(_G.Data)) end
end

local function Load()
    if isfile and isfile(fileName) then
        local content = readfile(fileName)
        local success, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if success then _G.Data = decoded end
    end
end
Load()

-- 2. ANTI-AFK CHUYÊN NGHIỆP
local vu = game:GetService("VirtualUser")
player.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- 3. GIAO DIỆN
local Window = Rayfield:CreateWindow({
    Name = "HỆ THỐNG CÀY THUÊ TỰ ĐỘNG",
    LoadingTitle = "Đang tải dữ liệu khách hàng...",
    LoadingSubtitle = "Account: " .. player.DisplayName,
})

-- TAB 1: NHẬN ĐƠN
local MainTab = Window:CreateTab("Nhận Đơn", 4483362458)

MainTab:CreateInput({
    Name = "Nhập Level Mục Tiêu",
    PlaceholderText = "Ví dụ: 2550",
    Callback = function(Text)
        local val = tonumber(Text)
        if val and val > player.Data.Level.Value then
            _G.Data.TargetLevel = val
            Save()
            Rayfield:Notify({Title = "Hệ thống", Content = "Mục tiêu mới: Lv." .. val})
        end
    end,
})

MainTab:CreateToggle({
    Name = "KÍCH HOẠT TÍNH TIỀN",
    CurrentValue = _G.Data.IsRecording,
    Callback = function(v) 
        if _G.Data.TargetLevel <= player.Data.Level.Value then
            Rayfield:Notify({Title = "Lỗi", Content = "Hãy nhập Level mục tiêu trước!"})
            return 
        end
        _G.Data.IsRecording = v 
        Save() 
    end
})

-- TAB 2: DASHBOARD
local DashTab = Window:CreateTab("Dashboard", 4483362458)
local MoneyLabel = DashTab:CreateLabel("TỔNG TIỀN: 0 VNĐ")
local ProgressLabel = DashTab:CreateLabel("Tiến độ: 0%")
local TimeLabel = DashTab:CreateLabel("Thời gian đã cày: 00:00:00")

-- TAB 3: LOG & CHI PHÍ
local LogTab = Window:CreateTab("Log & Chi Phí", 4483362458)
local LogContent = LogTab:CreateLabel("--- Nhật ký hóa đơn ---")

-- 4. VÒNG LẶP CHÍNH (REALTIME)
task.spawn(function()
    while task.wait(1) do
        if _G.Data.IsRecording then
            _G.Data.TotalSeconds = _G.Data.TotalSeconds + 1
            local curLv = player.Data.Level.Value
            local curBeli = player.Data.Beli.Value
            
            -- Tự động cộng tiền khi nhảy Level (140đ/lv)
            if curLv > _G.Data.LastLevel then
                _G.Data.TotalVND = _G.Data.TotalVND + ((curLv - _G.Data.LastLevel) * 140)
                _G.Data.LastLevel = curLv
            end
            
            -- Tự động cộng tiền khi cày đủ 1M Beli (1000đ)
            local diffBeli = curBeli - _G.Data.LastBeli
            if diffBeli >= 1000000 then
                _G.Data.TotalVND = _G.Data.TotalVND + 1000
                _G.Data.LastBeli = curBeli
            end
            
            -- Tự động cộng tiền theo thời gian (83đ/phút)
            if _G.Data.TotalSeconds % 60 == 0 then
                _G.Data.TotalVND = _G.Data.TotalVND + 83
            end
            
            -- Tính % tiến độ
            local targetNeed = _G.Data.TargetLevel - _G.Data.StartLevel
            local lvGained = curLv - _G.Data.StartLevel
            local percent = math.min(math.floor((lvGained / targetNeed) * 100), 100)

            -- Cập nhật giao diện
            MoneyLabel:SetText("TỔNG TIỀN: " .. math.floor(_G.Data.TotalVND) .. " VNĐ")
            ProgressLabel:SetText("Tiến độ: " .. percent .. "% (Đã cày " .. lvGained .. " Lv)")
            
            local h, m, s = math.floor(_G.Data.TotalSeconds/3600), math.floor((_G.Data.TotalSeconds%3600)/60), _G.Data.TotalSeconds%60
            TimeLabel:SetText(string.format("Thời gian: %02d:%02d:%02d", h, m, s))
            
            LogContent:SetText(string.format("Chi tiết:\n- Tiền Level: %dđ\n- Tiền Time: %dđ\n- Tiền Trái (%d): %dđ", 
                (lvGained * 140), math.floor((_G.Data.TotalSeconds/60)*83), _G.Data.FruitCount, (_G.Data.FruitCount * 4000)))

            if percent >= 100 then
                _G.Data.IsRecording = false
                Rayfield:Notify({Title = "HOÀN THÀNH", Content = "Đã đạt mục tiêu!"})
            end
            
            if _G.Data.TotalSeconds % 20 == 0 then Save() end
        end
    end
end)

-- THEO DÕI NHẶT TRÁI
player.Backpack.ChildAdded:Connect(function(child)
    if _G.Data.IsRecording and child:IsA("Tool") and child.Name:find("Fruit") and not child.Name:find("Common") then
        _G.Data.FruitCount = _G.Data.FruitCount + 1
        _G.Data.TotalVND = _G.Data.TotalVND + 4000
        Save()
        Rayfield:Notify({Title = "Nhặt Trái", Content = "Đã phát hiện trái mới (+4.000đ)"})
    end
end)

-- TAB CÀI ĐẶT
local SettingTab = Window:CreateTab("Cài Đặt", 4483362458)
SettingTab:CreateButton({
    Name = "RESET DATA ACC NÀY",
    Callback = function() 
        delfile(fileName) 
        game:GetService("TeleportService"):Teleport(game.PlaceId) 
    end
})
