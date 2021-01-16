----
-- Different console functionality.
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

--- Adds word prediction dictionaries.
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

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Console
function Console._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Console, "Console")
end

return Console
