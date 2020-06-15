local ConstantScanner = {}
local Constant = import("objects/Constant")

local requiredMethods = {
    getGc = true,
    getInfo = true,
    isXClosure = true,
    getConstant = true,
    setConstant = true,
    getConstants = true
}

local function compareConstant(query, constant)
    local constantType = type(constant)

    local stringCheck = constantType == "string" and (query == constant or constant:lower():find(query:lower()))
    local numberCheck = constantType == "number" and (tonumber(query) == constant or ("%.2f"):format(constant) == query)
    local userDataCheck = constantType == "userdata" and toString(constant) == query

    if constantType == "function" then
        local closureName = getInfo(constant).name
        return query == closureName or closureName:lower():find(query:lower())
    end

    return stringCheck or numberCheck or userDataCheck
end 

local function scan(query)
    local constants = {}

    for i, closure in pairs(getGc()) do
        if type(closure) == "function" and not isXClosure(closure) and isLClosure(closure) and not constants[closure] then
            for index, constant in pairs(getConstants(closure)) do
                if compareConstant(query, constant) then
                    local storage = constants[closure]

                    if not storage then
                        constants[closure] = { [index] = Constant.new(closure, index, constant) }
                    else
                        storage[index] = Constant.new(closure, index, constant)
                    end
                end
            end
        end
    end

    return constants
end

ConstantScanner.Scan = scan
ConstantScanner.RequiredMethods = requiredMethods
return ConstantScanner