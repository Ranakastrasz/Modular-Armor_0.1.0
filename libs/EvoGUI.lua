
EvoGUI = {}

function EvoGUI.new()

    function EvoGUI:createEvolutionRateText()
        local diff = game.evolution_factor - global.exponential_moving_average
        -- percentage is decimal * 100, * 60 for per minute value
        local evo_rate_per_min = math.abs(diff * 100 * 60)
        
        -- this nonsense is because string.format(%.3f) is not safe in MP across platforms, but integer math is
        local whole_number = math.floor(evo_rate_per_min)
        local fractional_component = math.floor((evo_rate_per_min - whole_number) * 1000)
        local text = string.format("%d.%04d%%", whole_number, fractional_component)
        if diff > 0 then
            return "Evolution Rate: +" .. text .. " / min"
        else
            return "Evolution Rate: -" .. text .. " / min"
        end
    end

    function EvoGUI:calculateEvolutionRateColor()
        local diff = game.evolution_factor - global.exponential_moving_average
        
        if diff > 0 then
            local red = (100 * 255 * diff) / 0.0035
            return { r = math.max(0, math.min(255, math.floor( red ))), g = math.max(0, math.min(255, math.floor( 255 - red ))), b = 0 }
        else
            return { r = 0, g = 255, b = 0 }
        end
    end

    function EvoGUI:createEvolutionText()
        local text = "Evolution State: " .. global.Natural_Evolution_state
        text = text .. " ( " .. math.floor(global.Natural_Evolution_Timer / 60) .. "s )"
        return text
    end
    
    function EvoGUI:setup()
        if remote.interfaces.EvoGUI and remote.interfaces.EvoGUI.create_remote_sensor then
            global.evo_gui.detected = true

            remote.call("EvoGUI", "create_remote_sensor", {
                mod_name = "Natural Evolution",
                name = "evolution_state",
                text = "Evolution State:",
                caption = "Evolution State"
            })
            remote.call("EvoGUI", "create_remote_sensor", {
                mod_name = "Natural Evolution",
                name = "evolution_rate",
                text = "Evolution Rate:",
                caption = "Evolution Rate"
            })
            self:updateGUI()
        end
    end

    function EvoGUI:tick()
        if not global.evo_gui then global.evo_gui = {} end
        if not global.exponential_moving_average then
            global.exponential_moving_average = game.evolution_factor
        end

        if not global.evo_gui.detected then
            self:setup()
        end
        if global.evo_gui.detected and game.tick % 3 == 0 then
            self:updateGUI()
            if game.tick % 60 == 0 then
                global.exponential_moving_average = global.exponential_moving_average + (0.8 * (game.evolution_factor - global.exponential_moving_average))
            end
        end
    end

    function EvoGUI:updateGUI()
        -- figure out what color to make the text here (if any)
        local color = { r = 255, g = 255, b = 255 }

        remote.call("EvoGUI", "update_remote_sensor", "evolution_state", self:createEvolutionText(), color)
        remote.call("EvoGUI", "update_remote_sensor", "evolution_rate", self:createEvolutionRateText(), self:calculateEvolutionRateColor())
    end

    return EvoGUI
end

return EvoGUI