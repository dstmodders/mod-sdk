----
-- Different thread functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Thread
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Thread = {}

local SDK

--- Starts a new thread.
--
-- Just a convenience wrapper for the `StartThread`.
--
-- @tparam string id Thread ID
-- @tparam function fn Thread function
-- @tparam[opt] function whl_fn While function
-- @tparam[opt] function init_fn Initialization function
-- @tparam[opt] function term_fn Termination function
-- @treturn table
function Thread.Start(id, fn, whl_fn, init_fn, term_fn)
    whl_fn = whl_fn ~= nil and whl_fn or function()
        return true
    end

    return StartThread(function()
        SDK.Debug.String("Thread started")
        if init_fn then
            init_fn()
        end
        while whl_fn() do
            fn()
        end
        if term_fn then
            term_fn()
        end
        Thread.Clear()
    end, id)
end

--- Clears a thread.
-- @tparam table thread Thread
function Thread.Clear(thread)
    local task = scheduler:GetCurrentTask()
    if thread or task then
        if thread and not task then
            SDK.Debug.String("[" .. thread.id .. "]", "Thread cleared")
        else
            SDK.Debug.String("Thread cleared")
        end
        thread = thread ~= nil and thread or task
        KillThreadsWithID(thread.id)
        thread:SetList(nil)
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Thread
function Thread._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Thread, "Thread")
end

return Thread
