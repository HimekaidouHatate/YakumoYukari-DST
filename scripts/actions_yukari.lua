local ActionHandler = GLOBAL.ActionHandler
local FRAMES = GLOBAL.FRAMES
local EventHandler = GLOBAL.EventHandler
local TimeEvent = GLOBAL.TimeEvent
local SpawnPrefab = GLOBAL.SpawnPrefab
local State = GLOBAL.State
local ACTIONS = ACTIONS
local Action = GLOBAL.Action
local Language = GetModConfigData("language")

-- Action Settings for Yukari --

local UTELEPORT = Action({1, false, true})
	UTELEPORT.id = "UTELEPORT"
	UTELEPORT.str = "Teleport"
	UTELEPORT.fn = function(act)
		print(act.pos, act.target)
		if act.invobject ~= nil and act.invobject.components.makegate ~= nil then
			return act.invobject.components.makegate:Teleport(act.pos, act.doer)
		end
	end

local function action_teleport(inst, doer, target, actions, right)
	table.insert(actions, ACTIONS.UTELEPORT)
end

AddStategraphPostInit("wilson", function(Stategraph)
	
	local state = State {
        name = "uteleport",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        end,

        timeline = 
        {
            TimeEvent(8*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },


    }
	
	Stategraph.states["uteleport"] = state

end)

AddAction(UTELEPORT)
AddComponentAction("USEITEM", "uteleport", action_teleport)
AddStategraphActionHandler("wilson", ActionHandler(UTELEPORT, "uteleport"))


local SPAWNG = Action({1, false, true})
SPAWNG.id = "SPAWNG"
SPAWNG.str = "Spawn"
SPAWNG.fn = function(act)
    if act.invobject and act.invobject.components.makegate then
        return act.invobject.components.makegate:RCreate(act.pos, act.doer)
    end
end

AddStategraphPostInit("wilson", function(Stategraph)
	
	local state = State {
        name = "spawnrgate",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        end,

        timeline = 
        {
            TimeEvent(8*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },
    }
	
	Stategraph.states["spawnrgate"] = state

end)

------------------------------------------------------------------------------------------------------------------------
local CASTTOHO = Action({-1, false, true})
CASTTOHO.id = "CASTTOHO"
CASTTOHO.str = "castspell"
CASTTOHO.fn = function(act)
	local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if staff and staff.components.spellcard and staff.components.spellcard:CanCast(act.doer, act.target, act.pos) then
		staff.components.spellcard:CastSpell(act.target, act.pos)
		return true
	end
end

AddStategraphPostInit("wilson", function(Stategraph)

	local state = State {
        name = "casttoho",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("staff") 
            inst.components.locomotor:Stop()
            inst.stafffx = SpawnPrefab("staffcastfx")  
			--Spawn an effect on the player's location
			local pos = inst:GetPosition()
            inst.stafffx.Transform:SetPosition(pos.x, pos.y, pos.z)
            inst.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.stafffx.AnimState:SetMultColour(95/255, 0, 1, 1)
        end,
		
		onexit = function(inst)
            inst.components.playercontroller:Enable(true)
			if inst.stafffx then
                inst.stafffx:Remove()
            end
        end,

        timeline = 
        {
            TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("soundpack/spell/spelldt") -- Add Custom Sound
            end),
			TimeEvent(0*FRAMES, function(inst)
                inst.stafflight = SpawnPrefab("staff_castinglight")
                local pos = inst:GetPosition()
                local colour = {95/255,0,1}
                inst.stafflight.Transform:SetPosition(pos.x, pos.y, pos.z)
                inst.stafflight.setupfn(inst.stafflight, colour, 1.9, .33)                

            end),
			TimeEvent(53*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },
    }
	
	Stategraph.states["casttoho"] = state

end)

local CASTTOHOL = Action({-1, false, true}) -- Light motion
CASTTOHOL.id = "CASTTOHOL"
CASTTOHOL.str = "castspell"
CASTTOHOL.fn = function(act)
	local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if staff and staff.components.spellcard and staff.components.spellcard:CanCast(act.doer, act.target, act.pos) then
		staff.components.spellcard:CastSpell(act.target, act.pos)
		return true
	end
end

AddStategraphPostInit("wilson", function(Stategraph)

	local state = State {
        name = "casttohol",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("staff") 
            inst.components.locomotor:Stop()
            inst.stafffx = SpawnPrefab("staffcastfx")  
			--Spawn an effect on the player's location
			local pos = inst:GetPosition()
            inst.stafffx.Transform:SetPosition(pos.x, pos.y, pos.z)
            inst.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.stafffx.AnimState:SetMultColour(95/255, 0, 1, 1)
        end,
		
		onexit = function(inst)
            inst.components.playercontroller:Enable(true)
			if inst.stafffx then
                inst.stafffx:Remove()
            end
        end,

        timeline = 
        {
            TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_gemstaff") -- Add Custom Sound
            end),
			TimeEvent(0*FRAMES, function(inst)
                inst.stafflight = SpawnPrefab("staff_castinglight")
                local pos = inst:GetPosition()
                local colour = {95/255,0,1}
                inst.stafflight.Transform:SetPosition(pos.x, pos.y, pos.z)
                inst.stafflight.setupfn(inst.stafflight, colour, 1.9, .33)                

            end),
			TimeEvent(53*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },
    }
	
	Stategraph.states["casttohol"] = state

end)


local CASTTOHOH = Action({-1, false, true}) -- Heavy motion
CASTTOHOH.id = "CASTTOHOH"
CASTTOHOH.str = "castspell"
CASTTOHOH.fn = function(act)
	local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if staff and staff.components.spellcard and staff.components.spellcard:CanCast(act.doer, act.target, act.pos) then
		staff.components.spellcard:CastSpell(act.target, act.pos)
		return true
	end
end


AddStategraphPostInit("wilson", function(Stategraph)

	local state = State {
        name = "casttohoh",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
			inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("staff") 
            inst.components.locomotor:Stop()
            inst.stafffx = SpawnPrefab("staffcastfx")  
			--Spawn an effect on the player's location
			local pos = inst:GetPosition()
            inst.stafffx.Transform:SetPosition(pos.x, pos.y, pos.z)
            inst.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.stafffx.AnimState:SetMultColour(95/255, 0, 1, 1)
        end,
		
		onexit = function(inst)
            inst.components.playercontroller:Enable(true)
			inst.components.health:SetInvincible(false)
			if inst.stafffx then
                inst.stafffx:Remove()
            end
        end,

        timeline = 
        {
            TimeEvent(17*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("soundpack/spell/bigspell") -- Add Custom Sound
            end),
			TimeEvent(0*FRAMES, function(inst)
                inst.stafflight = SpawnPrefab("staff_castinglight")
                local pos = inst:GetPosition()
                local colour = {95/255,0,1}
                inst.stafflight.Transform:SetPosition(pos.x, pos.y, pos.z)
                inst.stafflight.setupfn(inst.stafflight, colour, 1.9, .33)                

            end),
			TimeEvent(53*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("soundpack/spell/border")
				inst:PerformBufferedAction() 
			end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },
    }
	
	Stategraph.states["casttohoh"] = state

end)

local LAMENT = Action({-1, false, true}) -- Heavy motion
LAMENT.id = "LAMENT"
LAMENT.str = "waiting"
LAMENT.fn = function(act)
	local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if staff and staff.components.spellcard and staff.components.spellcard:CanCast(act.doer, act.target, act.pos) then
		staff.components.spellcard:CastSpell(act.target, act.pos)
		return true
	end
end

AddStategraphPostInit("wilson", function(Stategraph)

	local state = State {
        name = "lament",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
			inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("staff") 
            inst.components.locomotor:Stop()
            inst.stafffx = SpawnPrefab("staffcastfx")  
			--Spawn an effect on the player's location
			local pos = inst:GetPosition()
            inst.stafffx.Transform:SetPosition(pos.x, pos.y, pos.z)
            inst.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.stafffx.AnimState:SetMultColour(95/255, 0, 1, 1)
        end,
		
		onexit = function(inst)
            inst.components.playercontroller:Enable(true)
			inst.components.health:SetInvincible(false)
			if inst.stafffx then
                inst.stafffx:Remove()
            end
        end,

        timeline = 
        {
            TimeEvent(17*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("soundpack/spell/bigspell") -- Add Custom Sound
            end),
			TimeEvent(0*FRAMES, function(inst)
                inst.stafflight = SpawnPrefab("staff_castinglight")
                local pos = inst:GetPosition()
                local colour = {95/255,0,1}
                inst.stafflight.Transform:SetPosition(pos.x, pos.y, pos.z)
                inst.stafflight.setupfn(inst.stafflight, colour, 1.9, .33)                

            end),
			TimeEvent(53*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("soundpack/spell/border")
				inst:PerformBufferedAction() 
			end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },
    }
	
	Stategraph.states["lament"] = state

end)

if Language == "chinese" then
UTELEPORT.str = "传 送"
SPAWNG.str = "生 成"
CASTTOHO.str = "施 法"
CASTTOHOL.str = "施 法"
CASTTOHOH.str = "施 法"
LAMENT.str = "等 待"
end