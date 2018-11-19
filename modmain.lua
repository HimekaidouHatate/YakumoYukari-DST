PrefabFiles = {
	"tunnel",
	"yakumoyukari",
	"yakumoyukari_none",
	"yukariumbre",
	"yukarihat",
	"upgradepanel",
	"ultpanel",
	"ultpanelsw",
	"spellcards",
	"barrierfieldfx",
	"effect_fx",
	"scheme",
	"taggable_classified",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/yakumoyukari.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/yakumoyukari.xml" ),
    Asset( "IMAGE", "images/selectscreen_portraits/yakumoyukari.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/yakumoyukari.xml" ),
    Asset( "IMAGE", "images/selectscreen_portraits/yakumoyukari_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/yakumoyukari_silho.xml" ),
    Asset( "IMAGE", "bigportraits/yakumoyukari.tex" ),
    Asset( "ATLAS", "bigportraits/yakumoyukari.xml" ),
	
	Asset( "IMAGE", "images/map_icons/yakumoyukari.tex" ),
	Asset( "ATLAS", "images/map_icons/yakumoyukari.xml"  ),
	Asset( "IMAGE", "images/map_icons/minimap_tunnel.tex"),
	Asset( "ATLAS", "images/map_icons/minimap_tunnel.xml"),
	Asset( "IMAGE", "images/map_icons/yukarihat.tex"  ),
	Asset( "ATLAS", "images/map_icons/yukarihat.xml" ),
	Asset( "IMAGE", "images/map_icons/yukariumbre.tex" ),
	Asset( "ATLAS", "images/map_icons/yukariumbre.xml" ),
	Asset( "IMAGE", "images/map_icons/scheme.tex" ),
	Asset( "ATLAS", "images/map_icons/scheme.xml" ),
	
	Asset( "IMAGE", "images/inventoryimages/touhoutab.tex" ),
	Asset( "ATLAS", "images/inventoryimages/touhoutab.xml" ),
	Asset( "ANIM" , "anim/power.zip"),
	
	Asset("SOUNDPACKAGE", "sound/soundpack.fev"),
	Asset("SOUND", "sound/spell.fsb"),

	Asset( "ANIM" , "anim/ui_board_5x1.zip"),
}

----- GLOBAL & require list -----
local require = GLOBAL.require
local assert = GLOBAL.assert
require "class"
GLOBAL.TUNNELNETWORK = {}
GLOBAL.TUNNELFIRSTINDEX = nil
GLOBAL.TUNNELLASTINDEX = nil
GLOBAL.NUMTUNNEL = 0

local STRINGS = GLOBAL.STRINGS
local ProfileStatsSet = GLOBAL.ProfileStatsSet
local SpawnPrefab = GLOBAL.SpawnPrefab
local ThePlayer = GLOBAL.ThePlayer
local GetString = GLOBAL.GetString
local TheInput = GLOBAL.TheInput
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local FindEntity = GLOBAL.FindEntity
local SpringCombatMod = GLOBAL.SpringCombatMod
local IsYukari = ThePlayer and ThePlayer.prefab == "yakumoyukari"
local Inspect = GetModConfigData("inspect")
local Language = GetModConfigData("language")

----- Basic settings for Yukari -----
STRINGS.CHARACTER_TITLES.yakumoyukari = "Youkai of Boundaries"
STRINGS.CHARACTER_NAMES.yakumoyukari = "Yakumo Yukari"
STRINGS.CHARACTER_DESCRIPTIONS.yakumoyukari = "has own ability 'youkai power'.\nbecomes dreadful when she get 'power' from her world."
STRINGS.CHARACTER_QUOTES.yakumoyukari = "\"I have taken the first napkin.\""
STRINGS.CHARACTERS.YAKUMOYUKARI = require "speech_yakumoyukari"
if Language == "chinese" then
	STRINGS.CHARACTER_TITLES.yakumoyukari = "境界的妖怪"
	STRINGS.CHARACTER_DESCRIPTIONS.yakumoyukari = "拥 有 自 己 的 能 力 '妖 力'.\n 当 她 从 自 己 的 世 界 中 获 得 ' 力 量 ' 之 后 将 变 得 极 其 可 怕."
	STRINGS.CHARACTER_QUOTES.yakumoyukari = "\"我 将 会 掌 控 这 个 世 界！.\""
	STRINGS.CHARACTERS.YAKUMOYUKARI = require "speech_yakumoyukari_ch"
end
AddModCharacter("yakumoyukari", "FEMALE")
AddMinimapAtlas("images/map_icons/yakumoyukari.xml")
AddMinimapAtlas("images/map_icons/yukarihat.xml")
AddMinimapAtlas("images/map_icons/yukariumbre.xml")
AddMinimapAtlas("images/map_icons/minimap_tunnel.xml")
AddMinimapAtlas("images/map_icons/scheme.xml")

------ Function ------
AddReplicableComponent("taggable")

SetTaggableText = function(player, target, text)
    local taggable = target.components.taggable
    if taggable ~= nil then
        taggable:Write(player, text)
    end
end
AddModRPCHandler("scheme", "write", SetTaggableText)

---------------- OVERRIDE -----------------

local function OnTakeDamage(self)
	local function NewTakeDamage(self, damage, attacker, weapon, ...)
		-- GRAZE MECHANISM
		local Chara = self.inst
		if self.inst.prefab == "yakumoyukari" then
			local totaldodge = Chara.components.upgrader and (Chara.components.upgrader.dodgechance + Chara.components.upgrader.hatdodgechance)
			if math.random() < totaldodge then
				local pt = GLOBAL.Vector3(Chara.Transform:GetWorldPosition())
				for i = 1, math.random(3,5), 1 do
					local fx = SpawnPrefab("graze_fx")
					fx.Transform:SetPosition(pt.x + math.random() / 2, pt.y + 0.7 + math.random() / 2 , pt.z + math.random() / 2 )
				end
				Chara:PushEvent("grazed")
				
				return 0
			end
		end

		local absorbers = {}

		for k, v in pairs(self.equipslots) do
			if v.components.resistance ~= nil and
				v.components.resistance:HasResistance(attacker, weapon) and
				v.components.resistance:ShouldResistDamage() then
				v.components.resistance:ResistDamage(damage)
				return 0
			elseif v.components.armor ~= nil then
				absorbers[v.components.armor] = v.components.armor:GetAbsorption(attacker, weapon)
			end
		end

		local absorbed_percent = 0
		local total_absorption = 0
		for armor, amt in pairs(absorbers) do
			-- print("\t", armor.inst, "absorbs", amt)
			absorbed_percent = math.max(amt, absorbed_percent)
			total_absorption = total_absorption + amt
		end

		local absorbed_damage = damage * absorbed_percent
		local leftover_damage = damage - absorbed_damage

		-- print("\tabsorbed%", absorbed_percent, "total_absorption", total_absorption, "absorbed_damage", absorbed_damage, "leftover_damage", leftover_damage)

		if total_absorption > 0 then
			GLOBAL.ProfileStatsAdd("armor_absorb", absorbed_damage)

			for armor, amt in pairs(absorbers) do -- it doesn't increases armor durability efficiency.
				armor:TakeDamage(absorbed_damage * amt / total_absorption + armor:GetBonusDamage(attacker, weapon))
			end
		end

		-- custom damage reduction
		if self.inst.prefab == "yakumoyukari" then
			if self.inst.components.upgrader.hatequipped then
				for i = 1, Chara.components.upgrader.hatlevel, 1 do
					leftover_damage = leftover_damage * 0.6 -- 40%, 64%, 78.4%, 87%, 92.2%
				end
			end
			
			if Chara.components.upgrader.IsDamage then
				leftover_damage = leftover_damage * 0.7
			end
			
			if Chara:HasTag("IsDamage") then
				leftover_damage = leftover_damage * 0.5
			end
		end
		
		return leftover_damage
	end
	self.ApplyDamage = NewTakeDamage
end
-- Bunnyman Retarget Function
local function BunnymanNormalRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function is_meat(item)
		return item.components.edible and item.components.edible.foodtype == GLOBAL.FOODTYPE.MEAT
	end
	
	local function NormalRetargetFn(inst)
		return FindEntity(inst, TUNING.PIG_TARGET_DIST,
			function(guy)
				return inst.components.combat:CanTarget(guy)
					and (guy:HasTag("monster") or guy:HasTag("youkai")
					or (guy.components.inventory ~= nil and
						guy:IsNear(inst, TUNING.BUNNYMAN_SEE_MEAT_DIST) and
						guy.components.inventory:FindItem(is_meat) ~= nil))
			end,
			{ "_combat", "_health" }, -- see entityreplica.lua
			{ "realyoukai" }, -- not even be targetted with meat
			{ "monster", "player" })
	end
	inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
end
-- Pigman Retarget Function
local function PigmanNormalRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function NormalRetargetFn(inst)
		return FindEntity(inst, TUNING.PIG_TARGET_DIST,
			function(guy)
				return (guy.LightWatcher == nil or guy.LightWatcher:IsInLight())
					and inst.components.combat:CanTarget(guy) and (guy:HasTag("monster") or guy:HasTag("youkai"))
			end,
			{ "_combat" }, -- see entityreplica.lua
			inst.components.follower.leader ~= nil and
			{ "playerghost", "INLIMBO", "abigail" } or
			{ "playerghost", "INLIMBO", "realyoukai" })
	end
	inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
end
-- Bat Retarget Function
local function BatRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function MakeTeam(inst, attacker, ...) 
		local leader = SpawnPrefab("teamleader")
		leader.components.teamleader:SetUp(attacker, inst)
		leader.components.teamleader:BroadcastDistress(inst)
	end
	
	local function Retarget(inst)
		local ta = inst.components.teamattacker
		local newtarget = FindEntity(inst, TUNING.BAT_TARGET_DIST, function(guy)
				return inst.components.combat:CanTarget(guy)
			end,
			nil,
			{"bat", "realyoukai"},
			{"character", "monster"}
		)

		if newtarget and not ta.inteam and not ta:SearchForTeam() then
			MakeTeam(inst, newtarget)
		end

		if ta.inteam and not ta.teamleader:CanAttack() then
			return newtarget
		end
	end
	
	inst.components.combat:SetRetargetFunction(3, Retarget)
end
-- Bee Retarget Function
local function KillerbeeRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function KillerRetarget(inst)
		return FindEntity(inst, SpringCombatMod(8),
			function(guy)
				return inst.components.combat:CanTarget(guy)
			end,
			{ "_combat", "_health" },
			{ "insect", "INLIMBO", "realyoukai" },
			{ "character", "animal", "monster" })
	end
	inst.components.combat:SetRetargetFunction(2, KillerRetarget)
end
local function BeeRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function SpringBeeRetarget(inst)
		return GLOBAL.TheWorld.state.isspring and
		FindEntity(inst, 4,
			function(guy)
				return inst.components.combat:CanTarget(guy)
			end,
			{ "_combat", "_health" },
			{ "insect", "INLIMBO", "realyoukai" },
			{ "character", "animal", "monster" })
		or nil
	end
	inst.components.combat:SetRetargetFunction(2, SpringBeeRetarget)
end
-- frog Retarget Function
local function FrogRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function retargetfn(inst)
		if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() then
		return FindEntity(inst, TUNING.FROG_TARGET_DIST, function(guy) 
			if not guy.components.health:IsDead() then
				return guy.components.inventory ~= nil
			end
		end,
		{"_combat","_health"},
		{"realyoukai"}
		)
	end
	end
	if inst.components.combat ~= nil then
		inst.components.combat:SetRetargetFunction(3, retargetfn)
	end
end
-- spiders retargetfn
local function FindTarget(inst, radius)
    return FindEntity(
        inst,
        SpringCombatMod(radius),
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and not (inst.components.follower ~= nil and inst.components.follower.leader == guy)
        end,
        { "_combat", "character" },
        { "monster", "INLIMBO", "realyoukai" }
    )
end

local function SpiderRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function NormalRetarget(inst)
		return FindTarget(inst, inst.components.knownlocations:GetLocation("investigate") ~= nil and TUNING.SPIDER_INVESTIGATETARGET_DIST or TUNING.SPIDER_TARGET_DIST)
	end
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
end

local function WarriorRetargetFn(inst)
	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	local function WarriorRetarget(inst)
		return FindTarget(inst, TUNING.SPIDER_WARRIOR_TARGET_DIST)
	end
	inst.components.combat:SetRetargetFunction(2, WarriorRetarget)
end


local function SetInspectable(inst)
	if Inspect and IsMaster then
		inst:AddComponent("inspectable") 
		if inst:HasTag("NOCLICK") then
			inst:RemoveTag("NOCLICK")
		end
	end
end

local function ToolEfficientFn(self)
	if IsMaster then
		local function ToolEfficient(self, action, effectiveness, ...)
			assert(GLOBAL.TOOLACTIONS[action.id], "invalid tool action")
			if ThePlayer and IsYukari then
				if ThePlayer.components.upgrader and ThePlayer.components.upgrader.IsEfficient then
					if action ~= GLOBAL.ACTIONS.HAMMER then -- Hammering efficiency should not be inceased.
						effectiveness = effectiveness + 0.5
					end
				end
			end
			self.actions[action] = effectiveness or 1
			self.inst:AddTag(action.id.."_tool")
		end
	
		self.SetAction = ToolEfficient
	end
end

--local writeable = require"prefab/writeable_classified"


---------- print current upgrade & ability
function SayInfo(inst)
	local TheInput = TheInput
	local index = inst.info % 3
	local HP = 0
	local HN = 0
	local SA = 0
	local PO = 0
	local str = ""
	
	if index == 0 then
		HP = inst.components.upgrader.health_level
		HN = inst.components.upgrader.hunger_level
		SA = inst.components.upgrader.sanity_level
		PO = inst.components.upgrader.power_level

		str = STRINGS.NAMES.HEALTHPANEL.." - "..HP.."\n"..STRINGS.NAMES.HUNGERPANEL.." - "..HN.."\n"..STRINGS.NAMES.SANITYPANEL.." - "..SA.."\n"..STRINGS.NAMES.POWERPANEL.." - "..PO
	elseif index == 1 then
		for i = 1, inst.components.upgrader.skillsort, 1 do
			for j = 1, inst.components.upgrader.skilllevel, 1 do
				if inst.components.upgrader.ability[i][j] then
					if i == 1 then
						HP = HP + 1
					elseif i == 2 then
						HN = HN + 1
					elseif i == 3 then
						SA = SA + 1
					elseif i == 4 then
						PO = PO + 1
					end
				end
			end
		end

		str = STRINGS.HEALTH.." "..STRINGS.ABILITY.." - lev."..HP.."\n"..STRINGS.HUNGER.." "..STRINGS.ABILITY.." - lev."..HN.."\n"..STRINGS.SANITY.." "..STRINGS.ABILITY.." - lev."..SA.."\n"..STRINGS.POWER.." "..STRINGS.ABILITY.." - lev."..PO
	else -- TODO : RECODE(with table)
		if inst.components.upgrader.InvincibleLearned then
			if inst.IsInvincible then
				invincibility = STRINGS.INVINCIBILITY.." - "..STRINGS.ACTIVATED
			elseif inst.invin_cool > 0 then
				invincibility = STRINGS.INVINCIBILITY.." - "..inst.invin_cool..STRINGS.SECONDS
			else
				invincibility = STRINGS.INVINCIBILITY.." - "..STRINGS.READY
			end
		end

		str = invincibility or ""
		if str == "" then
			str = STRINGS.YUKARI_NOSKILL
		end
	end

	inst.components.talker:Say(str)
	inst.info = inst.info + 1
end

AddModRPCHandler("yakumoyukari", "SayInfo", SayInfo)

-------------------------------
modimport "scripts/power_init.lua"
modimport "scripts/tunings_yukari.lua"
modimport "scripts/strings_yukari.lua"
modimport "scripts/actions_yukari.lua"
modimport "scripts/recipes_yukari.lua"
AddPrefabPostInit("bunnyman", BunnymanNormalRetargetFn)
AddPrefabPostInit("pigman", PigmanNormalRetargetFn)
AddPrefabPostInit("bat", BatRetargetFn)
AddPrefabPostInit("bee", BeeRetargetFn)
AddPrefabPostInit("killerbee", KillerbeeRetargetFn)
AddPrefabPostInit("frog", FrogRetargetFn)
AddPrefabPostInit("spider", SpiderRetargetFn)
AddPrefabPostInit("spider_warrior", WarriorRetargetFn)
AddPrefabPostInit("shadowwatcher", SetInspectable)
AddPrefabPostInit("shadowskittish", SetInspectable)
AddPrefabPostInit("shadowskittish_water", SetInspectable)
AddPrefabPostInit("creepyeyes", SetInspectable)
AddPrefabPostInit("crawlinghorror", SetInspectable)
AddPrefabPostInit("terrorbeak", SetInspectable)
AddPrefabPostInit("swimminghorror", SetInspectable)
AddPrefabPostInit("crawlingnightmare", SetInspectable)
AddPrefabPostInit("nightmarebeak", SetInspectable)
AddComponentPostInit("inventory", OnTakeDamage)
AddComponentPostInit("tool", ToolEfficientFn)