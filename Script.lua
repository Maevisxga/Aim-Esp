-- Integrated Hack Script con Aimbot, Wall-Check, ESP Estético y Funcional,
-- Limpieza de ESP con F1 y al morir,
-- Avatar & Account Info, Indie Flower Font,
-- Session Playtime Tracking con Recordatorios “Touch Grass”

local UserInputService = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local StarterGui        = game:GetService("StarterGui")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

----------------------------------------------------------------
-- Variables de Aimbot, Wall-Check & ESP & Session
----------------------------------------------------------------
local fovRadius             = 60
local aimbotEnabled         = true
local wallCheckEnabled      = false
local currentAimbotTarget   = nil

local espEnabled            = false
-- toggles individuales de ESP
local espShowBox            = true
local espShowHealth         = true
local espShowName           = true
local espShowDistance       = true
local espShowTool           = true
local espData               = {}

local sessionTrackingEnabled = true
local sessionStartTime      = tick()
local sessionTime           = 0
local sessionTimeLabel

local breakIntervals = {
    { time = 1800, message = "30 minutos? Deberías salir a tomar aire." },
    { time = 3600, message = "1 hora?! Tómate un descanso, amigo." },
    { time = 7200, message = "2 horas seguidas! En serio, descansa un poco." },
}
local triggered = {}

----------------------------------------------------------------
-- Formatea segundos a HH:MM:SS
----------------------------------------------------------------
local function formatTime(s)
    local h = math.floor(s/3600)
    local m = math.floor((s%3600)/60)
    local sec = math.floor(s%60)
    return string.format("%02d:%02d:%02d", h, m, sec)
end

----------------------------------------------------------------
-- Limpia todos los elementos de ESP
----------------------------------------------------------------
local function clearESP()
    for _, data in pairs(espData) do
        for _, ln in pairs(data.box) do ln:Remove() end
        data.health:Remove()
        data.damage:Remove()
        data.nameTxt:Remove()
        data.distTxt:Remove()
        data.toolTxt:Remove()
    end
    espData = {}
end

----------------------------------------------------------------
-- Envía una notificación
----------------------------------------------------------------
local function sendNotification(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title    = title,
        Text     = text,
        Duration = duration or 3,
    })
end

----------------------------------------------------------------
-- Seguimiento de tiempo de sesión
----------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1)
        if sessionTrackingEnabled then
            sessionTime = tick() - sessionStartTime
            if sessionTimeLabel then
                sessionTimeLabel.Text = "Session Time: " .. formatTime(sessionTime)
            end
            for i, data in ipairs(breakIntervals) do
                if sessionTime >= data.time and not triggered[i] then
                    sendNotification("Tómate un Descanso", data.message, 5)
                    triggered[i] = true
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- Creación de la UI y controles
----------------------------------------------------------------
local Keybinds = {
    UIToggle = Enum.KeyCode.U,
    ClearESP = Enum.KeyCode.F1,
}

local screenGui, mainFrame, hackFrame, infoFrame
local closeButton, aimbotButton, wallCheckButton, sessionButton
local fovSliderLabel, fovSlider, fovKnob

-- Info del jugador
local userId      = player.UserId
local userName    = player.Name
local displayName = player.DisplayName
local membership  = tostring(player.MembershipType)
local dateJoined  = os.date("%c", os.time() - player.AccountAge * 24 * 3600)

-- Avatar thumbnail
local thumbnailUrl = Players:GetUserThumbnailAsync(
    userId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size420x420
)

local function createToggleButton(parent, name, label, position)
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.Text             = label
    btn.Size             = UDim2.new(1, -20, 0, 40)
    btn.Position         = position
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.IndieFlower
    btn.TextScaled       = true
    btn.Parent           = parent

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color     = Color3.new(0,0,0)
    stroke.Thickness = 2

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(90,90,90) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70,70,70) }):Play()
    end)

    return btn
end

function createUI()
    screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screenGui.Name         = "HackUI"
    screenGui.ResetOnSpawn = false

    mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size, mainFrame.Position = UDim2.new(0,600,0,550), UDim2.new(0.5,-300,0.5,-275)
    mainFrame.BackgroundColor3, mainFrame.BackgroundTransparency = Color3.fromRGB(30,30,30), 0.1
    mainFrame.Active, mainFrame.Draggable, mainFrame.Visible = true, true, false
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

    -- Cerrar
    closeButton = Instance.new("TextButton", mainFrame)
    closeButton.Size, closeButton.Position = UDim2.new(0,30,0,30), UDim2.new(1,-35,0,5)
    closeButton.BackgroundColor3, closeButton.Text = Color3.fromRGB(200,0,0), "X"
    closeButton.TextColor3, closeButton.Font, closeButton.TextScaled = Color3.new(1,1,1), Enum.Font.IndieFlower, true
    Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", closeButton).Thickness = 2
    closeButton.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

    -- Panel izquierdo
    hackFrame = Instance.new("Frame", mainFrame)
    hackFrame.Size, hackFrame.Position = UDim2.new(0,320,1,0), UDim2.new(0,0,0,0)
    hackFrame.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", hackFrame)
    title.Size, title.Position, title.Text = UDim2.new(1,0,0,40), UDim2.new(0,0,0,0),"Hack Control Panel"
    title.BackgroundTransparency, title.TextColor3, title.Font, title.TextScaled = 1, Color3.new(1,1,1), Enum.Font.IndieFlower, true

    -- Aim Settings
    local aimLabel = Instance.new("TextLabel", hackFrame)
    aimLabel.Size, aimLabel.Position = UDim2.new(1,-20,0,24), UDim2.new(0,10,0,50)
    aimLabel.BackgroundTransparency, aimLabel.TextColor3, aimLabel.Font, aimLabel.TextScaled = 1, Color3.new(1,1,1), Enum.Font.IndieFlower, true
    aimLabel.Text = "Aim Settings"

    aimbotButton = createToggleButton(hackFrame, "AimbotToggle", "Aimbot: ON", UDim2.new(0,10,0,80))
    aimbotButton.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        sendNotification("Aimbot", "Aimbot "..(aimbotEnabled and "Enabled" or "Disabled"))
        aimbotButton.Text = "Aimbot: "..(aimbotEnabled and "ON" or "OFF")
    end)

    wallCheckButton = createToggleButton(hackFrame, "WallCheckToggle", "WallCheck: OFF", UDim2.new(0,10,0,130))
    wallCheckButton.MouseButton1Click:Connect(function()
        wallCheckEnabled = not wallCheckEnabled
        sendNotification("Wall-Check", (wallCheckEnabled and "Enabled" or "Disabled"))
        wallCheckButton.Text = "WallCheck: "..(wallCheckEnabled and "ON" or "OFF")
    end)

    fovSliderLabel = Instance.new("TextLabel", hackFrame)
    fovSliderLabel.Size, fovSliderLabel.Position = UDim2.new(1,-20,0,20), UDim2.new(0,10,0,180)
    fovSliderLabel.BackgroundTransparency, fovSliderLabel.TextColor3, fovSliderLabel.Font, fovSliderLabel.TextScaled = 1, Color3.new(1,1,1), Enum.Font.IndieFlower, true
    fovSliderLabel.Text = "FOV: "..fovRadius

    fovSlider = Instance.new("Frame", hackFrame)
    fovSlider.Size, fovSlider.Position = UDim2.new(1,-20,0,20), UDim2.new(0,10,0,210)
    fovSlider.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", fovSlider).CornerRadius = UDim.new(0,8)

    fovKnob = Instance.new("Frame", fovSlider)
    fovKnob.Size = UDim2.new((fovRadius-50)/(300-50),0,1,0)
    fovKnob.Position = UDim2.new((fovRadius-50)/(300-50),-8,0,0)
    fovKnob.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", fovKnob).CornerRadius = UDim.new(0,8)

    local dragging = false
    fovSlider.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; mainFrame.Draggable=false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local mx = inp.Position.X
            local left,width = fovSlider.AbsolutePosition.X, fovSlider.AbsoluteSize.X
            local rel = math.clamp(mx-left,0,width)
            fovRadius = 50 + (rel/width)*(300-50)
            fovKnob.Position = UDim2.new(rel/width,-8,0,0)
            fovSliderLabel.Text = "FOV: "..math.floor(fovRadius)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false; mainFrame.Draggable=true
        end
    end)

    -- Visual Settings
    local visLabel = Instance.new("TextLabel", hackFrame)
    visLabel.Size, visLabel.Position = UDim2.new(1,-20,0,24), UDim2.new(0,10,0,260)
    visLabel.BackgroundTransparency, visLabel.TextColor3, visLabel.Font, visLabel.TextScaled = 1, Color3.new(1,1,1), Enum.Font.IndieFlower, true
    visLabel.Text = "Visual Settings"

    -- ESP general
    local espButton = createToggleButton(hackFrame, "ESPToggle", "ESP: OFF", UDim2.new(0,10,0,300))
    espButton.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        sendNotification("ESP", (espEnabled and "Enabled" or "Disabled"))
        espButton.Text = "ESP: "..(espEnabled and "ON" or "OFF")
        if not espEnabled then clearESP() end
    end)

    -- Session Tracking toggle
    sessionButton = createToggleButton(hackFrame, "SessionToggle", "Session: ON", UDim2.new(0,10,0,350))
    sessionButton.MouseButton1Click:Connect(function()
        sessionTrackingEnabled = not sessionTrackingEnabled
        sendNotification("Session", (sessionTrackingEnabled and "Enabled" or "Disabled"))
        sessionButton.Text = "Session: "..(sessionTrackingEnabled and "ON" or "OFF")
    end)

    -- Toggles individuales de ESP
    local function makeESPToggle(key, text, varName, ypos)
        local btn = createToggleButton(hackFrame, key, text, UDim2.new(0,10,0,ypos))
        btn.MouseButton1Click:Connect(function()
            _G[varName] = not _G[varName]
            sendNotification("ESP "..text:match("%w+"), (_G[varName] and "ON" or "OFF"))
            btn.Text = text:match("%w+")..": "..(_G[varName] and "ON" or "OFF")
            -- ocultar actual
            for _,d in pairs(espData) do
                if varName=="espShowBox" then
                    for _,ln in pairs(d.box) do ln.Visible = _G[varName] end
                elseif varName=="espShowHealth" then
                    d.health.Visible = _G[varName]; d.damage.Visible = _G[varName]
                elseif varName=="espShowName" then
                    d.nameTxt.Visible = _G[varName]
                elseif varName=="espShowDistance" then
                    d.distTxt.Visible = _G[varName]
                elseif varName=="espShowTool" then
                    d.toolTxt.Visible = _G[varName]
                end
            end
        end)
        return btn
    end

    makeESPToggle("ESPBoxToggle",      "Box: ON",      "espShowBox",      380)
    makeESPToggle("ESPHealthToggle",   "Health: ON",   "espShowHealth",   410)
    makeESPToggle("ESPNameToggle",     "Name: ON",     "espShowName",     440)
    makeESPToggle("ESPDistToggle",     "Distance: ON", "espShowDistance", 470)
    makeESPToggle("ESPToolToggle",     "Tool: ON",     "espShowTool",     500)

    -- Panel derecho: info de cuenta
    infoFrame = Instance.new("Frame", mainFrame)
    infoFrame.Size, infoFrame.Position = UDim2.new(0,280,1,0), UDim2.new(0,320,0,0)
    infoFrame.BackgroundTransparency = 1

    local avatarImg = Instance.new("ImageLabel", infoFrame)
    avatarImg.Size, avatarImg.Position = UDim2.new(0,100,0,100), UDim2.new(0,90,0,20)
    avatarImg.BackgroundTransparency, avatarImg.Image = 1, thumbnailUrl

    local y = 130
    local function makeInfo(txt)
        local lbl = Instance.new("TextLabel", infoFrame)
        lbl.Size, lbl.Position = UDim2.new(1,-20,0,30), UDim2.new(0,10,0,y)
        lbl.BackgroundTransparency, lbl.TextColor3, lbl.Font, lbl.TextScaled = 1, Color3.new(1,1,1), Enum.Font.IndieFlower, true
        lbl.Text = txt; y = y + 35
        return lbl
    end

    makeInfo("Username: "     .. userName)
    makeInfo("Display Name: " .. displayName)
    makeInfo("UserID: "       .. userId)
    makeInfo("Membership: "   .. membership)
    makeInfo("Date Joined: "  .. dateJoined)
    sessionTimeLabel = makeInfo("Session Time: 00:00:00")
end

-- Inicializar UI
if not player:WaitForChild("PlayerGui"):FindFirstChild("HackUI") then
    createUI()
end

----------------------------------------------------------------
-- Input global
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode==Keybinds.UIToggle then
        mainFrame.Visible = not mainFrame.Visible
    elseif input.KeyCode==Keybinds.ClearESP and espEnabled then
        clearESP()
        sendNotification("ESP", "ESP limpiado", 2)
    end
end)
UserInputService.InputEnded:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        currentAimbotTarget = nil
    end
end)

----------------------------------------------------------------
-- Limpia ESP al morir
----------------------------------------------------------------
player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if espEnabled then clearESP() end
    end)
end)

----------------------------------------------------------------
-- Aimbot & FOV Circle
----------------------------------------------------------------
local fovCircle = Drawing.new("Circle")
fovCircle.Color, fovCircle.Thickness, fovCircle.Transparency, fovCircle.NumSides, fovCircle.Filled =
    Color3.new(1,0,0), 2, 1, 100, false

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    if aimbotEnabled then
        fovCircle.Visible, fovCircle.Position, fovCircle.Radius =
            true, Vector2.new(mousePos.X,mousePos.Y), fovRadius

        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if not currentAimbotTarget then
                local best,bestDist = nil,math.huge
                for _,op in ipairs(Players:GetPlayers()) do
                    if op~=player and op.Character then
                        local head = op.Character:FindFirstChild("Head")
                        if head then
                            local pt,on = camera:WorldToViewportPoint(head.Position)
                            if on then
                                local sp=Vector2.new(pt.X,pt.Y)
                                local d=(sp-Vector2.new(mousePos.X,mousePos.Y)).Magnitude
                                if d<fovRadius and d<bestDist then
                                    local canSee=true
                                    if wallCheckEnabled then
                                        local params=RaycastParams.new()
                                        params.FilterDescendantsInstances={player.Character}
                                        params.FilterType=Enum.RaycastFilterType.Blacklist
                                        params.IgnoreWater=true
                                        local ray=workspace:Raycast(
                                            camera.CFrame.Position,
                                            (head.Position-camera.CFrame.Position),
                                            params
                                        )
                                        if not (ray and ray.Instance and ray.Instance:IsDescendantOf(op.Character)) then
                                            canSee=false
                                        end
                                    end
                                    if canSee then best,bestDist=head,d end
                                end
                            end
                        end
                    end
                end
                currentAimbotTarget=best
            end
            if currentAimbotTarget and currentAimbotTarget.Parent then
                camera.CFrame=CFrame.new(camera.CFrame.Position, currentAimbotTarget.Position)
            end
        else
            currentAimbotTarget=nil
        end
    else
        fovCircle.Visible=false
        currentAimbotTarget=nil
    end
end)

----------------------------------------------------------------
-- ESP Estético con BoundingBox
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    for _,op in ipairs(Players:GetPlayers()) do
        if op==player then continue end
        local char=op.Character
        if not char then
            if espData[op] then
                for _,ln in pairs(espData[op].box) do ln.Visible=false end
                espData[op].health.Visible=false
                espData[op].damage.Visible=false
                espData[op].nameTxt.Visible=false
                espData[op].distTxt.Visible=false
                espData[op].toolTxt.Visible=false
            end
            continue
        end
        local humanoid=char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health<=0 then
            if espData[op] then
                for _,ln in pairs(espData[op].box) do ln.Visible=false end
                espData[op].health.Visible=false
                espData[op].damage.Visible=false
                espData[op].nameTxt.Visible=false
                espData[op].distTxt.Visible=false
                espData[op].toolTxt.Visible=false
            end
            continue
        end

        -- Bounding box 3D -> 2D
        local modelCFrame, modelSize = char:GetBoundingBox()
        local extents = modelSize/2
        local points2D = {}
        for _,sx in ipairs({-1,1}) do
            for _,sy in ipairs({1,-1}) do
                for _,sz in ipairs({-1,1}) do
                    local offset = Vector3.new(sx*extents.X, sy*extents.Y, sz*extents.Z)
                    local worldPoint = modelCFrame:PointToWorldSpace(offset)
                    local pt,on = camera:WorldToViewportPoint(worldPoint)
                    if on then table.insert(points2D, Vector2.new(pt.X, pt.Y)) end
                end
            end
        end
        if #points2D==0 then
            if espData[op] then
                for _,ln in pairs(espData[op].box) do ln.Visible=false end
            end
            continue
        end

        local minX,minY, maxX,maxY = math.huge,math.huge, -math.huge,-math.huge
        for _,v in ipairs(points2D) do
            if v.X<minX then minX=v.X end
            if v.X>maxX then maxX=v.X end
            if v.Y<minY then minY=v.Y end
            if v.Y>maxY then maxY=v.Y end
        end

        local tl, tr = Vector2.new(minX,minY), Vector2.new(maxX,minY)
        local bl, br = Vector2.new(minX,maxY), Vector2.new(maxX,maxY)

        -- crea si falta
        if not espData[op] then
            local data = {}
            data.box = {}
            for _,side in ipairs({"Top","Bottom","Left","Right"}) do
                local ln = Drawing.new("Line")
                ln.Color, ln.Thickness, ln.Transparency = Color3.new(1,1,1), 2, 1
                data.box[side] = ln
            end
            data.health = Drawing.new("Line")
            data.health.Color, data.health.Thickness, data.health.Transparency = Color3.new(0,1,0),4,1
            data.damage = Drawing.new("Line")
            data.damage.Color, data.damage.Thickness, data.damage.Transparency = Color3.new(1,0,0),4,1
            local function newText()
                local t = Drawing.new("Text")
                t.Size, t.Center, t.Outline, t.Color = 14,true,true,Color3.new(1,1,1)
                return t
            end
            data.nameTxt = newText()
            data.distTxt = newText()
            data.toolTxt = newText()
            espData[op] = data
        end

        local d = espData[op]

        -- Caja
        for k,v in pairs({Top={From=tl,To=tr}, Bottom={From=bl,To=br},
                         Left={From=tl,To=bl}, Right={From=tr,To=br}}) do
            d.box[k].From, d.box[k].To = v.From, v.To
            d.box[k].Visible = espShowBox
        end

        -- Salud
        local barX = minX - 6
        local barTop, barBottom = minY, maxY
        local ratio = humanoid.Health/humanoid.MaxHealth
        local healthEndY = barTop + (barBottom-barTop)*ratio
        d.health.From, d.health.To = Vector2.new(barX,barTop), Vector2.new(barX,healthEndY)
        d.damage.From, d.damage.To = Vector2.new(barX,healthEndY), Vector2.new(barX,barBottom)
        d.health.Visible = espShowHealth
        d.damage.Visible = espShowHealth

        -- Name
        d.nameTxt.Text = op.DisplayName.." ("..op.Name..")"
        d.nameTxt.Position = Vector2.new((minX+maxX)/2, minY-4)
        d.nameTxt.Visible = espShowName

        -- Distance
        local dist = math.floor((char.HumanoidRootPart.Position - camera.CFrame.Position).Magnitude)
        d.distTxt.Text = dist.." Studs"
        d.distTxt.Position = Vector2.new((minX+maxX)/2, maxY+2)
        d.distTxt.Visible = espShowDistance

        -- Tool
        local toolName = "No Tool"
        for _,c in pairs(char:GetChildren()) do
            if c:IsA("Tool") then toolName=c.Name; break end
        end
        d.toolTxt.Text = toolName
        d.toolTxt.Position = Vector2.new((minX+maxX)/2, maxY+18)
        d.toolTxt.Visible = espShowTool
    end
end)
