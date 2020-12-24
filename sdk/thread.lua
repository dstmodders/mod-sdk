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
local Debug = require "sdk/debug"

local Thread = {}

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
        Debug.String("Thread started")
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
            Debug.String("[" .. thread.id .. "]", "Thread cleared")
        else
            Debug.String("Thread cleared")
        end
        thread = thread ~= nil and thread or task
        KillThreadsWithID(thread.id)
        thread:SetList(nil)
    end
end

return Thread
