for _, func in pairs(RegisteredFunctions) do
    local old_func = _G[func]
    _G[func] = function(x, y, w, h)
        AddSkullflys(x, y)
        old_func(x, y, w, h)
    end
end