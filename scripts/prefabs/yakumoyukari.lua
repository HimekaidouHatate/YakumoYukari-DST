local MakePlayerCharacter = require "prefabs/player_common"

local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
        Asset( "ANIM", "anim/player_idles_shiver.zip" ),
        Asset( "ANIM", "anim/player_actions.zip" ),
        Asset( "ANIM", "anim/player_actions_axe.zip" ),
        Asset( "ANIM", "anim/player_actions_pickaxe.zip" ),
        Asset( "ANIM", "anim/player_actions_shovel.zip" ),
        Asset( "ANIM", "anim/player_actions_blowdart.zip" ),
        Asset( "ANIM", "anim/player_actions_eat.zip" ),
        Asset( "ANIM", "anim/player_actions_item.zip" ),
        Asset( "ANIM", "anim/player_actions_uniqueitem.zip" ),
        Asset( "ANIM", "anim/player_actions_bugnet.zip" ),
        Asset( "ANIM", "anim/player_actions_fishing.zip" ),
        Asset( "ANIM", "anim/player_actions_boomerang.zip" ),
        Asset( "ANIM", "anim/player_bush_hat.zip" ),
        Asset( "ANIM", "anim/player_attacks.zip" ),
        Asset( "ANIM", "anim/player_idles.zip" ),
        Asset( "ANIM", "anim/player_rebirth.zip" ),
        Asset( "ANIM", "anim/player_jump.zip" ),
        Asset( "ANIM", "anim/player_amulet_resurrect.zip" ),
        Asset( "ANIM", "anim/player_teleport.zip" ),
        Asset( "ANIM", "anim/wilson_fx.zip" ),
        Asset( "ANIM", "anim/player_one_man_band.zip" ),
        Asset( "ANIM", "anim/shadow_hands.zip" ),
        Asset( "ANIM", "anim/beard.zip" ),
		Asset( "SOUND", "sound/sfx.fsb" ),
        Asset( "SOUND", "sound/wilson.fsb" ),

		Asset( "ATLAS", "images/avatars/avatar_yakumoyukari.xml"),
		Asset( "ATLAS", "images/avatars/avatar_ghost_yakumoyukari.xml"),
}

local prefabs = { -- deps; should be a list of prefabs that it wants to have loaded in order to be able to create prefab.
	"scheme",
	"yukariumbre",
	"yukarihat",
}

-- Custom starting items
local function GetStartInv()
	local difficulty = GetModConfigData("difficulty", "YakumoYukari")
	if difficulty == "easy" then
		return {"meat",
				"meat",
				"meat",
				"meat",
				"meat",
				"scheme",
				"yukariumbre",
				"yukarihat",}
	else return {
				"scheme",
				"yukariumbre",
				"yukarihat",
				}
	end
end

local start_inv = GetStartInv()
--{"scheme", "yukariumbre", "yukarihat",}

local function onsave(inst, data)
	data.regen_cool = inst.regen_cool
	data.poison_cool = inst.poison_cool
	data.invin_cool = inst.invin_cool
	data.grazecnt = inst.grazecnt
	data.health_level = inst.components.upgrader.health_level
	data.hunger_level = inst.components.upgrader.hunger_level
	data.sanity_level = inst.components.upgrader.sanity_level
	data.power_level = inst.components.upgrader.power_level
	data.skilltree = inst.components.upgrader.ability
	data.hatskill = inst.components.upgrader.hatskill
	data.hatlevel = inst.components.upgrader.hatlevel
end

local function onpreload(inst, data)
	
	if data then
		if inst.components.power then
			inst.regen_cool = data.regen_cool or 0 
			inst.poison_cool = data.poison_cool or 0 
			inst.invin_cool = data.invin_cool or 0 
			inst.grazecnt = data.grazecnt or 0
			inst.components.upgrader.health_level = data.health_level or 0 
			inst.components.upgrader.hunger_level = data.hunger_level or 0
			inst.components.upgrader.sanity_level = data.sanity_level or 0 
			inst.components.upgrader.power_level = data.power_level or 0	
			inst.components.upgrader.hatlevel = data.hatlevel or 1
			inst.components.upgrader.ability = data.skilltree
			inst.components.upgrader.hatskill = data.hatskill
			inst.components.upgrader:AbilityManager(inst)
			inst.components.upgrader:DoUpgrade(inst)

			--re-set these from the save data, because of load-order clipping issues
			if data.health and data.health.health then inst.components.health.currenthealth = data.health.health end
			if data.hunger and data.hunger.hunger then inst.components.hunger.current = data.hunger.hunger end
			if data.sanity and data.sanity.current then inst.components.sanity.current = data.sanity.current end
			if data.power and data.power.current then inst.components.power.current = data.power.current end
			inst.components.health:DoDelta(0)
			inst.components.hunger:DoDelta(0)
			inst.components.sanity:DoDelta(0)
			inst.components.power:DoDelta(0)
		end
	end
	
end

local function OnhitEvent(inst, data)

	local target = data.target
	local RegenAmount = 0
	
	-- Life Leech
	if inst.components.upgrader.IsVampire then
	
		if inst.components.upgrader.IsAOE then
			RegenAmount = 2
		else
			RegenAmount = 1
		end
		
		if target and target.components.health and not target:HasTag("chester") then -- Hopefully, Packim(SW Chester) also has "chester" tag.
			inst.components.health:DoDelta(RegenAmount, nil, nil, true)
			if math.random() < 0.15 then
				inst.components.health:DoDelta(5, nil, nil, true)
				if inst.components.poisonable and inst.components.upgrader.IsPoisonCure then
					inst.components.poisonable:Cure(inst)
				end
			end
		end
	end
	
	-- AOE Hit
	if inst.components.upgrader.IsAOE then
		if math.random() < 0.4 then -- remember chance of 40% is < 0.4 not <= 0.4
			inst.components.combat:SetAreaDamage(5, 0.6)
		else
			inst.components.combat:SetAreaDamage(0, 0)
		end
	end
	
end

local function OnAttackedEvent(attacked, data)
	if attacked.components.health and attacked.components.upgrader.IsFight then
		if not attacked.components.health.invincible then -- Check another invinciblity.
			attacked.components.health:SetInvincible(true)
			scheduler:ExecuteInTime(1, attacked.components.health:SetInvincible(false))
		end
	end
end

local function TelePortDelay(player)
	player:DoTaskInTime(0.5, function()
		player.istelevalid = true 
	end)
end

local function DoPowerRestore(inst, amount)
	inst.components.power:DoDelta(amount, false)
	--inst.HUD.controls.status.power:PulseGreen() 
	--inst.HUD.controls.status.power:ScaleTo(1.3,1,.7)
end
	
function DoHungerUp(inst, data)
	if inst:HasTag("inspell") then 
		return
	end

	if inst.components.hunger then
		inst.components.combat.damagemultiplier = TUNING.YDEFAULT.DAMAGE_MULTIPLIER + math.max(inst.components.hunger:GetPercent() - (1 - inst.components.upgrader.powerupvalue * 0.2), 0)
	end
end

local function HealthRegen(inst)
	if inst.components.health then
		local amount = inst.components.upgrader.regenamount
		inst.components.health:DoDelta(amount)
	end
end

local function InvincibleRegen(inst)
	if inst.components.health and inst.components.upgrader.emergency then
		local emergency = inst.components.upgrader.emergency
		inst.components.health:DoDelta(emergency, nil, nil, true) -- DoDelta(amount, overtime, cause, ignore_invincible)
	end
end

function GoInvincible(inst)
	if  inst.components.health 
	and inst.components.health.currenthealth <= 50 
	and inst.components.upgrader.InvincibleLearned
	and inst.components.upgrader.CanbeInvincible then
		inst.components.health:SetInvincible(true)
		inst.invin_cool = 1450
		inst.components.upgrader.CanbeInvincible = false
		inst.components.talker:Say(GetString(inst.prefab, "DESCRIBE_INVINCIBILITY_ACTIVE"))
		inst.components.upgrader.emergency = 4
		inst.IsInvincible = true
		scheduler:ExecuteInTime(10, function() -- Execute after 10 seconds.
			inst.components.upgrader.emergency = 0
			inst.IsInvincible = false
			inst.components.health:SetInvincible(false)
			inst.components.talker:Say(GetString(inst.prefab, "DESCRIBE_INVINCIBILITY_DONE"))
		end)
	end
end

local function PeriodicFunction(inst, data)
	
	local function GetPoint(pt)
		local theta = math.random() * 2 * PI
		local radius = 6 + math.random() * 6
	
		local result_offset = FindValidPositionByFan(theta, radius, 12, function(offset)
			local ground = TheWorld
			local spawn_point = pt + offset
			if not (ground.Map and ground.Map:GetTileAtPoint(spawn_point.x, spawn_point.y, spawn_point.z) == GROUND.IMPASSABLE) then
				return true
			end
			return false
		end)
	
		if result_offset then
			return pt+result_offset
		end
	end

	local Light = inst.entity:AddLight()
	
	if inst.components.upgrader.ResistDark then
		if inst.components.upgrader.ResistCave then
			inst.components.sanity.night_drain_mult = 0
		elseif not TheWorld:HasTag("cave") then
			inst.components.sanity.night_drain_mult = 0
		end
	else
		if inst.hatequipped then
			inst.components.sanity.night_drain_mult = 0.5
		end
		inst.components.sanity.night_drain_mult = 1
	end
	
	if inst.components.upgrader.NightVision then
		if TheWorld.state.phase == "night" or TheWorld:HasTag("cave") then
			if inst.components.sanity and inst.components.sanity:GetPercent() >= 0.8 and inst.components.sanity:GetPercent() < 0.98 then
				inst.Light:SetRadius(1);inst.Light:SetFalloff(.9);inst.Light:SetIntensity(0.3);inst.Light:SetColour(128/255,0,217/255);inst.Light:Enable(true)
			elseif inst.components.sanity and inst.components.sanity:GetPercent() >= 0.98 then
				inst.Light:SetRadius(3);inst.Light:SetFalloff(.5);inst.Light:SetIntensity(0.3);inst.Light:SetColour(128/255,0,217/255);inst.Light:Enable(true)
			else
				Light:SetRadius(0);Light:SetFalloff(0);Light:SetIntensity(0);Light:SetColour(0,0,0);Light:Enable(false)
			end
		else
			Light:SetRadius(0);Light:SetFalloff(0);Light:SetIntensity(0);Light:SetColour(0,0,0);Light:Enable(false)
		end
	end
	
	if inst.components.health and inst.IsInvincible then
		InvincibleRegen(inst)
	end
	
	if inst.components.upgrader.SightDistance > 0 then
		local dis = inst.components.upgrader.SightDistance
		local pt = GetPoint(Vector3(inst.Transform:GetWorldPosition()))
		TheWorld.minimap.MiniMap:ShowArea(pt.x, pt.y, pt.z, 50 * dis)
		TheWorld.Map:VisitTile(TheWorld.Map:GetTileCoordsAtPoint(pt.x, pt.y, pt.z))
	end
end

local function CooldownFunction(inst)
	
	if inst.components.upgrader.ability[1][2] then
		if inst.regen_cool > 0 then
			inst.regen_cool = inst.regen_cool - 1
		elseif inst.regen_cool == 0 
		and inst.components.health 
		and inst.components.health:IsHurt() 
		and inst.components.hunger:GetPercent() > 0.8 then
			HealthRegen(inst)
			inst.regen_cool = inst.components.upgrader.regencool
		end
	end
	
	if inst.invin_cool > 0 then
		inst.invin_cool = inst.invin_cool - 1
	elseif inst.invin_cool == 0 then
		inst.components.upgrader.CanbeInvincible = true
	end
	
end

local function OnGrazed(inst)
	inst.grazecnt = inst.grazecnt + 1
	inst.components.power:DoDelta(math.random(0, 2), false)
end

local function EquippingEvent(inst)
	
	if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
		inst.hatequipped = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "yukarihat"
	else
		inst.hatequipped = false
	end
		
	if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) then
		inst.fireimmuned = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab == ("armordragonfly" or "armorobsidian")
	else
		inst.fireimmuned = false
	end

	inst.components.upgrader:DoUpgrade(inst)
end

local function DebugFunction(inst)
	inst:DoPeriodicTask(1, function()
		if inst.components.power and inst.infpower then
			inst.components.power.max = 300
			inst.components.power.current = 300
		end
		inst.components.hunger:Pause(true)
	end)
end	

local function common_init(inst) -- things before SetPristine()
	inst.MiniMapEntity:SetIcon( "yakumoyukari.tex" )

	inst.regen_cool = 0
	inst.poison_cool = 0
	inst.invin_cool = 0
	inst.grazecnt = 0

	inst.maxpower = net_ushortint(inst.GUID, "maxpower")
	inst.currentpower = net_ushortint(inst.GUID, "currentpower")

	inst.fireimmuned = false
	inst.hatequipped = false

	inst:AddTag("youkai")
	inst:AddTag("yakumoga")
	inst:AddTag("yakumoyukari")
	
	inst:RemoveTag("notarget")
	inst:RemoveTag("inspell")
	inst:RemoveTag("IsDamage")
	
	STRINGS.NAMES.SHADOWWATCHER = "Watcher"
	STRINGS.NAMES.SHADOWSKITTISH = "Shadow Creature"
	STRINGS.NAMES.SHADOWSKITTISH_WATER = "Shadow Creature"
	STRINGS.NAMES.CREEPYEYES = "Eyes"
	-- TUNING.HAMMER_DAMAGE = 10
end

local master_postinit = function(inst) -- after SetPristine()
	
	inst:AddComponent("upgrader")
	inst:AddComponent("power")
	
	inst.soundsname = "willow"
	inst.starting_inventory = start_inv -- starting_inventory passed as a parameter is now deprecated
	
	inst.components.sanity:SetMax(75)
	inst.components.health:SetMaxHealth(80)
	inst.components.health:SetInvincible(false)
	inst.components.hunger:SetMax(150)
	inst.components.hunger.hungerrate = 1.5 * TUNING.WILSON_HUNGER_RATE
	inst.components.combat.damagemultiplier = TUNING.YDEFAULT.DAMAGE_MULTIPLIER
	inst.components.builder.science_bonus = 1
	
	CUSTOM_RECIPETABS['TOUHOU'] = {str = "TOUHOU", sort= 787, icon = "touhoutab.tex", icon_atlas = "images/inventoryimages/touhoutab.xml"}
	
	inst.components.eater.EatMEAT = inst.components.eater.Eat
	function inst.components.eater:Eat( food )
		if self:CanEat(food) then
		
			if food.prefab == "minotaurhorn"
			or food.prefab == "deerclops_eyeball"
			or food.prefab == "tigereye" then
				DoPowerRestore(inst, 300)
				
			elseif food.prefab == "trunk_winter"
			or food.prefab == "tallbirdegg"
			or food.prefab == "tallbirdegg_cracked" then
				food.components.edible.sanityvalue = 0
				DoPowerRestore(inst, 70)
			
			elseif food.prefab == "baconeggs" 
			or food.prefab == "surfnturf" then
				DoPowerRestore(inst, 60)
			
			elseif food.prefab == "trunk_summer"
			or food.prefab == "tallbirdegg_cooked"
			or food.prefab == "dragoonheart" then
				food.components.edible.sanityvalue = 0
				DoPowerRestore(inst, 50)
				
			elseif food.prefab == "turkeydinner" 
			or food.prefab == "bonestew" then
				DoPowerRestore(inst, 45)
		
			elseif food.prefab == "honeyham" then
				DoPowerRestore(inst, 30)
			
			elseif food.prefab == "meat"
			or food.prefab == "plantmeat" 
			or food.prefab == "bird_egg"
			or food.prefab == "shark_fin"
			or food.prefab == "doydoyegg"
			or food.prefab == "eel"
			or food.prefab == "trunk_cooked"
			or food.prefab == "fish_raw"
			or food.prefab == "fish_med"
			or food.prefab == "hotchili"
			or food.prefab == "perogies"
			or food.prefab == "guacamole"
			or food.prefab == "monstermeat" then
				food.components.edible.sanityvalue = 0
				DoPowerRestore(inst, 20)
				
			elseif food.prefab == "meat_dried"
			or food.prefab == "monstermeat_dried" then
				DoPowerRestore(inst, 20)
				
			elseif food.prefab == "drumstick" 
			or food.prefab == "drumstick_cooked" then
				food.components.edible.sanityvalue = 0
				DoPowerRestore(inst, 16)
				
			elseif food.prefab == "doydoyegg_cooked" 
			or food.prefab == "bird_egg_cooked"
			or food.prefab == "cookedmonstermeat"
			or food.prefab == "bird_egg_cooked"
			or food.prefab == "fish_med_cooked"			
			or food.prefab == "plantmeat_cooked"
			or food.prefab == "unagi"
			or food.prefab == "eel_cooked" then
				DoPowerRestore(inst, 15)
				
			elseif food.prefab == "smallmeat" 
			or food.prefab == "tropical_fish"
			or food.prefab == "batwing" 
			or food.prefab == "froglegs" 
			or food.prefab == "fish_raw_small"
			or food.prefab == "frogglebunwich" then
				food.components.edible.sanityvalue = 0
				DoPowerRestore(inst, 10)
				
			elseif food.prefab == "smallmeat_dried" then
				DoPowerRestore(inst, 10)
				
			elseif food.prefab == "cookedsmallmeat"
			or food.prefab == "froglegs_cooked"
			or food.prefab == "batwing_cooked"
			or food.prefab == "honeynuggets"
			or food.prefab == "kabobs"
			or food.prefab == "frogglebunwich"
			or food.prefab == "fish_raw_small_cooked" then
				DoPowerRestore(inst, 8)
			
			end
			
			if food.prefab == "monstermeat" 
			or food.prefab == "monsterlasagna" then
				food.components.edible.healthvalue = -20	
				DoPowerRestore(inst, 5)
				
			elseif food.prefab == "monstermeat_dried"
			or food.prefab == "cookedmonstermeat" then
				food.components.edible.healthvalue = -3
				DoPowerRestore(inst, 3)
			end
			
		end
		return inst.components.eater:EatMEAT(food)
	end

	inst:DoPeriodicTask(1, CooldownFunction)
	inst:DoPeriodicTask(1, PeriodicFunction)
	
	inst.OnSave = onsave
	inst.OnPreLoad = onpreload
	inst.OnLoad = function(inst)
		inst.valid = true
		inst.components.upgrader:DoUpgrade(inst)
		inst:PushEvent("yukariloaded")
	end
	
	inst:ListenForEvent( "debugmode", DebugFunction, inst)
	inst:ListenForEvent( "hungerdelta", DoHungerUp )
	inst:ListenForEvent( "healthdelta", GoInvincible )
	inst:ListenForEvent( "onhitother", OnhitEvent )
	inst:ListenForEvent( "attacked", OnAttackedEvent, inst )
	inst:ListenForEvent( "teleported", TelePortDelay, inst )
	inst:ListenForEvent( "hatequip", EquippingEvent )
	inst:ListenForEvent( "hatunequip", EquippingEvent )
	inst:ListenForEvent( "grazed", OnGrazed )

	if TheNet:GetServerGameMode() == "lavaarena" then
        event_server_data("lavaarena", "prefabs/yakumoyukari").master_postinit(inst)
    elseif TheNet:GetServerGameMode() == "quagmire" then
        event_server_data("quagmire", "prefabs/yakumoyukari").master_postinit(inst)
    end
end

return MakePlayerCharacter("yakumoyukari", prefabs, assets, common_init, master_postinit)