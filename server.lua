local Webhook = "https://discord.com/api/webhooks/" -- replace with your own webhook URL
local UseWebhook = true -- set to true to send to discord webhook

--Don't mess with anything below this line
local ProfRunning = false
RegisterConsoleListener(function(channel, message)
    if string.find(message, "server thread hitch warning") then
        if not ProfRunning then
          print("Hitch warning detected, starting profiler")
          ExecuteCommand("profiler record 100")
          ProfRunning = true
        end
    end
    if string.find(message, "Stopped the recording") then
        local resname = GetCurrentResourceName()
        local respath = GetResourcePath(resname)
        ExecuteCommand("profiler saveJSON " .. respath .. "/profiler.json")
    end
    if string.find(message, "Save complete") then
        local oldnamets = 0
        local oldname = None
        local warnmessage = "The following resources are using more tick time than recommended, please check them out:"
        local discordmessage = warnmessage .. "\n"
        local json2 = LoadResourceFile(GetCurrentResourceName(), "profiler.json")
        local traceEvents = json.decode(json2).traceEvents
        print(warnmessage)
        for k,v in pairs(traceEvents) do
            if string.find(v.name, "tick") then
                if oldname == v.name then
                    local ticktime = v.ts - oldnamets
                    if ticktime > 5000 then
                        local name = string.gsub(v.name, "tick", "")
                        local name = string.gsub(name, "%(", "")
                        local name = string.gsub(name, "%)", "")
                        local name = string.gsub(name, " ", "")
                        print(name .. ": " .. ticktime / 1000 .. "ms")
                        discordmessage = discordmessage .. name .. ": " .. ticktime / 1000 .. "ms\n"
                    end
                end
                oldname = v.name
                oldnamets = v.ts
            end
        end
        if UseWebhook then
            PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({content = discordmessage}), { ['Content-Type'] = 'application/json' })
        end
        ProfRunning = false
    end

end)
