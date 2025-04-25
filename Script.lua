-- Integrated Hack Script con Aimbot, Wall-Check, ESP Estético y Funcional,
-- Limpieza de ESP con F1 y al morir,
-- Avatar & Account Info, Indie Flower Font,
-- Session Playtime Tracking con Recordatorios “Touch Grass”,
-- Nueva feature: Skeleton ESP blanco (R6 + R15)

local UserInputService = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local StarterGui        = game:GetService("StarterGui")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

----------------------------------------------------------------
-- Configuración inicial
----------------------------------------------------------------
local config = {
    fovRadius        = 45,
    aimbotEnabled    = true,
    wallCheckEnabled = false,
    espEnabled       = false,
    espShow = {
        box      = false,
        health   = false,
        name     = false,
        distance = false,
        tool     = false,
        skeleton = false,
    },
    sessionTrackingEnabled = true,
}

local espData = {}
local sessionStartTime = tick()
local triggered = {}

local breakIntervals = {
    { time = 1800, message = "30 minutos? Deberías salir a tomar aire." },
    { time = 3600, message = "1 hora?! Tómate un descanso, amigo." },
    { time = 7200, message = "2 horas seguidas! En serio, descansa un poco." },
}

----------------------------------------------------------------
-- Utilidades
----------------------------------------------------------------
local function formatTime(s)
    local h = math.floor(s/3600)
    local m = math.floor((s%3600)/60)
    local sec = math.floor(s%60)
    return string.format("%02d:%02d:%02d", h, m, sec)
end

local function sendNotification(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title    = title,
        Text     = text,
        Duration = duration or 3,
    })
end

local function clearESP()
    for _, data in pairs(espData) do
        for _, ln in pairs(data.box)      do ln:Remove() end
        data.health:Remove()
        data.damage:Remove()
        data.nameTxt:Remove()
        data.distTxt:Remove()
        data.toolTxt:Remove()
        if data.skeleton then
            for _, sk in ipairs(data.skeleton) do sk:Remove() end
        end
    end
    espData = {}
end

----------------------------------------------------------------
-- Tracking de sesión
----------------------------------------------------------------
local sessionLabel
task.spawn(function()
    while true do
        task.wait(1)
        if config.sessionTrackingEnabled then
            local elapsed = tick() - sessionStartTime
            if sessionLabel then
                sessionLabel.Text = "Session Time: " .. formatTime(elapsed)
            end
            for i, br in ipairs(breakIntervals) do
                if elapsed >= br.time and not triggered[i] then
                    sendNotification("Tómate un Descanso", br.message, 5)
                    triggered[i] = true
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- Creación de UI
----------------------------------------------------------------
local Keybinds = { UIToggle = Enum.KeyCode.U, ClearESP = Enum.KeyCode.F1 }
local screenGui, mainFrame, hackFrame, infoFrame

local function createBtn(parent, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.Font = Enum.Font.IndieFlower
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextScaled = true
    btn.Text = text
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", btn).Thickness = 1

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(90,90,90) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70,70,70) }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

function createUI()
    screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screenGui.Name = "HackUI"
    screenGui.ResetOnSpawn = false

    mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 560, 0, 580)
    mainFrame.Position = UDim2.new(0.5, -280, 0.5, -290)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

    -- Cerrar
    local closeBtn = createBtn(mainFrame, "X", 8, function(btn)
        mainFrame.Visible = false
    end)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 8)

    -- Panel de controles
    hackFrame = Instance.new("Frame", mainFrame)
    hackFrame.Size = UDim2.new(0, 300, 1, -20)
    hackFrame.Position = UDim2.new(0, 10, 0, 10)
    hackFrame.BackgroundTransparency = 1

    -- Título
    local title = Instance.new("TextLabel", hackFrame)
    title.Size = UDim2.new(1,0,0,30)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "Hack Control Panel"
    title.Font = Enum.Font.IndieFlower
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.TextScaled = true

    local offsetY = 40

    -- Aimbot toggle
    createBtn(hackFrame, "Aimbot: ON", offsetY, function(btn)
        config.aimbotEnabled = not config.aimbotEnabled
        btn.Text = "Aimbot: " .. (config.aimbotEnabled and "ON" or "OFF")
        if not config.aimbotEnabled then currentAimbotTarget = nil end
        sendNotification("Aimbot", config.aimbotEnabled and "Enabled" or "Disabled")
    end)
    offsetY = offsetY + 46

    -- WallCheck toggle
    createBtn(hackFrame, "WallCheck: OFF", offsetY, function(btn)
        config.wallCheckEnabled = not config.wallCheckEnabled
        btn.Text = "WallCheck: " .. (config.wallCheckEnabled and "ON" or "OFF")
        sendNotification("Wall-Check", config.wallCheckEnabled and "Enabled" or "Disabled")
    end)
    offsetY = offsetY + 46

    -- FOV slider label
    local fovLabel = Instance.new("TextLabel", hackFrame)
    fovLabel.Size = UDim2.new(1,0,0,24)
    fovLabel.Position = UDim2.new(0,0,0, offsetY)
    fovLabel.BackgroundTransparency = 1
    fovLabel.TextColor3 = Color3.new(1,1,1)
    fovLabel.Font = Enum.Font.IndieFlower
    fovLabel.TextScaled = true
    fovLabel.Text = "FOV: " .. config.fovRadius
    offsetY = offsetY + 24

    -- Slider container
    local fovSlider = Instance.new("Frame", hackFrame)
    fovSlider.Size = UDim2.new(1,0,0,12)
    fovSlider.Position = UDim2.new(0,0,0,offsetY)
    fovSlider.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", fovSlider).CornerRadius = UDim.new(0,4)
    offsetY = offsetY + 20

    -- Knob
    local fovKnob = Instance.new("Frame", fovSlider)
    fovKnob.Size = UDim2.new((config.fovRadius-20)/(200-20),0,1,0)
    fovKnob.Position = UDim2.new((config.fovRadius-20)/(200-20),0,0,0)
    fovKnob.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", fovKnob).CornerRadius = UDim.new(0,4)

    -- Slider logic
    do
        local dragging = false
        fovSlider.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local relX = math.clamp(inp.Position.X - fovSlider.AbsolutePosition.X, 0, fovSlider.AbsoluteSize.X)
                local newFOV = math.floor(20 + (relX/fovSlider.AbsoluteSize.X)*(200-20))
                config.fovRadius = newFOV
                fovKnob.Position = UDim2.new(relX/fovSlider.AbsoluteSize.X,0,0,0)
                fovLabel.Text = "FOV: " .. newFOV
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    offsetY = offsetY + 10

    -- ESP master toggle
    createBtn(hackFrame, "ESP: OFF", offsetY, function(btn)
        config.espEnabled = not config.espEnabled
        btn.Text = "ESP: " .. (config.espEnabled and "ON" or "OFF")
        if not config.espEnabled then clearESP() end
        sendNotification("ESP", config.espEnabled and "Enabled" or "Disabled")
    end)
    offsetY = offsetY + 46

    -- Toggles de ESP individuales
    for key, label in pairs({ box="Box", health="Health", name="Name", distance="Distance", tool="Tool", skeleton="Skeleton" }) do
        createBtn(hackFrame, label..": OFF", offsetY, function(btn)
            local state = not config.espShow[key]
            config.espShow[key] = state
            btn.Text = label..": " .. (state and "ON" or "OFF")
            for _, data in pairs(espData) do
                if key == "box" then
                    for _, ln in pairs(data.box) do ln.Visible = state end
                elseif key == "health" then
                    data.health.Visible, data.damage.Visible = state, state
                elseif key == "name" then
                    data.nameTxt.Visible = state
                elseif key == "distance" then
                    data.distTxt.Visible = state
                elseif key == "tool" then
                    data.toolTxt.Visible = state
                elseif key == "skeleton" then
                    if data.skeleton then for _, ln in ipairs(data.skeleton) do ln.Visible = state end end
                end
            end
        end)
        offsetY = offsetY + 46
    end

    -- Panel de info (derecha)
    infoFrame = Instance.new("Frame", mainFrame)
    infoFrame.Size = UDim2.new(0, 230, 1, -20)
    infoFrame.Position = UDim2.new(0, 320, 0, 10)
    infoFrame.BackgroundTransparency = 1

    local thumb = Instance.new("ImageLabel", infoFrame)
    thumb.Size = UDim2.new(0,100,0,100)
    thumb.Position = UDim2.new(0.5,-50,0,0)
    thumb.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    thumb.BackgroundTransparency = 1

    local y = 110
    for _, txt in ipairs({
        "Username: "..player.Name,
        "Display: "..player.DisplayName,
        "UserID: "..player.UserId,
        "Membership: "..tostring(player.MembershipType),
        "Joined: "..os.date("%c",os.time()-player.AccountAge*86400),
    }) do
        local lbl = Instance.new("TextLabel", infoFrame)
        lbl.Size = UDim2.new(1,0,0,24)
        lbl.Position = UDim2.new(0,0,0,y)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.IndieFlower
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextScaled = true
        lbl.Text = txt
        y = y + 30
    end

    sessionLabel = Instance.new("TextLabel", infoFrame)
    sessionLabel.Size = UDim2.new(1,0,0,24)
    sessionLabel.Position = UDim2.new(0,0,0,y)
    sessionLabel.BackgroundTransparency = 1
    sessionLabel.Font = Enum.Font.IndieFlower
    sessionLabel.TextColor3 = Color3.new(1,1,1)
    sessionLabel.TextScaled = true
    sessionLabel.Text = "Session Time: 00:00:00"
end

-- Inicializar UI
if not player.PlayerGui:FindFirstChild("HackUI") then createUI() end

----------------------------------------------------------------
-- Input global y ESP limpia al morir
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Keybinds.UIToggle then mainFrame.Visible = not mainFrame.Visible
    elseif input.KeyCode == Keybinds.ClearESP and config.espEnabled then clearESP(); sendNotification("ESP","ESP limpiado",2) end
end)
player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").Died:Connect(function() if config.espEnabled then clearESP() end end)
end)

----------------------------------------------------------------
-- Aimbot, FOV Circle y ESP/Skeleton rendering
----------------------------------------------------------------
local fovCircle = Drawing.new("Circle")
fovCircle.Color, fovCircle.Thickness, fovCircle.Transparency, fovCircle.NumSides, fovCircle.Filled =
    Color3.new(1,0,0), 2, 1, 100, false

RunService.RenderStepped:Connect(function()
    local mx,my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y

    -- FOV Circle
    fovCircle.Visible = config.aimbotEnabled
    if config.aimbotEnabled then fovCircle.Position, fovCircle.Radius = Vector2.new(mx,my), config.fovRadius end

    -- Aimbot logic
    if config.aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentAimbotTarget then
            local best, bestD = nil, math.huge
            for _,op in ipairs(Players:GetPlayers()) do
                if op~=player and op.Character and op.Character:FindFirstChild("Head") then
                    local head = op.Character.Head
                    local pt,on = camera:WorldToViewportPoint(head.Position)
                    if on then
                        local d = (Vector2.new(pt.X,pt.Y)-Vector2.new(mx,my)).Magnitude
                        if d < config.fovRadius and d < bestD then
                            local ok = true
                            if config.wallCheckEnabled then
                                local params = RaycastParams.new()
                                params.FilterDescendantsInstances = {player.Character}
                                params.FilterType = Enum.RaycastFilterType.Blacklist
                                params.IgnoreWater = true
                                local ray = workspace:Raycast(camera.CFrame.Position, head.Position-camera.CFrame.Position, params)
                                if ray and ray.Instance and not ray.Instance:IsDescendantOf(op.Character) then ok = false end
                            end
                            if ok then best, bestD = head, d end
                        end
                    end
                end
            end
            currentAimbotTarget = best
        end
        if currentAimbotTarget and currentAimbotTarget.Parent then
            camera.CFrame = CFrame.new(camera.CFrame.Position, currentAimbotTarget.Position)
        end
    else
        currentAimbotTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not config.espEnabled then return end
    for _,op in ipairs(Players:GetPlayers()) do
        if op==player then continue end
        local char = op.Character
        local data = espData[op]
        if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health<=0 then
            if data then
                for _,ln in pairs(data.box) do ln.Visible=false end
                data.health.Visible=false; data.damage.Visible=false
                data.nameTxt.Visible=false; data.distTxt.Visible=false; data.toolTxt.Visible=false
                if data.skeleton then for _,ln in ipairs(data.skeleton) do ln.Visible=false end end
            end
            continue
        end
        if not data then
            data = {box={}, skeleton={}}
            for _,side in ipairs({"Top","Bottom","Left","Right"}) do
                local ln=Drawing.new("Line") ln.Color,ln.Thickness,ln.Transparency=Color3.new(1,1,1),2,1
                data.box[side]=ln
            end
            data.health=Drawing.new("Line"); data.health.Color, data.health.Thickness, data.health.Transparency=Color3.new(0,1,0),4,1
            data.damage=Drawing.new("Line"); data.damage.Color, data.damage.Thickness, data.damage.Transparency=Color3.new(1,0,0),4,1
            local function nt() local t=Drawing.new("Text") t.Size,t.Center,t.Outline,t.Color=14,true,true,Color3.new(1,1,1) return t end
            data.nameTxt, data.distTxt, data.toolTxt = nt(), nt(), nt()
            espData[op] = data
        end
        local cf,size=char:GetBoundingBox()
        local ext=size/2
        local pts={}
        for _,v in ipairs({Vector3.new(-ext.X, ext.Y,-ext.Z),Vector3.new(-ext.X, ext.Y, ext.Z),Vector3.new(ext.X, ext.Y,-ext.Z),Vector3.new(ext.X, ext.Y, ext.Z),Vector3.new(-ext.X,-ext.Y,-ext.Z),Vector3.new(-ext.X,-ext.Y, ext.Z),Vector3.new(ext.X,-ext.Y,-ext.Z),Vector3.new(ext.X,-ext.Y, ext.Z)}) do
            local w=cf:PointToWorldSpace(v)
            local p,on=camera:WorldToViewportPoint(w)
            if on then table.insert(pts,Vector2.new(p.X,p.Y)) end
        end
        if #pts==0 then continue end
        local minX,minY,maxX,maxY=pts[1].X,pts[1].Y,pts[1].X,pts[1].Y
        for _,v in ipairs(pts) do minX,minY=math.min(minX,v.X),math.min(minY,v.Y) maxX,maxY=math.max(maxX,v.X),math.max(maxY,v.Y) end
        for k,v in pairs({Top={From=Vector2.new(minX,minY),To=Vector2.new(maxX,minY)},Bottom={From=Vector2.new(minX,maxY),To=Vector2.new(maxX,maxY)},Left={From=Vector2.new(minX,minY),To=Vector2.new(minX,maxY)},Right={From=Vector2.new(maxX,minY),To=Vector2.new(maxX,maxY)}}) do
            data.box[k].From,data.box[k].To=v.From,v.To
            data.box[k].Visible=config.espShow.box
        end
        local humanoid=char:FindFirstChildOfClass("Humanoid")
        local ratio=humanoid.Health/humanoid.MaxHealth
        local xBar=minX-6; local yEnd=minY+(maxY-minY)*ratio
        data.health.From,data.health.To=Vector2.new(xBar,minY),Vector2.new(xBar,yEnd)
        data.damage.From,data.damage.To=Vector2.new(xBar,yEnd),Vector2.new(xBar,maxY)
        data.health.Visible, data.damage.Visible = config.espShow.health, config.espShow.health
        data.nameTxt.Text=op.DisplayName.." ("..op.Name..")"; data.nameTxt.Position=Vector2.new((minX+maxX)/2,minY-18); data.nameTxt.Visible=config.espShow.name
        local dist=math.floor((char.HumanoidRootPart.Position-camera.CFrame.Position).Magnitude)
        data.distTxt.Text=dist.." Studs"; data.distTxt.Position=Vector2.new((minX+maxX)/2,maxY+4); data.distTxt.Visible=config.espShow.distance
        local tool="No Tool"; for _,c in ipairs(char:GetChildren()) do if c:IsA("Tool") then tool=c.Name; break end end
        data.toolTxt.Text=tool; data.toolTxt.Position=Vector2.new((minX+maxX)/2,maxY+18); data.toolTxt.Visible=config.espShow.tool
        if config.espShow.skeleton then
            local rig=humanoid.RigType
            local pairsTable=(rig==Enum.HumanoidRigType.R6) and {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}} or {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
            for i,p in ipairs(pairsTable) do
                local b0=char:FindFirstChild(p[1]); local b1=char:FindFirstChild(p[2])
                if b0 and b1 then
                    local p0,on0=camera:WorldToViewportPoint(b0.Position)
                    local p1,on1=camera:WorldToViewportPoint(b1.Position)
                    if on0 and on1 then
                        local ln=data.skeleton[i] or Drawing.new("Line")
                        ln.Color,ln.Thickness,ln.Transparency=Color3.new(1,1,1),2,1
                        ln.From,ln.To=Vector2.new(p0.X,p0.Y),Vector2.new(p1.X,p1.Y)
                        ln.Visible=true; data.skeleton[i]=ln
                    elseif data.skeleton[i] then data.skeleton[i].Visible=false end
                elseif data.skeleton[i] then data.skeleton[i].Visible=false end
            end
        else
            for _,ln in ipairs(data.skeleton) do ln.Visible=false end
        end
    end
end)
