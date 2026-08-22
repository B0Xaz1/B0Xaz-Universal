-- src/DrawingManager.lua
return function()
    local drawingAvailable = false
    pcall(function()
        local t = Drawing.new("Line")
        t.Visible = false
        t:Remove()
        drawingAvailable = true
    end)

    getgenv().B0XazAllDrawings = getgenv().B0XazAllDrawings or {}

    local DrawingManager = {
        Available = drawingAvailable
    }

    local function track(obj)
        if obj then
            table.insert(getgenv().B0XazAllDrawings, obj)
        end
        return obj
    end

    function DrawingManager.NewLine(props)
        if not drawingAvailable then return nil end
        local ok, obj = pcall(function()
            local l = Drawing.new("Line")
            l.Visible = false
            l.Thickness = props and props.Thickness or 1
            l.Color = props and props.Color or Color3.new(1, 1, 1)
            l.Transparency = props and props.Transparency or 1
            return l
        end)
        return ok and track(obj) or nil
    end

    function DrawingManager.NewCircle(props)
        if not drawingAvailable then return nil end
        local ok, obj = pcall(function()
            local c = Drawing.new("Circle")
            c.Visible = false
            c.Radius = props and props.Radius or 10
            c.Color = props and props.Color or Color3.new(1, 1, 1)
            c.Thickness = props and props.Thickness or 1
            c.Filled = props and props.Filled or false
            c.Transparency = props and props.Transparency or 1
            c.NumSides = props and props.NumSides or 64
            return c
        end)
        return ok and track(obj) or nil
    end

    function DrawingManager.NewSquare(props)
        if not drawingAvailable then return nil end
        local ok, obj = pcall(function()
            local s = Drawing.new("Square")
            s.Visible = false
            s.Thickness = props and props.Thickness or 2
            s.Filled = props and props.Filled or false
            s.Transparency = props and props.Transparency or 1
            s.Color = props and props.Color or Color3.new(1, 1, 1)
            return s
        end)
        return ok and track(obj) or nil
    end

    function DrawingManager.NewText(props)
        if not drawingAvailable then return nil end
        local ok, obj = pcall(function()
            local t = Drawing.new("Text")
            t.Visible = false
            t.Size = props and props.Size or 14
            t.Center = (props and props.Center ~= nil) and props.Center or true
            t.Outline = (props and props.Outline ~= nil) and props.Outline or true
            t.Font = props and props.Font or 2
            t.Color = props and props.Color or Color3.new(1, 1, 1)
            t.Text = ""
            return t
        end)
        return ok and track(obj) or nil
    end

    function DrawingManager.SafeRemove(drawing)
        if not drawing then return end
        pcall(function() drawing.Visible = false end)
        pcall(function()
            if drawing.Remove then drawing:Remove() end
        end)
    end

    function DrawingManager.RemoveAll()
        local list = getgenv().B0XazAllDrawings
        if type(list) == "table" then
            for i = #list, 1, -1 do
                DrawingManager.SafeRemove(list[i])
                list[i] = nil
            end
        end
        getgenv().B0XazAllDrawings = {}
    end

    return DrawingManager
end
