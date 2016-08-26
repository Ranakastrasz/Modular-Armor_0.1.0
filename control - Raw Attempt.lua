--require "defines"
require "config"
require 'libs/EvoGUI'
--require "interfaces"

--[[
    This module handles the gameloop alteration, allowing conduit modules in power armor grid to tranfer energy between your power grid and your armor.

]]--

--[[
    Figure out if you can access energy network with the get network command thinggy.
    Alternately, do aura search, steal power from accumulators and roboports. /Done
    
    Add command to disable conduit mechanics.
    -Shield pulse visial /Done, Removed to seperate mod
    -Better Energy Distribution
    -Sheld autobalance /Done
    -Boost batteries. Add higher tier,larger battery(s) /Done
    -Finish tech fixing /Done
    -Add GUI display for fuel.
    -Add custom fuel slot.
    -Method to discharge energy into network?
]]--

luadata = nil



--



function verifySettings()
	if (RanaMods.ModularArmor.config.tickRate < 0) then
		RanaMods.ModularArmor.config.tickRate = 1
		throwError("Tick rate must be >= 0.")
	end
end

script.on_init(function()
       -- globalPrint("onLoad")
	if (global.loaded == nil) then
		global.loaded = true
       -- globalPrint("loaded")
        
		verifySettings()
	end
    refresh_equipment()
    
    --[[if (not global.surface) then
        global.surface = game.surfaces['nauvis']
    end]]--
    if (not global.modularArmor) then
        global.modularArmor = {}
    end
    if (global.ticking == nil) then
        global.ticking = 0
    end
	--if not evo_gui then
		--evo_gui = EvoGUI.new(Natural_Evolution_state)
		--evo_gui = EvoGUI.new(Expansion_State)
		
	--end	
    script.on_event(defines.events.on_tick, ticker)
end
)

script.on_configuration_changed(function(data)
    if data.mod_changes ~= nil and data.mod_changes["Modular-Armor"] ~= nil then
        if data.mod_changes["Modular-Armor"].old_version == nil then
            -- "My Mod" was added to an existing game
            refresh_equipment()
        elseif data.mod_changes["Modular-Armor"].old_version ~= data.mod_changes["Modular-Armor"].new_version then
            refresh_equipment()

        end
    end
end)

function globalPrint(msg)
  local players = game.players
  --if RanaMods.ModularArmor.config.Debug then
      for x=1, #players do
        game.players[x].print(msg)
      end
  --end
end


function tableIsEmpty(t)
	if (t) then
		for k in pairs(t) do
			return false
		end
	end
	return true
end



function registerEquipmentGroup(iGroup)

    --iGroup.mod = iMod
    if not RanaMods.ModularArmor.equipmentData then
        RanaMods.ModularArmor.equipmentData = {}

    end
    if iGroup and iGroup.name and iGroup.type then
        globalPrint(iGroup.name.." "..iGroup.type)
        
        for _, v in pairs(RanaMods.ModularArmor.equipmentData) do
            if v.name == iName then
                return
            end
        end
        table.insert(RanaMods.ModularArmor.equipmentData, iGroup)
        
    else
        return "Invalid Table"
    end
end

function registerPrototype (iGroup,iPrototype,iType)
-- Ideally, this will register equipment group itself, if it doesn't yet exist.
    if not RanaMods.ModularArmor.equipmentData then
        RanaMods.ModularArmor.equipmentData = {}
    end
    if iGroup and iGroup.name and iGroup.type then
        if iPrototype and iPrototype.name and iPrototype.power then

            for _, v in pairs(RanaMods.ModularArmor.equipmentData) do
                if v.name == iGroup.name then

                    thisTable = nil
                    if iType == "equipment" then
                        if not v.equipment then
                            v.equipment = {}
                        end
                        thisTable = v.equipment
                    elseif iType == "fuel" then
                        if not v.fuel then
                            v.fuel = {}
                        end
                        thisTable = v.fuel
                    else
                        globalPrint("Invalid Type "..iType)
                        return "Invalid Type"
                    end
                    
                    
                    for _, data in pairs(thisTable) do
                        if data.name == iPrototype.name then
                            data = iPrototype
                            return
                        end
                    end
                    table.insert(thisTable, iPrototype)
                    
                    break
                end
            end
        else
            return "Invalid iPrototype"
        end
    else
        return "Invalid iGroup"
    end
end


function reset_equipment()
    globalPrint("reset_equipment")
    RanaMods.ModularArmor.equipmentData = {}
end

function refresh_equipment()
    luadata = {raw = loadstring(game.entity_prototypes["DATA_RAW"].order)()}
    reset_equipment()
    for i, equipment in pairs (luadata.raw["battery-equipment"]) do
        if equipment.rana_mod then
            if equipment.rana_mod.powerType then
                -- This will happen repeatedly, but it should work correctly even with duplicate registrations, just failing instead.
                registerEquipmentGroup({name = equipment.rana_mod.powerGroup,type = equipment.rana_mod.powerType})
                registerPrototype({name = equipment.rana_mod.powerGroup,type = equipment.rana_mod.powerType},{name = equipment.name     ,power =  equipment.rana_mod.fuelPower},"equipment")
            end
            -- might have more data attachment types later.
        end
    end
    
    for i, fuel in pairs (luadata.raw["item"]) do
        if fuel.rana_mod then

            if fuel.rana_mod.powerType then
            
                registerEquipmentGroup({name = fuel.rana_mod.powerGroup,type = fuel.rana_mod.powerType})
                registerPrototype({name = fuel.rana_mod.powerGroup,type = fuel.rana_mod.powerType},{name = fuel.name     ,power =  fuel.rana_mod.fuelPower},"fuel")
            end
        end
    end
    
    
    --[[registerEquipmentGroup({name = "conduit",type = "conduit"})
    registerEquipmentGroup({name = "burner" ,type = "fuelled"})
    registerEquipmentGroup({name = "fusion" ,type = "fuelled"})

    registerPrototype({name = "conduit",type = "conduit"},{name = "semi-conduit-conduit-equipment"     ,power =  40 * 1000},"equipment","Modular-Armor")
    registerPrototype({name = "conduit",type = "conduit"},{name = "power-conduit-equipment"            ,power = 720 * 1000},"equipment","Modular-Armor")
    registerPrototype({name = "burner" ,type = "fuelled"},{name = "engine-equipment"                   ,power = 100 * 1000},"equipment","Modular-Armor")
    registerPrototype({name = "fusion" ,type = "fuelled"},{name = "fusion-reactor-equipment"           ,power = 960 * 1000},"equipment","Modular-Armor")
                    ]]--   
    --[[registerPrototype({name = "burner" ,type = "fuelled"},{name = "solid-fuel"  ,power = 25     * 1000 * 1000},"fuel","Modular-Armor")
    registerPrototype({name = "burner" ,type = "fuelled"},{name = "coal"        ,power = 8.     * 1000 * 1000},"fuel","Modular-Armor")
    registerPrototype({name = "burner" ,type = "fuelled"},{name = "raw-wood"    ,power = 4.     * 1000 * 1000},"fuel","Modular-Armor")
    registerPrototype({name = "fusion" ,type = "fuelled"},{name = "alien-fuel"  ,power = 200.   * 1000 * 1000},"fuel","Modular-Armor")
]]--

end

function ticker() -- run once per tickRate number of gameticks.
    if (game.tick % RanaMods.ModularArmor.config.tickRate) == 0 then
		tick()
        
	else
	end
    if (game.tick %  60) == 0 then
        refresh_equipment()
    end
end



function tickDummies(id,iSurface,iPosition) -- This and kill dummies need to use a factory. I have no idea what that is. Need research

    if not id.units then
        id.units = {}
    else
        -- Already exists.
    end
    if not id.units.accumulator then
        id.units.accumulator = iSurface.create_entity{name = "laser-turret-dummy", position = iPosition, force=game.forces.player}
        id.units.accumulator.energy = RanaMods.ModularArmor.config.accumulatorEnergyCap -- initialize energy levels
        id.previousEnergy = id.units.accumulator.energy -- and previous energy level from last tick
        id.units.accumulator.destructible = false -- Make dummy invulnerable.
    else
        id.units.accumulator.teleport(iPosition) -- Ensure that the power drain dummy is always at the player's position.
    end
    
    --[[if not id.units.pole then
        id.units.pole = global.surface.create_entity{name = "electric-pole-dummy", position = positionz, force=game.forces.player}
        id.units.pole.destructible = false
    else
        id.units.pole.teleport(positionz)
    end
    
    if not id.units.solar then
        id.units.solar = global.surface.create_entity{name = "solar-panel-dummy", position = positionz, force=game.forces.player}
        id.units.solar.destructible = false
    else
        id.units.solar.teleport(positionz)
    end]]--
end
function killDummies(id)
    if id.units then
        if id.units.accumulator then
            id.units.accumulator.destroy()
            id.units.accumulator = nil
        else
            -- Already gone
        end
        --[[if id.units.pole then
            id.units.pole.destroy()
            id.units.pole = nil
        else
            -- Already gone
        end
        if id.units.solar then
            id.units.solar.destroy()
            id.units.solar = nil
        else
          -- Already gone
        end]]--
    else
        -- Already deleted.
    end
end

function tick()
	local shouldKeepTicking
    local thisPlayer = nil
    local players = game.players
    --globalPrint("tick")
    shouldKeepTicking = true -- Due to lack of any alternate method of detecting player's armor state, we have to always tick.

    
    for x=1, #players do
        thisPlayer = players[x]
        if (thisPlayer.connected) then
            if (thisPlayer.character) then
                --game.getplayer(1).print(x..' '..player)
                
                --if not global.modularArmor[x] then
                --    global.modularArmor[x] = {}
                --end
                local modularArmor = global.modularArmor[x]
                
                if (not modularArmor) then
                    
                    modularArmor = {} -- ensure player has data attached
                    --modularArmor.storedFuel = {["steam"] = 0, ["fusion"] = 0}
                    global.modularArmor[x] = modularArmor
                    
                    --[[if (RanaMods.ModularArmor.config.Debug == true) then
                
                        game.always_day=true -- test mode stuff
                        thisPlayer.insert{name="basic-grenade",count=50}
                        thisPlayer.insert{name="energy-shield-basic-equipment",count=20}
                        thisPlayer.insert{name="energy-shield-equipment",count=20}
                        thisPlayer.insert{name="energy-shield-mk2-equipment",count=10}
                        --thisPlayer.insert{name="energy-shield-module-equipment",count=10}
                        --thisPlayer.insert{name="energy-shield-core-equipment",count=5}
                        
                        thisPlayer.insert{name="power-conduit-equipment",count=40}
                        thisPlayer.insert{name="engine-equipment",count=10}
                        thisPlayer.insert{name="fusion-reactor-equipment",count=10}
                        --thisPlayer.insert{name="power-conduit-core-equipment",count=5}
                        
                        thisPlayer.insert{name="coal",count=50}
                        thisPlayer.insert{name="solid-fuel",count=50}
                        thisPlayer.insert{name="alien-fuel",count=50}

                        --thisPlayer.insert{name="solar-panel-equipment-node",count=20}
                        thisPlayer.insert{name="solar-panel-equipment",count=20}
                        thisPlayer.insert{name="solar-panel-equipment-mk2",count=10}
                        thisPlayer.insert{name="basic-actuator-equipment",count=20}
                        thisPlayer.insert{name="basic-exoskeleton-equipment",count=20}

                        thisPlayer.insert{name="battery-equipment",count=5}
                        thisPlayer.insert{name="battery-mk2-equipment",count=5}
                        thisPlayer.insert{name="battery-mk3-equipment",count=5}
                        thisPlayer.insert{name="battery-mk4-equipment",count=5}
                        thisPlayer.insert{name="power-armor-mk2",count=1}
                        thisPlayer.insert{name="power-armor",count=1}
                        thisPlayer.insert{name="basic-modular-armor",count=1}
                        
                        
                        thisPlayer.insert{name="basic-laser-defense-equipment",count=5}
                        thisPlayer.insert{name="basic-electric-discharge-defense-equipment",count=5}
                        thisPlayer.insert{name="basic-electric-discharge-defense-remote",count=1}
                        
                        
                        thisPlayer.insert{name="small-electric-pole",count=50}
                        thisPlayer.insert{name="solar-panel",count=50}
                        thisPlayer.insert{name="basic-accumulator",count=50}
                        thisPlayer.insert{name="basic-mining-drill",count=50}
                    end]]--
                    
                end
                if (not modularArmor.storedFuel) then
                    modularArmor.storedFuel = {}
                end
                for x,equipmentData in ipairs(RanaMods.ModularArmor.equipmentData) do
                    if equipmentData.type == "fuelled" then
                        if not modularArmor.storedFuel[x] then
                            modularArmor.storedFuel[x] = 1
                        end
                    end
                end
                
                -- Removed till I can figure out how to fix the entity.
                --[[if modularArmor.units and modularArmor.units.name == "modular-accumulator-dummy" then
                    modularArmor.units.destroy()
                end
                if modularArmor.units == nil then
                    modularArmor.units = {}
                end]]--
                -- Ensure dummies exist.
                --[[]]--
                
                local armor = thisPlayer.get_inventory(defines.inventory.player_armor)[1] -- Check for armour presence.
                
                -- /c ((game.players[1].get_inventory(defines.inventory.player_armor)[1]).grid).put{equipment = "battery-equipment"}
                -- /c ((game.players[1].get_inventory(defines.inventory.player_armor)[1]).grid).put{equipment = game.players[1].insert{name = "battery-equipment",count=1}}
                
                if (armor.valid_for_read) then
                    
                    if (armor.has_grid) then -- Check for grid existence.
                        local grid = armor.grid
                        
                        tickDummies(modularArmor,thisPlayer.character.surface,thisPlayer.character.position)-- validate, create, and move dummy units.
                        
                        
                        
                        local transferRate = 0 -- Rate of transfer from external network to armor.
                    
                        --transferRate = transferRate + ArmorTransferRatePerGridSize*grid.width*grid.height
                        
                        local fuelRates = {}
                    
                        local energy = 0 -- Total energy and energy capacity
                        local energyCap = 0 -- need smallest fraction count as well. Essentially, if any of them have less than 50% or 90%, activate fusion and steam respectively.
                        --local hasBattery = false -- Due to lack of a good energy distrubution system, I only limit production so long as you have a battery. Otherwise, things near the end of the list don't get any energy.
                        -- Disabled, since power distribution percentages of 98 and 99% don't really have problems anymore. You would need 50 mini-shields, which wont happen
                        local shieldHealth = 0 -- Total shield and shield capacity for auto-balancing.
                        local shieldCap = 0
                        for x,equipment in ipairs(grid.equipment) do -- Loop through all equipment.
                            if (equipment.max_energy ~= 0) then
                                energy = energy + equipment.energy -- If it has energy, add values to total value.
                                energyCap = energyCap + equipment.max_energy
                                --if equipment.type == "battery-equipment" then
                                --    hasBattery = true
                                --else
                                
                                --end
                            else
                            
                            end
                            
                            if equipment.max_shield ~= 0 then
                                shieldHealth = shieldHealth + equipment.shield -- Same with shield.
                                shieldCap = shieldCap + equipment.max_shield
                            else
                            end
                            
                            for x,equipmentData in ipairs(RanaMods.ModularArmor.equipmentData) do -- Count all scripted equipment
                                    --globalPrint(x)
                                for y,equipmentType in ipairs (equipmentData.equipment) do
                                    --globalPrint(y)
                                    --globalPrint(equipmentType.name)
                                    if (equipment.name == equipmentType.name) then
                                    --globalPrint(equipment.name.." ? "..fuelType)
                                         if equipmentData.type == "fuelled" then -- Get total production rate for each type.

                                            if not fuelRates[x] then
                                                fuelRates[x] = equipmentType.power
                                            else
                                                fuelRates[x] = fuelRates[x] + equipmentType.power
                                            end
                                        elseif equipmentData.type == "conduit" then -- And network transfer rate.
                                            transferRate = transferRate + equipmentType.power
                                        end
                                    else
                                        
                                    end
                                end
                            end
                            
                                
                            --[[if (equipment.name == "power-conduit-equipment") then -- Also count each conduit module.
                                transferRate = transferRate + data.ConduitTransferRatePerEquipment
                            end]]--
                        end
                        
                        
                        
                        local shieldFraction = shieldHealth/shieldCap
                        local energyWanted = energyCap-energy
                        local transferRate = math.min(transferRate,energyWanted) -- We cant transfer energy without space to put it into
                        
                        --local accumulatorEnergy = 0*conversionAntiRatio -- Temporarily removed.
                        local accumulatorEnergy = (modularArmor.units.accumulator.energy - modularArmor.previousEnergy)--*conversionAntiRatio -- How much energy was accumulated since last tick
                        --globalPrint("Accumulator "..accumulatorEnergy)
                        local energyToAdd = math.min(transferRate,accumulatorEnergy) -- Accumulated energy, or transfer wanted, whichever is lower.
                        local newEnergy = energy+energyToAdd
                        local storageRatio = newEnergy/energyCap
                        
                        accumulatorEnergy = accumulatorEnergy - energyToAdd -- Remove 
                        -- SFX
                        -- if energyToAdd >= 10000 and game.tick%60 == 0 then
                        --    global.surface.create_entity{name = "conduit-sparks", position = thisPlayer.character.position, force=game.forces.neutral}
                        --end
                        --globalPrint("Accumulator -- "..accumulatorEnergy)
                        --global.surface.create_entity{name = "smoke-fast", position = thisPlayer.character.position, force=game.forces.neutral} 
                        
                        for x,equipment in ipairs(RanaMods.ModularArmor.equipmentData) do
                            if equipment.type == "fuelled" then
                                
                               --globalPrint("detected Generator "..(fuelRates.fuelType)..(fuelType))
                                if (fuelRates[x] and (fuelRates[x] > 0.0)) then -- Make sure it exists, and that is is above zero.
                                    --globalPrint("detected Generator "..fuelRates.fuelType..fuelType)
                                    -- This type exists
                                    local threshhold = energyCap -- How much power this generator is allowed to bring you up to.
                                    -- Currently leaving it at 100% for now, till I have a better idea how I want to do this.
                                    --if hasBattery then
                                        --threshhold = threshhold * fuelVal.threshhold -- Without a battery, you cannot regulate energy production.
                                    --else
                                        
                                    --end
                                    local energyWanted = threshhold - newEnergy -- How much power we want to generate
                                    energyWanted = math.max(energyWanted,0) -- Can't request negative power
                                    energyWanted = math.min(energyWanted,fuelRates[x]) -- Can't make more power than the engines can support
                                    local energyToGenerate = 0
                                    
                                    --globalPrint("Stored "..modularArmor.storedFuel[x]..fuelType)
                                    --globalPrint("Wanted "..energyWanted)
                                    if (modularArmor.storedFuel[x] < energyWanted) then
                                        -- Check for fuel. If available, consume. If not, spend what you have
                                        local mainInventory = thisPlayer.get_inventory(defines.inventory.player_main)
                                        local validFuel = nil
                                        for y,fuel in ipairs(equipment.fuel) do
                                            if (mainInventory.get_item_count(fuel.name) > 0) then
                                                -- Got some
                                                validFuel = fuel
                                                break
                                            else
                                                -- No luck, skip it
                                            end
                                            --globalPrint(fuel[x][1].." "..mainInventory.get_item_count(fuel[x][1]))
                                        end
                                        if (validFuel) then
                                            mainInventory.remove{name = validFuel.name, count = 1}
                                            modularArmor.storedFuel[x] = modularArmor.storedFuel[x] + validFuel.power
                                            --surface.create_entity{name="flying-text", position=thisPlayer.character.position, text=("-1 "..validFuel[1]), color={r=1,g=1,b=1}}
                                            --globalPrint(validFuel[1].." "..modularArmor.storedFuel[x])
                                        else
                                            if RanaMods.ModularArmor.config.LowFuelMessage then
                                                if (game.tick%RanaMods.ModularArmor.config.ticksPerSecond == 0) then
                                                    thisPlayer.character.surface.create_entity{name="flying-text", position=thisPlayer.character.position, text=("No "..(equipment.name).." fuel"), color={r=1,g=0.25,b=0.25}}
                                                -- Needs a better feedback method.
                                                else
                                                  
                                                end
                                            end

                                            -- Out of fuel
                                            --globalPrint("No fuel")
                                        end
                                        
                                        
                                    else
                                        -- Have enough fuel already.
                                    end
                                    energyToGenerate = math.min(modularArmor.storedFuel[x],energyWanted)
                                    
                                    modularArmor.storedFuel[x] = modularArmor.storedFuel[x] - energyToGenerate
                                    
                                    
                                        
                                    energyToAdd = energyToAdd + energyToGenerate
                                    
                                    --global.surface.pollute(thisPlayer.character.position, energyToGenerate*RanaMods.ModularArmor.config.pollutionCoef)
                                    
                                  
                                        
                                    --end
                                else
                                    -- No such generator.
                                end
                            else
                                -- Its a conduit.
                            end
                        end
                        
                        -- I have energy to add, Energy Cap, and current energy.
                        -- I want to give amount proportional to amount missing to each elements. Ones with less get a higher fraction.
                        -- The amount I have available needs to be split into fractions of amount missing overall.
                        -- For each point missing from an element, add energyFraction to it.
                        -- Calc extra as well, and if it is greater than like 10%, feed into accumulator for next tick.
                        
                        
                        --globalPrint("energyFraction"..energyFraction)
                        --globalPrint("energyToAdd"..energyToAdd)
                        
                        --globalPrint("energySpent"..energySpent)
                        shieldHealth = 0
                        for x,equipment in ipairs(grid.equipment) do -- Basic Setup. Distribute as much to first in line, remainder to next, and next, till you run out.
                            if (equipment.max_energy ~= 0 and energyToAdd > 0) then          -- Poor Distribution method.
                                local difference = equipment.max_energy - equipment.energy
                                if (energyToAdd > difference) then
                                    energyToAdd = energyToAdd - difference
                                    equipment.energy = equipment.max_energy
                                else
                                    equipment.energy = equipment.energy + energyToAdd
                                    energyToAdd = 0
                                    --break -- Removed since it interferes with shield.
                                end
                            end  
                            if (equipment.max_shield ~= 0) then
                                
                                equipment.shield = equipment.max_shield * shieldFraction -- This part is a quick autobalance. All shields get equal power.
                                shieldHealth = shieldHealth + equipment.shield
                                --equipment.shield = equipment.shield - (equipment.max_shield*ShieldDecayPerTick)
                            else -- Ideally, I want to send power from high efficiency ones to lower efficiency ones. That minimizes power consumption.
                                
                            end
                        end
                        --globalPrint("Shield Initial: "..shieldInitial)
                        --globalPrint("Shield After: "..shieldHealth)
                        --globalPrint("Shield Diff: "..shieldHealth-shieldInitial)
                        
                               
                        --globalPrint("accumulatorEnergy "..accumulatorEnergy)
                        --globalPrint("transferRate "..transferRate)
                        --globalPrint("accumulatorEnergyCap "..accumulatorEnergyCap)
                        
                        modularArmor.units.accumulator.energy = RanaMods.ModularArmor.config.accumulatorEnergyCap - transferRate--*conversionRatio
                        modularArmor.previousEnergy = modularArmor.units.accumulator.energy --*conversionRatio -- The additional accumulated energy over
                        
                        
                        
                    else
                        killDummies(modularArmor)
                    end
                else
                    killDummies(modularArmor)
                end
            else
                -- No player
                -- killDummies(modularArmor)
            end
        end
            
    end
    
	if (not shouldKeepTicking) then
		global.ticking = nil
		script.onevent(defines.events.ontick, nil)
	end
end