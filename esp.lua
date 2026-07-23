if getgenv().Syrniki and getgenv().Syrniki.Unload then
    pcall(getgenv().Syrniki.Unload, getgenv().Syrniki)
end

local GetService = setmetatable({}, {
    __index = function(_, Name)
        return cloneref(game:GetService(Name))
    end
})

local Workspace, Players, RunService, HttpService = GetService["Workspace"], GetService["Players"], GetService["RunService"], GetService["HttpService"]
local LocalPlayer, Camera = Players.LocalPlayer, Workspace.CurrentCamera
local WorldToViewportPoint, FindFirstChildOfClass, FindFirstChild = Camera.WorldToViewportPoint, game.FindFirstChildOfClass, game.FindFirstChild

local NewVector3, NewVector2, Dim, Dim2, DimOffset = Vector3.new, Vector2.new, UDim.new, UDim2.new, UDim2.fromOffset
local NumSeq = NumberSequence.new
local NumKey = NumberSequenceKeypoint.new

local Format, Spawn, Clear, Floor, Clamp, Abs, Tan, Rad, Huge, Remove = string.format, task.spawn, table.clear, math.floor, math.clamp, math.abs, math.tan, math.rad, math.huge, table.remove
local Frame, ZeroVector3, CameraPosition, FocalLength, ViewPortY, Updates = 1 / 60, NewVector3(0,0,0), NewVector3(0,0,0), 0, 0, 0

local function CameraCache()
    ViewPortY = Camera.ViewportSize.Y
    CachedFocalLength = ViewPortY / (2 * Tan(Rad(Camera.FieldOfView) * 0.5))
end

CameraCache()

Camera:GetPropertyChangedSignal("FieldOfView"):Connect(CameraCache)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(CameraCache)

getgenv().Syrniki = {
    ['Directory'] = 'Esp',
    ['Cache'] = {},
    ['Holder'] = nil,
    ['Threads'] = {},
    ['Connections'] = {},
    ['Table'] = {
        ['Enabled'] = false,
        ['Bots'] = {
            ['Enabled'] = false,
        },
        ['Boxes'] = {
            ['Enabled'] = false,
            ['Bounding Box'] = {
                ['Enabled'] = false,
                ['IncludeAccessories'] = false,
                ['BoxX'] = 0,
                ['BoxY'] = 2,
            },
            ['Box Glow'] = {
                ['Enabled'] = true,
                ['Top'] = Color3.fromRGB(255, 255, 255),
                ['Bot'] = Color3.fromRGB(255, 255, 255),
                ['Transparency'] = {0.85, 0.85},
            },
            ['Gradients'] = {
                ['Top'] = Color3.fromRGB(255, 255, 255),
                ['Bot'] = Color3.fromRGB(255, 255, 255),
            },
            ['Filled'] = {
                ['Enabled'] = true,
                ['Top'] = Color3.fromRGB(255, 255, 255),
                ['Bot'] = Color3.fromRGB(255, 255, 255),
                ['Transparency'] = {0.85, 0.85},
            },
        },
        ['Bars'] = {
            ['Health Bar'] = {
                ['Enabled'] = false,
                ['Color'] = Color3.fromRGB(255, 255, 255),
            },
        },
        ['Texts'] = {
            ['Name'] = {
                ['Enabled'] = false,
                ['Color'] = Color3.fromRGB(255, 255, 255),
            },
            ['Distance'] = {
                ['Enabled'] = false,
                ['Color'] = Color3.fromRGB(200, 200, 200),
            },
            ['Weapon'] = {
                ['Enabled'] = false,
                ['Color'] = Color3.fromRGB(255, 255, 255),
            },
            ['State'] = {
                ['Enabled'] = false,
                ['Color'] = Color3.fromRGB(255, 255, 255),
            },
        },
    },
}

local Table = Syrniki['Table']

local Fonts = { }
do
    local function FontsRegister(Name, Weight, Style, Asset)
        if isfile(Asset.Id) then
            delfile(Asset.Id)
        end
        writefile(Asset.Id, Asset.Font)
        if isfile(Name .. ".font") then
            delfile(Name .. ".font")
        end
        local Info = {
            name = Name,
            faces = {
                {
                    name = "Normal",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(Asset.Id)
                }
            }
        }
        writefile(Name .. ".font", HttpService:JSONEncode(Info))
        return getcustomasset(Name .. ".font")
    end

    Fonts.Tahoma = FontsRegister("Tahoma", 400, "Normal", {
        Id = "Tahoma.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf")
    })
    Fonts.SmallestPixel = FontsRegister("SmallestPixel", 400, "Normal", {
        Id = "smallest_pixel-7.ttf",
        Font = game:HttpGet("https://raw.githubusercontent.com/sametexe001/luas/main/smallest_pixel-7.ttf")
    })

    Syrniki.Tahoma = Font.new(Fonts.Tahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Syrniki.SmallestPixel = Font.new(Fonts.SmallestPixel, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

Syrniki.__index = Syrniki

function Syrniki:CreateObjects(Name, Prop)
    local New = Instance.new(Name)
    for Property, Value in Prop or {} do
        New[Property] = Value
    end
    return New
end

function Syrniki:CreateThreads(Name, Signal, Callback)
    local Connection = Signal:Connect(Callback)
    self.Threads[Name] = Connection
    return Connection
end

Syrniki.Holder = Syrniki:CreateObjects("ScreenGui", {
    Name = "\n",
    Parent = gethui(),
    ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ResetOnSpawn = false,
    DisplayOrder = -1,
    IgnoreGuiInset = true,
})

function Syrniki:InitEsp(Data)
    local Objects = Data.Objects

    do
        Objects["TargetHolder"] = self:CreateObjects("Frame", {
            Parent = self.Holder,
            Visible = false,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(0, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["TopHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["TargetHolder"],
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = true,
            BackgroundTransparency = 1,
            AnchorPoint = NewVector2(0, 1),
            Position = Dim2(0, -2, 0, -5),
            Size = Dim2(1, 4, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BottomHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["TargetHolder"],
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(0, -2, 1, 3),
            Size = Dim2(1, 4, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["LeftHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["TargetHolder"],
            AutomaticSize = Enum.AutomaticSize.X,
            Visible = true,
            BackgroundTransparency = 1,
            AnchorPoint = NewVector2(1, 0),
            Position = Dim2(0, -5, 0, -2),
            Size = Dim2(0, 0, 1, 4),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["RightHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["TargetHolder"],
            AutomaticSize = Enum.AutomaticSize.X,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(1, 5, 0, -2),
            Size = Dim2(0, 0, 1, 4),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
    end

    do
        Objects["TopTextHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["TopHolder"],
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(1, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BottomTextHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["BottomHolder"],
            LayoutOrder = 2,
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(1, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["LeftTextHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["LeftHolder"],
            AutomaticSize = Enum.AutomaticSize.XY,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(1, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["RightTextHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["RightHolder"],
            LayoutOrder = 2,
            AutomaticSize = Enum.AutomaticSize.XY,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(0, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
    end

    do
        Objects["LeftBarHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["LeftHolder"],
            AutomaticSize = Enum.AutomaticSize.X,
            Visible = false,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(0, 0, 1, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BottomBarHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["BottomHolder"],
            LayoutOrder = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(1, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
    end

    do
        self:CreateObjects("UIListLayout", {
            Parent = Objects["TopTextHolder"],
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = Dim(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["BottomTextHolder"],
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = Dim(0, -1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["LeftTextHolder"],
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = Dim(0, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["RightTextHolder"],
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = Dim(0, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["LeftBarHolder"],
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = Dim(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["BottomBarHolder"],
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = Dim(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["TopHolder"],
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = Dim(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["BottomHolder"],
            Padding = Dim(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["LeftHolder"],
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = Dim(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        self:CreateObjects("UIListLayout", {
            Parent = Objects["RightHolder"],
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = Dim(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    end

    do
        self:CreateObjects("UIPadding", {
            Parent = Objects["TopTextHolder"],
            PaddingBottom = Dim(0, 0),
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["BottomTextHolder"],
            PaddingTop = Dim(0, -1)
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["LeftTextHolder"],
            PaddingTop = Dim(0, -3),
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["RightTextHolder"],
            PaddingTop = Dim(0, -3),
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["LeftBarHolder"],
            PaddingRight = Dim(0, 1),
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["BottomBarHolder"],
            PaddingTop = Dim(0, 3),
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["LeftHolder"],
            PaddingRight = Dim(0, 1),
        })
    end

    do
        Objects["BoxGlow"] = self:CreateObjects("ImageLabel", {
            Parent = Objects["TargetHolder"],
            Image = "rbxassetid://110204605000367",
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(NewVector2(21, 21), NewVector2(79, 79)),
            AutomaticSize = Enum.AutomaticSize.XY,
            ImageTransparency = 0.65,
            ResampleMode = Enum.ResamplerMode.Pixelated,
            Visible = true,
            BackgroundTransparency = 1,
            Position = Dim2(0, -21, 0, -21),
            Size = Dim2(0, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BoxGlowGradient"] = self:CreateObjects("UIGradient", {
            Parent = Objects["BoxGlow"],
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
            }),
            Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
        })

        self:CreateObjects("UIPadding", {
            Parent = Objects["BoxGlow"],
            PaddingTop = Dim(0, 21),
            PaddingBottom = Dim(0, 20),
            PaddingLeft = Dim(0, 21),
            PaddingRight = Dim(0, 20),
        })

        Objects["BoxOutlineHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["BoxGlow"],
            Visible = false,
            BackgroundTransparency = 1,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(0, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BoxOutline"] = self:CreateObjects("UIStroke", {
            Parent = Objects["BoxOutlineHolder"],
            Thickness = 3,
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["BoxOutlineGradient"] = self:CreateObjects("UIGradient", {
            Parent = Objects["BoxOutline"],
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
            }),
            Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
        })

        Objects["BoxInlineHolder"] = self:CreateObjects("Frame", {
            Parent = Objects["BoxGlow"],
            Visible = false,
            BackgroundTransparency = 1,
            Position = Dim2(0, -1, 0, -1),
            Size = Dim2(0, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BoxInline"] = self:CreateObjects("UIStroke", {
            Parent = Objects["BoxInlineHolder"],
            Color = Color3.fromRGB(255, 255, 255),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["BoxInlineGradient"] = self:CreateObjects("UIGradient", {
            Parent = Objects["BoxInline"],
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
            }),
            Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
        })

        Objects["BoxFill"] = self:CreateObjects("Frame", {
            Parent = Objects["BoxGlow"],
            Visible = false,
            BackgroundTransparency = 0,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(0, 0, 0, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })

        Objects["BoxFillGradient"] = self:CreateObjects("UIGradient", {
            Parent = Objects["BoxFill"],
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
            }),
            Transparency = NumSeq({NumKey(0, 1), NumKey(1, 1)}),
        })
    end

    do
        Objects["HealthBarOutline"] = self:CreateObjects("Frame", {
            Parent = Objects["LeftBarHolder"],
            ZIndex = 5,
            LayoutOrder = 0,
            Visible = false,
            BackgroundTransparency = 0,
            Position = Dim2(0, 0, 0, 0),
            Size = Dim2(0, 2, 1, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            ClipsDescendants = false,
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["HealthBarOutline"],
            Thickness = 1,
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["HealthBar"] = self:CreateObjects("Frame", {
            Parent = Objects["HealthBarOutline"],
            ZIndex = 6,
            AnchorPoint = NewVector2(0, 1),
            Position = Dim2(0, 0, 1, 0),
            Size = Dim2(1, 0, 1, 0),
            BorderSizePixel = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ClipsDescendants = true,
        })

        Objects["HealthBarGradient"] = self:CreateObjects("UIGradient", {
            Parent = Objects["HealthBar"],
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Table['Bars']['Health Bar']['Color']),
                ColorSequenceKeypoint.new(1, Table['Bars']['Health Bar']['Color']),
            }),
            Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
        })

        Objects["HealthBarText"] = self:CreateObjects("TextLabel", {
            Parent = Objects["HealthBarOutline"],
            FontFace = Syrniki.SmallestPixel,
            TextSize = 9,
            ZIndex = 10,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            AnchorPoint = NewVector2(0.5, 0.5),
            Position = Dim2(0.5, 0, 1, 0),
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["HealthBarText"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })
    end

    do
        Objects["TargetName"] = self:CreateObjects("TextLabel", {
            Parent = Objects["TopTextHolder"],
            FontFace = Syrniki.Tahoma,
            TextSize = 12,
            LayoutOrder = 2,
            TextColor3 = Table['Texts']['Name']['Color'],
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Center,
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            ZIndex = 5,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["TargetName"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["Distance"] = self:CreateObjects("TextLabel", {
            Parent = Objects["BottomTextHolder"],
            FontFace = Syrniki.SmallestPixel,
            TextSize = 9,
            LayoutOrder = 2,
            TextColor3 = Table['Texts']['Distance']['Color'],
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Center,
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            ZIndex = 5,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["Distance"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["WalkFlag"] = self:CreateObjects("TextLabel", {
            Parent = Objects["RightTextHolder"],
            FontFace = Syrniki.SmallestPixel,
            TextSize = 9,
            LayoutOrder = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Walking",
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            ZIndex = 5,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["WalkFlag"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["JumpFlag"] = self:CreateObjects("TextLabel", {
            Parent = Objects["RightTextHolder"],
            FontFace = Syrniki.SmallestPixel,
            TextSize = 9,
            LayoutOrder = 2,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Jumping",
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            ZIndex = 5,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["JumpFlag"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["StateFlag"] = self:CreateObjects("TextLabel", {
            Parent = Objects["RightTextHolder"],
            FontFace = Syrniki.SmallestPixel,
            TextSize = 9,
            LayoutOrder = 3,
            TextColor3 = Table['Texts']['State']['Color'],
            Text = "Standing",
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            ZIndex = 5,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["StateFlag"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })

        Objects["Weapon"] = self:CreateObjects("TextLabel", {
            Parent = Objects["BottomTextHolder"],
            FontFace = Syrniki.SmallestPixel,
            TextSize = 9,
            LayoutOrder = 3,
            TextColor3 = Table['Texts']['Weapon']['Color'],
            Text = "none",
            TextXAlignment = Enum.TextXAlignment.Center,
            BorderSizePixel = 0,
            Visible = false,
            BackgroundTransparency = 1,
            ZIndex = 5,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = Dim2(0, 0, 0, 0),
        })

        self:CreateObjects("UIStroke", {
            Parent = Objects["Weapon"],
            Color = Color3.fromRGB(0, 0, 0),
            LineJoinMode = Enum.LineJoinMode.Miter,
        })
    end
end

function Syrniki:CalculateBox(Data)
    local RootPart = Data['RootPart']
    if not RootPart then
        return nil, nil, nil, nil, false
    end

    local RootScreen, OnScreen = WorldToViewportPoint(Camera, RootPart.Position)
    if not OnScreen then
        return nil, nil, nil, nil, false
    end

    local BoundingBox = Table['Boxes']['Bounding Box']
    if BoundingBox['Enabled'] then
        local Children = Data['Children']
        if not Children then
            local Scale = (RootPart.Size.Y * ViewPortY) / (RootScreen.Z * 2)
            local W, H = 3 * Scale, 4.5 * Scale
            return W, H, RootScreen.X - (W * 0.5), RootScreen.Y - (H * 0.5), OnScreen
        end

        local IncludeAccessories = Data['IncludeAccessories']
        local ScrMinX, ScrMinY = Huge, Huge
        local ScrMaxX, ScrMaxY = -Huge, -Huge
        local HasValidParts = false

        for _, Part in Children do
            if Part:IsA('BasePart') and Part.Transparency ~= 1 and Part ~= RootPart then
                local Parent = Part.Parent
                if Parent == nil then
                    continue
                end
                if not IncludeAccessories and Parent:IsA('Accessory') then
                    continue
                end

                local PartScreen, PartOnScreen = WorldToViewportPoint(Camera, Part.Position)
                if not PartOnScreen or PartScreen.Z <= 0 then
                    continue
                end

                HasValidParts = true

                local Cf = Part.CFrame
                local Sz = Part.Size
                local HX, HY, HZ = Sz.X * 0.5, Sz.Y * 0.5, Sz.Z * 0.5
                local RX, UY, LZ = Cf.RightVector, Cf.UpVector, Cf.LookVector
                local DepthScale = CachedFocalLength / PartScreen.Z

                local Ex = (Abs(RX.X * HX) + Abs(UY.X * HY) + Abs(LZ.X * HZ)) * DepthScale
                local Ey = (Abs(RX.Y * HX) + Abs(UY.Y * HY) + Abs(LZ.Y * HZ)) * DepthScale

                local PMinX, PMaxX = PartScreen.X - Ex, PartScreen.X + Ex
                local PMinY, PMaxY = PartScreen.Y - Ey, PartScreen.Y + Ey

                if PMinX < ScrMinX then ScrMinX = PMinX end
                if PMaxX > ScrMaxX then ScrMaxX = PMaxX end
                if PMinY < ScrMinY then ScrMinY = PMinY end
                if PMaxY > ScrMaxY then ScrMaxY = PMaxY end
            end
        end

        if not HasValidParts then
            local Scale = (RootPart.Size.Y * ViewPortY) / (RootScreen.Z * 2)
            local W, H = 3 * Scale, 4.5 * Scale
            return W, H, RootScreen.X - (W * 0.5), RootScreen.Y - (H * 0.5), OnScreen
        end

        local PadX = BoundingBox['BoxX']
        local PadY = BoundingBox['BoxY']
        local W = (ScrMaxX - ScrMinX) + PadX
        local H = (ScrMaxY - ScrMinY) + PadY

        return W, H, ScrMinX - (PadX * 0.5), ScrMinY - (PadY * 0.5), true
    else
        local Scale = (RootPart.Size.Y * ViewPortY) / (RootScreen.Z * 2)
        local W, H = 3 * Scale, 4.5 * Scale
        return W, H, RootScreen.X - (W * 0.5), RootScreen.Y - (H * 0.5), OnScreen
    end
end

function Syrniki:AddTarget(Target)
    local IsPlayer = Target:IsA("Player")
    local IsBot = not IsPlayer and Target.Name == "bot" and Target:IsA("Model")

    if not IsPlayer and not IsBot then
        return
    end

    if self.Cache[Target] then
        return
    end

    if IsPlayer and Target == LocalPlayer then
        return
    end

    local Data = {
        ['Target'] = Target,
        ['IsBot'] = IsBot,
        ['IsPlayer'] = IsPlayer,
        ['Objects'] = {},
        ['Conns'] = {},
        ['Character'] = nil,
        ['RootPart'] = nil,
        ['Humanoid'] = nil,
        ['Children'] = nil,
        ['Health'] = 0,
        ['MaxHealth'] = 100,
        ['CurrentTool'] = nil,
        ['Alive'] = false,
        ['LastW'] = nil,
        ['LastH'] = nil,
        ['LastX'] = nil,
        ['LastY'] = nil,
        ['WalkActive'] = false,
        ['JumpActive'] = false,
        ['IncludeAccessories'] = Table['Boxes']['Bounding Box']['IncludeAccessories'],
        ['LastGlowTop'] = nil,
        ['LastGlowBot'] = nil,
        ['LastGlowT1'] = nil,
        ['LastGlowT2'] = nil,
        ['LastGradTop'] = nil,
        ['LastGradBot'] = nil,
        ['LastFillTop'] = nil,
        ['LastFillBot'] = nil,
        ['LastFillT1'] = nil,
        ['LastFillT2'] = nil,
        ['LastDist'] = nil,
        ['LastDistColor'] = nil,
        ['LastDisplayName'] = nil,
        ['LastNameColor'] = nil,
        ['LastHealthColor'] = nil,
        ['LastHealthFloor'] = nil,
        ['LastRatio'] = nil,
        ['LastWeapon'] = nil,
        ['LastWeaponColor'] = nil,
        ['LastStateColor'] = nil,
        ['LastDistance'] = nil,
    }
    self:InitEsp(Data)
    self['Cache'][Target] = Data

    if IsPlayer then
        local HealthHandler = {}
        do
            function HealthHandler.BindHealth(Humanoid)
                if Data['Conns']['Health'] then
                    Data['Conns']['Health']:Disconnect()
                end
                if Data['Conns']['Died'] then
                    Data['Conns']['Died']:Disconnect()
                end

                Data['Humanoid'] = Humanoid
                Data['Health'] = Humanoid.Health
                Data['MaxHealth'] = Humanoid.MaxHealth
                Data['Alive'] = Humanoid.Health > 0

                Data['Conns']['Health'] = Humanoid.HealthChanged:Connect(function(NewHealth)
                    Data['Alive'] = NewHealth > 0
                    Data['Health'] = NewHealth
                end)

                Data['Conns']['Died'] = Humanoid.Died:Connect(function()
                    Data['Alive'] = false
                end)
            end
            Data['BindHealth'] = HealthHandler.BindHealth
        end

        local ChildHandler = {}
        do
            function ChildHandler.BindChildren(Character)
                if Data['Conns']['ChildAdded'] then
                    Data['Conns']['ChildAdded']:Disconnect()
                end
                if Data['Conns']['ChildRemoved'] then
                    Data['Conns']['ChildRemoved']:Disconnect()
                end

                local Children = Character:GetChildren()
                Data['Children'] = Children

                Data['Conns']['ChildAdded'] = Character.ChildAdded:Connect(function(Child)
                    Children[#Children + 1] = Child
                end)

                Data['Conns']['ChildRemoved'] = Character.ChildRemoved:Connect(function(Child)
                    for I = #Children, 1, -1 do
                        if Children[I] == Child then
                            Remove(Children, I)
                            break
                        end
                    end
                end)
            end
            Data['BindChildren'] = ChildHandler.BindChildren
        end

        local FlagsHandler = {}
        do
            function FlagsHandler.BindFlags(Humanoid)
                if Data['Conns']['MoveDir'] then
                    Data['Conns']['MoveDir']:Disconnect()
                end
                if Data['Conns']['StateChange'] then
                    Data['Conns']['StateChange']:Disconnect()
                end

                local Objects = Data['Objects']
                Data['JumpActive'] = false
                Data['WalkActive'] = false

                Objects['WalkFlag'].Visible = false
                Objects['JumpFlag'].Visible = false
                Objects['StateFlag'].Text = "Standing"
                Objects['StateFlag'].Visible = true
                Objects['StateFlag'].LayoutOrder = 1

                Data['Conns']['MoveDir'] = Humanoid:GetPropertyChangedSignal('MoveDirection'):Connect(function()
                    local Walking = Humanoid.MoveDirection ~= ZeroVector3
                    if Walking and not Data['WalkActive'] then
                        Data['WalkActive'] = true
                        Objects['StateFlag'].Visible = false
                        Objects['WalkFlag'].Text = "Walking"
                        Objects['WalkFlag'].Visible = true
                        if Data['JumpActive'] then
                            Objects['WalkFlag'].LayoutOrder = 2
                            Objects['JumpFlag'].LayoutOrder = 1
                        else
                            Objects['WalkFlag'].LayoutOrder = 1
                        end
                    elseif not Walking and Data['WalkActive'] then
                        Data['WalkActive'] = false
                        Objects['WalkFlag'].Visible = false
                        if Data['JumpActive'] then
                            Objects['JumpFlag'].LayoutOrder = 1
                            Objects['StateFlag'].Visible = false
                        else
                            Objects['StateFlag'].Text = "Standing"
                            Objects['StateFlag'].Visible = true
                            Objects['StateFlag'].LayoutOrder = 1
                        end
                    end
                end)

                Data['Conns']['StateChange'] = Humanoid.StateChanged:Connect(function(_, NewState)
                    local Jumping = NewState == Enum.HumanoidStateType.Jumping or NewState == Enum.HumanoidStateType.Freefall
                    if Jumping and not Data['JumpActive'] then
                        Data['JumpActive'] = true
                        Objects['StateFlag'].Visible = false
                        Objects['JumpFlag'].Text = "Jumping"
                        Objects['JumpFlag'].Visible = true
                        if Data['WalkActive'] then
                            Objects['JumpFlag'].LayoutOrder = 1
                            Objects['WalkFlag'].LayoutOrder = 2
                        else
                            Objects['JumpFlag'].LayoutOrder = 1
                        end
                    elseif not Jumping and Data['JumpActive'] then
                        Data['JumpActive'] = false
                        Objects['JumpFlag'].Visible = false
                        if Data['WalkActive'] then
                            Objects['WalkFlag'].LayoutOrder = 1
                            Objects['StateFlag'].Visible = false
                        else
                            Objects['StateFlag'].Text = "Standing"
                            Objects['StateFlag'].Visible = true
                            Objects['StateFlag'].LayoutOrder = 1
                        end
                    end
                end)
            end
            Data['BindFlags'] = FlagsHandler.BindFlags
        end

        local CharacterHandler = {}
        do
            function CharacterHandler.OnCharacter(Character)
                Data['Character'] = Character
                Data['RootPart'] = nil
                Data['Humanoid'] = nil
                Data['Children'] = nil
                Data['Alive'] = false
                Data['WalkActive'] = false
                Data['JumpActive'] = false

                if not Character or not Character.Parent then
                    return
                end

                local RootPart = FindFirstChild(Character, "HumanoidRootPart")
                if not RootPart then
                    RootPart = Character:WaitForChild('HumanoidRootPart', 10)
                end

                local Humanoid = FindFirstChildOfClass(Character, 'Humanoid')
                if not Humanoid then
                    Humanoid = Character:WaitForChild('Humanoid', 10)
                end

                if not RootPart or not Humanoid then
                    return
                end

                if not Character.Parent then
                    return
                end

                Data['RootPart'] = RootPart
                Data['Humanoid'] = Humanoid

                Data['BindChildren'](Character)
                Data['BindHealth'](Humanoid)
                Data['BindFlags'](Humanoid)
            end

            if Data['Conns']['CharAdded'] then
                Data['Conns']['CharAdded']:Disconnect()
            end

            Data['Conns']['CharAdded'] = Target.CharacterAdded:Connect(function(Character)
                task.defer(CharacterHandler.OnCharacter, Character)
            end)

            if Target.Character and Target.Character.Parent then
                task.defer(CharacterHandler.OnCharacter, Target.Character)
            end
        end
    else
        Data['Character'] = Target
        Data['RootPart'] = Target:FindFirstChild("HumanoidRootPart")
        Data['Humanoid'] = Target:FindFirstChildOfClass("Humanoid")
        Data['Children'] = Target:GetChildren()
        Data['Alive'] = Data['Humanoid'] and Data['Humanoid'].Health > 0 or false
        Data['Health'] = Data['Humanoid'] and Data['Humanoid'].Health or 0
        Data['MaxHealth'] = Data['Humanoid'] and Data['Humanoid'].MaxHealth or 100
    end
end

function Syrniki:RemoveTarget(Target)
    local Data = self['Cache'][Target]
    if not Data then
        return
    end

    for _, Connections in Data['Conns'] do
        Connections:Disconnect()
    end
    Clear(Data['Conns'])

    if Data['Objects']['TargetHolder'] then
        Data['Objects']['TargetHolder']:Destroy()
    end
    Clear(Data['Objects'])
    self['Cache'][Target] = nil
end

function Syrniki:Update(Target, Data)
    local Objects = Data['Objects']

    if not Data['IsBot'] and Target.Character and Target.Character.Parent then
        Data['Character'] = Target.Character
    end

    local Character = Data['Character']

    if not Character or not Character.Parent then
        if Objects['TargetHolder'].Visible then
            Objects['TargetHolder'].Visible = false
        end
        return
    end

    local RootPart = Data['RootPart'] or Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Data['Humanoid'] or Character:FindFirstChildOfClass("Humanoid")

    if not RootPart or not Humanoid then
        if Objects['TargetHolder'].Visible then
            Objects['TargetHolder'].Visible = false
        end
        return
    end

    if Humanoid.Health <= 0 then
        if Objects['TargetHolder'].Visible then
            Objects['TargetHolder'].Visible = false
        end
        return
    end

    Data['RootPart'] = RootPart
    Data['Humanoid'] = Humanoid
    Data['Children'] = Character:GetChildren()
    Data['Health'] = Humanoid.Health
    Data['MaxHealth'] = Humanoid.MaxHealth

    if Data['Character'] ~= Character then
        Data['Character'] = Character
        Data['LastW'] = nil
        Data['LastH'] = nil
        Data['LastX'] = nil
        Data['LastY'] = nil
    end

    local W, H, X, Y, OnScreen = self:CalculateBox(Data)
    if not OnScreen or not W then
        if Objects['TargetHolder'].Visible then
            Objects['TargetHolder'].Visible = false
        end
        return
    end

    W = Floor(W)
    H = Floor(H)
    X = Floor(X)
    Y = Floor(Y)

    if not Objects['TargetHolder'].Visible then
        Objects['TargetHolder'].Visible = true
    end

    local DirtySizes = Data['LastW'] ~= W or Data['LastH'] ~= H
    local DirtyPosition = Data['LastX'] ~= X or Data['LastY'] ~= Y

    if DirtyPosition then
        Objects['TargetHolder'].Position = DimOffset(X, Y)
        Data['LastX'] = X
        Data['LastY'] = Y
    end

    if DirtySizes then
        Objects['TargetHolder'].Size = DimOffset(W, H)
        Objects['BoxGlow'].Size = DimOffset(W, H)
        Objects['BoxOutlineHolder'].Size = DimOffset(W, H)
        Objects['BoxInlineHolder'].Size = DimOffset(W + 2, H + 2)
        Objects['BoxFill'].Size = DimOffset(W, H)
        Data['LastW'] = W
        Data['LastH'] = H
    end

    local BoxesCfg = Table['Boxes']
    local TextsCfg = Table['Texts']

    if BoxesCfg['Enabled'] then
        if BoxesCfg['Box Glow']['Enabled'] then
            if Objects['BoxGlow'].ImageTransparency ~= 0 then
                Objects['BoxGlow'].ImageTransparency = 0
            end

            local GlowTop = BoxesCfg['Box Glow']['Top']
            local GlowBot = BoxesCfg['Box Glow']['Bot']

            if Data['LastGlowTop'] ~= GlowTop or Data['LastGlowBot'] ~= GlowBot then
                Objects['BoxGlowGradient'].Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, GlowTop),
                    ColorSequenceKeypoint.new(1, GlowBot),
                })
                Data['LastGlowTop'] = GlowTop
                Data['LastGlowBot'] = GlowBot
            end

            local T1 = BoxesCfg['Box Glow']['Transparency'][1]
            local T2 = BoxesCfg['Box Glow']['Transparency'][2]

            if Data['LastGlowT1'] ~= T1 or Data['LastGlowT2'] ~= T2 then
                Objects['BoxGlowGradient'].Transparency = NumSeq({NumKey(0, T1), NumKey(1, T2)})
                Data['LastGlowT1'] = T1
                Data['LastGlowT2'] = T2
            end
        else
            if Objects['BoxGlow'].ImageTransparency ~= 1 then
                Objects['BoxGlow'].ImageTransparency = 1
            end
        end

        if not Objects['BoxOutlineHolder'].Visible then
            Objects['BoxOutlineHolder'].Visible = true
        end

        if not Objects['BoxInlineHolder'].Visible then
            Objects['BoxInlineHolder'].Visible = true
        end

        local GradTop = BoxesCfg['Gradients']['Top']
        local GradBot = BoxesCfg['Gradients']['Bot']

        if Data['LastGradTop'] ~= GradTop or Data['LastGradBot'] ~= GradBot then
            Objects['BoxInlineGradient'].Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, GradTop),
                ColorSequenceKeypoint.new(1, GradBot),
            })
            Data['LastGradTop'] = GradTop
            Data['LastGradBot'] = GradBot
        end

        if BoxesCfg['Filled']['Enabled'] then
            if not Objects['BoxFill'].Visible then
                Objects['BoxFill'].Visible = true
            end

            local FillTop = BoxesCfg['Filled']['Top']
            local FillBot = BoxesCfg['Filled']['Bot']
            local FillT1 = BoxesCfg['Filled']['Transparency'][1]
            local FillT2 = BoxesCfg['Filled']['Transparency'][2]

            if Data['LastFillTop'] ~= FillTop or Data['LastFillBot'] ~= FillBot then
                Objects['BoxFillGradient'].Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, FillTop),
                    ColorSequenceKeypoint.new(1, FillBot),
                })
                Data['LastFillTop'] = FillTop
                Data['LastFillBot'] = FillBot
            end

            if Data['LastFillT1'] ~= FillT1 or Data['LastFillT2'] ~= FillT2 then
                Objects['BoxFillGradient'].Transparency = NumSeq({NumKey(0, FillT1), NumKey(1, FillT2)})
                Data['LastFillT1'] = FillT1
                Data['LastFillT2'] = FillT2
            end
        else
            if Objects['BoxFill'].Visible then
                Objects['BoxFill'].Visible = false
            end
        end
    else
        if Objects['BoxGlow'].ImageTransparency ~= 1 then
            Objects['BoxGlow'].ImageTransparency = 1
        end

        if Objects['BoxOutlineHolder'].Visible then
            Objects['BoxOutlineHolder'].Visible = false
        end

        if Objects['BoxInlineHolder'].Visible then
            Objects['BoxInlineHolder'].Visible = false
        end

        if Objects['BoxFill'].Visible then
            Objects['BoxFill'].Visible = false
        end
    end

    if TextsCfg['Name']['Enabled'] then
        if not Objects['TargetName'].Visible then
            Objects['TargetName'].Visible = true
        end

        local DisplayName
        if Data['IsBot'] then
            DisplayName = "Solder"
        else
            DisplayName = Target.DisplayName
        end

        if Data['LastDisplayName'] ~= DisplayName then
            Objects['TargetName'].Text = DisplayName
            Data['LastDisplayName'] = DisplayName
        end

        local NameColor = TextsCfg['Name']['Color']
        if Data['LastNameColor'] ~= NameColor then
            Objects['TargetName'].TextColor3 = NameColor
            Data['LastNameColor'] = NameColor
        end
    else
        if Objects['TargetName'].Visible then
            Objects['TargetName'].Visible = false
        end
    end

    if TextsCfg['Distance']['Enabled'] then
        if not Objects['Distance'].Visible then
            Objects['Distance'].Visible = true
        end

        local RootPos = Data['RootPart'].Position
        local Distance = Floor((CameraPosition - RootPos).Magnitude)
        if Data['LastDist'] ~= Distance then
            Objects['Distance'].Text = Format('%d st', Distance)
            Data['LastDist'] = Distance
        end

        local DistColor = TextsCfg['Distance']['Color']
        if Data['LastDistColor'] ~= DistColor then
            Objects['Distance'].TextColor3 = DistColor
            Data['LastDistColor'] = DistColor
        end
    else
        if Objects['Distance'].Visible then
            Objects['Distance'].Visible = false
        end
    end

    if TextsCfg['State']['Enabled'] then
        if Data['LastStateColor'] ~= TextsCfg['State']['Color'] then
            Objects['StateFlag'].TextColor3 = TextsCfg['State']['Color']
            Objects['WalkFlag'].TextColor3 = TextsCfg['State']['Color']
            Objects['JumpFlag'].TextColor3 = TextsCfg['State']['Color']
            Data['LastStateColor'] = TextsCfg['State']['Color']
        end
    else
        Objects['StateFlag'].Visible = false
        Objects['WalkFlag'].Visible = false
        Objects['JumpFlag'].Visible = false
    end

    local HealthCfg = Table['Bars']['Health Bar']

    if HealthCfg['Enabled'] then
        local Health = Data['Health'] or 0
        local MaxHealth = Data['MaxHealth'] or 100
        local Ratio = Clamp(Health / MaxHealth, 0, 1)

        if not Objects['LeftBarHolder'].Visible then
            Objects['LeftBarHolder'].Visible = true
        end

        if not Objects['HealthBarOutline'].Visible then
            Objects['HealthBarOutline'].Visible = true
        end

        if Data['LastRatio'] ~= Ratio then
            Objects['HealthBar'].Size = Dim2(1, 0, Ratio, 0)
            Data['LastRatio'] = Ratio
        end

        local Color = HealthCfg['Color']
        if Data['LastHealthColor'] ~= Color then
            Objects['HealthBarGradient'].Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color),
                ColorSequenceKeypoint.new(1, Color),
            })
            Data['LastHealthColor'] = Color
        end

        if Ratio < 1 then
            if not Objects['HealthBarText'].Visible then
                Objects['HealthBarText'].Visible = true
            end

            local FlooredHealth = Floor(Health)

            if Data['LastHealthFloor'] ~= FlooredHealth then
                Objects['HealthBarText'].Text = Format('%d', FlooredHealth)
                Objects['HealthBarText'].Position = Dim2(0.5, 0, 1 - Ratio, 0)
                Data['LastHealthFloor'] = FlooredHealth
            end
        else
            if Objects['HealthBarText'].Visible then
                Objects['HealthBarText'].Visible = false
            end
        end
    else
        if Objects['HealthBarOutline'].Visible then
            Objects['HealthBarOutline'].Visible = false
        end

        if Objects['HealthBarText'].Visible then
            Objects['HealthBarText'].Visible = false
        end

        if Objects['LeftBarHolder'].Visible then
            Objects['LeftBarHolder'].Visible = false
        end
    end

    local WeaponCfg = TextsCfg['Weapon']
    if WeaponCfg['Enabled'] then
        if not Objects['Weapon'].Visible then
            Objects['Weapon'].Visible = true
        end
        local CurrentWeapon
        if Data['IsBot'] then
            CurrentWeapon = "MP5"
        else
            CurrentWeapon = 'none'
            if Character then
                for _, Child in Character:GetChildren() do
                    if Child:IsA('Tool') then
                        CurrentWeapon = Child.Name
                        break
                    end
                end
            end
        end
        if Data['LastWeapon'] ~= CurrentWeapon then
            Objects['Weapon'].Text = CurrentWeapon
            Data['LastWeapon'] = CurrentWeapon
        end
        local WeaponColor = WeaponCfg['Color']
        if Data['LastWeaponColor'] ~= WeaponColor then
            Objects['Weapon'].TextColor3 = WeaponColor
            Data['LastWeaponColor'] = WeaponColor
        end
    else
        if Objects['Weapon'].Visible then
            Objects['Weapon'].Visible = false
        end
    end
end

do
    Syrniki:CreateThreads('Renderer', RunService.RenderStepped, function()
        if not Table['Enabled'] then
            for _, Data in Syrniki['Cache'] do
                if Data['Objects']['TargetHolder'].Visible then
                    Data['Objects']['TargetHolder'].Visible = false
                end
            end
            return
        end

        CameraPosition = Camera.CFrame.Position

        for _, Player in pairs(Players:GetPlayers()) do
            if not Syrniki['Cache'][Player] then
                Syrniki:AddTarget(Player)
            end
        end

        if Table['Bots']['Enabled'] then
            for _, Bot in pairs(Workspace:GetChildren()) do
                if Bot:IsA("Model") and Bot.Name == "bot" then
                    if not Syrniki['Cache'][Bot] then
                        Syrniki:AddTarget(Bot)
                    end
                end
            end
        end

        for Target, Data in Syrniki['Cache'] do
            pcall(function()
                Syrniki:Update(Target, Data)
            end)
        end
    end)
end

do
    for _, Player in Players:GetPlayers() do
        Syrniki:AddTarget(Player)
    end

    Syrniki:CreateThreads('PlayerAdded', Players.PlayerAdded, function(Player)
        Syrniki:AddTarget(Player)
    end)

    Syrniki:CreateThreads('PlayerRemoving', Players.PlayerRemoving, function(Player)
        Syrniki:RemoveTarget(Player)
    end)
end

do
    function Syrniki:Unload()
        for Target in self['Cache'] do
            self:RemoveTarget(Target)
        end

        for _, Conn in self['Connections'] do
            Conn:Disconnect()
        end
        Clear(self['Connections'])

        for _, Conn in self['Threads'] do
            Conn:Disconnect()
        end
        Clear(self['Threads'])

        if self['Holder'] then
            self['Holder']:Destroy()
            self['Holder'] = nil
        end

        Clear(self['Cache'])
    end
end

return Syrniki
