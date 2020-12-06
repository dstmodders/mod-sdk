----
-- Console.
--
-- Includes console functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Console
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Console = {}

local SDK

--- General
-- @section general

--- Adds world prediction dictionaries.
-- @tparam table dictionaries
function Console.AddWordPredictionDictionaries(dictionaries)
    SDK.env.AddClassPostConstruct("screens/consolescreen", function(self, ...)
        for _, dictionary in pairs(dictionaries) do
            if type(dictionary) == "table" then
                self.console_edit:AddWordPredictionDictionary(dictionary)
            elseif type(dictionary) == "function" then
                self.console_edit:AddWordPredictionDictionary(dictionary(self, ...))
            end
        end
    end)
end

--- Executes the console command remotely.
-- @tparam string cmd Command to execute
-- @tparam[opt] table data Data that will be unpacked and used alongside with string
-- @treturn table
function Console.Remote(cmd, data)
    local fn_str = string.format(cmd, unpack(data or {}))
    local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    TheNet:SendRemoteExecute(fn_str, x, z)
end

--- Lifecycle
-- @section lifecycle

--- Initializes console.
-- @tparam SDK sdk
-- @treturn SDK.Console
function Console._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(Console, "Console")
end

return Console
