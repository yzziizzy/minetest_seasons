
seasons = {}


function deepclone(t)
	if type(t) ~= "table" then 
		return t 
	end
	
	local meta = getmetatable(t)
	local target = {}
	
	for k, v in pairs(t) do
		if type(v) == "table" then
			target[k] = deepclone(v)
		else
			target[k] = v
		end
	end
	
	setmetatable(target, meta)
	
	return target
end



local SEASONS_YEARLEN = 60 * 60 * 2



local between = function(v, a, b)
	if v >= a and v < b then
		return true
	end
	return false
end

local abm_list = {}
local core_lookup = {}
local changes_lookup = {
	spring = {},
	summer = {},
	fall = {},
	winter = {},
}

local function splitname(name)
	local c = string.find(name, ":", 1)
	return string.sub(name, 1, c - 1), string.sub(name, c + 1, string.len(name))
end



function reg_changes(ssn, oldmod, oldname)
	local old = oldmod..":"..oldname
	local new = "seasons:"..ssn.."_"..oldmod.."_"..oldname

	core_lookup[old] = old
	if ssn == "summer" then -- minetest is in "summer" by default
		changes_lookup[ssn][old] = old
		table.insert(abm_list, old)
	else
		core_lookup[new] = old
		changes_lookup[ssn][old] = new
		table.insert(abm_list, new)
	end
	
	
end

function reg_custom(ssn, old, new)
	core_lookup[old] = old
	if ssn == "summer" then -- minetest is in "summer" by default
		changes_lookup[ssn][old] = old
		table.insert(abm_list, old)
	else
		print(dump(core_lookup))
		core_lookup[new] = old
		changes_lookup[ssn][old] = new
		table.insert(abm_list, new)
	end
end
seasons.reg_custom = reg_custom



function reg_generic(oldmod, oldname, tiles, drops, default_season)
	local old = oldmod..":"..oldname
	local ds = default_season or "summer"
	
	local function reg(ssn)
		local new
		if ssn == ds then -- minetest is in "summer" by default
			new = old
		else
			new = "seasons:"..ssn.."_"..oldmod.."_"..oldname
		end
		
		
		if ssn ~= ds then
			local def = deepclone(minetest.registered_nodes[old])
			def.groups.not_in_creative_inventory = 1
			
			if tiles and tiles[ssn] then
				def.tiles = tiles[ssn]
			else
				def.tiles = {"seasons_"..ssn.."_"..oldmod.."_"..oldname..".png"}
			end
			
			if drops and drops[ssn] then 
				def.drops = drops[ssn]
			end
			
			minetest.register_node(new, def)
		end
		
-- 		print("new: "..new.." old: "..old)
		core_lookup[new] = old
		changes_lookup[ssn][old] = new
		table.insert(abm_list, new)
	end
	
	
	reg("spring")
	reg("summer")
	reg("fall")
	reg("winter")
	
end


reg_generic("default", "dirt_with_grass", {
		spring = {"seasons_spring_default_grass.png", "default_dirt.png", {name = "default_dirt.png^seasons_spring_default_grass_side.png", tileable_vertical = false}},
		fall = {"seasons_fall_default_grass.png", "default_dirt.png", {name = "default_dirt.png^seasons_fall_default_grass_side.png", tileable_vertical = false}},
		winter = {"seasons_winter_default_grass.png", "default_dirt.png", {name = "default_dirt.png^seasons_winter_default_grass_side.png", tileable_vertical = false}},
	},
	nil)
	
for i = 1, 5 do
	reg_generic("default", "grass_"..i, nil, nil)
end

reg_generic("default", "bush_leaves", {
		spring = {"seasons_spring_default_leaves_simple.png"},
		fall = {"seasons_fall_default_leaves_simple.png"},
		winter = {"seasons_winter_default_leaves_simple.png"},
	}, 
	nil)
	
reg_generic("default", "jungleleaves", nil, nil)
default.register_leafdecay({
	trunks = {"default:jungletree"},
	leaves = {
		"seasons:winter_default_jungleleaves",
		"seasons:fall_default_jungleleaves",
		"seasons:spring_default_jungleleaves",
	},
	radius = 2,
})

reg_generic("default", "acacia_leaves", nil, nil)
default.register_leafdecay({
	trunks = {"default:acacia_tree"},
	leaves = {
		"seasons:winter_default_acacia_leaves",
		"seasons:fall_default_acacia_leaves",
		"seasons:spring_default_acacia_leaves",
	},
	radius = 2,
})


--[[
saplings
dirt_with_footsteps ?
jungle trees
acacia trees
apple
bushes
flowers
ferns
cattails

pine leaves turning red in summer/fall
falling leaf particles
]]

--reg_generic("default", "dirt_with_grass", {}, nil)



function reg_leaves(ssn)
	reg_changes(ssn, "default", "leaves")
	
	minetest.register_node("seasons:"..ssn.."_default_leaves", {
		description = "Apple Tree Leaves",
		drawtype = "allfaces_optional",
		waving = 1,
		tiles = {"seasons_"..ssn.."_leaves.png"},
		special_tiles = {"default_leaves_simple.png"},
		paramtype = "light",
		stack_max = 30,
		is_ground_content = false,
		groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
		drop = {
			max_items = 1,
			items = {
				{
					-- player will get sapling with 1/20 chance
					items = {'default:sapling'},
					rarity = 20,
				},
				{
					-- player will get leaves only if he get no saplings,
					-- this is because max_items is 1
					items = {'seasons:'..ssn..'_default_leaves'},
				}
			}
		},
		sounds = default.node_sound_leaves_defaults(),

		after_place_node = default.after_place_leaves,
	})
	
	default.register_leafdecay({
		trunks = {"default:tree"},
		leaves = {"seasons:"..ssn.."_default_leaves"},
		radius = 2,
	})
end
reg_leaves("spring")
reg_leaves("fall")
reg_leaves("winter")
reg_changes("summer", "default", "leaves")


function reg_aspen_leaves(ssn)
	reg_changes(ssn, "default", "aspen_leaves")
	
	minetest.register_node("seasons:"..ssn.."_default_aspen_leaves", {
		description = "Aspen Tree Leaves",
		drawtype = "allfaces_optional",
		tiles = {"seasons_"..ssn.."_aspen_leaves.png"},
		waving = 1,
		paramtype = "light",
		stack_max = 30,
		is_ground_content = false,
		groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
		drop = {
			max_items = 1,
			items = {
				{items = {"default:aspen_sapling"}, rarity = 20},
				{items = {"seasons:"..ssn.."_default_aspen_leaves"}}
			}
		},
		sounds = default.node_sound_leaves_defaults(),

		after_place_node = default.after_place_leaves,
	})
	
	default.register_leafdecay({
		trunks = {"default:aspen_tree"},
		leaves = {"seasons:"..ssn.."_default_aspen_leaves"},
		radius = 3,
	})
end

reg_aspen_leaves("spring")
reg_aspen_leaves("fall")
reg_aspen_leaves("winter")
reg_changes("summer", "default", "aspen_leaves")





-- flowers bloom in spring, not summer

reg_generic("flowers", "rose", nil, 
	{ -- drops
		spring = {"flowers:rose"},
		summer = {}, -- nothin
		fall = {}, -- TODO: rosehip
		winter = {}, -- TODO: rose bud
	}, 
	"spring")


reg_generic("flowers", "tulip", 
	{
		summer = {"seasons_summer_flowers_tulip.png"},
		fall = {"seasons_fall_flowers_tulip.png"},
		winter = {"seasons_winter_flowers_tulip.png"}
	}, 
	{ -- drops
		--spring = {"flowers:tulip"},
		summer = {}, -- nothin
		fall = {}, -- nothin
		winter = {}, -- TODO: bulb
	}, 
	"spring")
	
--[[
reg_generic("flowers", "tulip_black", 
	{
		summer = {"seasons_summer_flowers_tulip.png"},
		fall = {"seasons_fall_flowers_tulip.png"},
		winter = {"seasons_winter_flowers_tulip.png"}
	}, 
	{ -- drops
		--spring = {"flowers:tulip_black"},
		summer = {}, -- nothin
		fall = {}, -- nothin
		winter = {}, -- TODO: bulb
	}, 
	"spring")
]]

local def
-- dandelions are done manually because the default ones represent two seasons
-- fall
def = deepclone(minetest.registered_nodes["flowers:dandelion_yellow"])
def.groups.not_in_creative_inventory = 1
def.tiles = {"seasons_fall_flowers_dandelion.png"}
def.drops = {}
minetest.register_node("seasons:fall_flowers_dandelion", def)
-- winter
def = deepclone(minetest.registered_nodes["flowers:dandelion_yellow"])
def.groups.not_in_creative_inventory = 1
def.tiles = {"seasons_winter_flowers_dandelion.png"}
def.drops = {}
minetest.register_node("seasons:winter_flowers_dandelion", def)
-- lookups
core_lookup["seasons:winter_flowers_dandelion"] = "flowers:dandelion_yellow"
core_lookup["seasons:fall_flowers_dandelion"] = "flowers:dandelion_yellow"
core_lookup["flowers:dandelion_yellow"] = "flowers:dandelion_yellow"
core_lookup["flowers:dandelion_white"] = "flowers:dandelion_yellow" -- this is correct
changes_lookup["fall"]["flowers:dandelion_yellow"] = "seasons:fall_flowers_dandelion"
changes_lookup["winter"]["flowers:dandelion_yellow"] = "seasons:winter_flowers_dandelion"
changes_lookup["spring"]["flowers:dandelion_yellow"] = "flowers:dandelion_yellow"
changes_lookup["summer"]["flowers:dandelion_yellow"] = "flowers:dandelion_white"
table.insert(abm_list, "seasons:fall_flowers_dandelion")
table.insert(abm_list, "seasons:winter_flowers_dandelion")
table.insert(abm_list, "flowers:dandelion_yellow")
table.insert(abm_list, "flowers:dandelion_white")





local get_season_data = function() 
	local t = minetest.get_gametime()
	
	local s = ((t *  math.pi * 2) / (SEASONS_YEARLEN)) % (math.pi * 2)
	local snorm = (math.sin(s) + 1) * 0.5 
	local cnorm = (math.cos(s) + 1) * 0.5 
	
	local sign = 1
	if cnorm < .5 then
		sign = -1
	end
	
	local season
	if between(s, 0, .2) then 
		season = "winter"
	elseif between(s, .8, 1.0) then
		season = "summer"
	else
		if sign > 0 then
			season = "spring"
		else
			season = "fall"
		end
	end
	
	return season, snorm, sign
end


local get_season = function() 
	local season, time
	local t = minetest.get_gametime()
	
	local s = (t % SEASONS_YEARLEN) / SEASONS_YEARLEN
	
	if between(s, 0, .2) then 
		season = "spring"
		time = (s - .0) / .2
	elseif between(s, .2, .5) then
		season = "summer"
		time = (s - .2) / .3
	elseif between(s, .5, .7) then
		season = "fall"
		time = (s - .5) / .2
	elseif between(s, .7, 1.0) then
		season = "winter"
		time = (s - .7) / .3
	end

	return season, time, s
end


seasons.get_season = get_season


minetest.register_abm({
	label = "Leaf Change",
	nodenames = abm_list,
	interval = 1,
	chance = 5,
	catch_up = true,
	action = function(pos, node)
		local s, progress = get_season()

		--local name = changes[s][node.name]
		local core = core_lookup[node.name]
		local name = changes_lookup[s][core]

		if name == nil or name == node.name then return end
		
		minetest.set_node(pos, {name = name})
		
	end,
})







-- water freezing

def = deepclone(minetest.registered_nodes["default:ice"])
def.groups.not_in_creative_inventory = 1
def.drops = {"default:ice"}
minetest.register_node("seasons:ice_water_source", def)

def = deepclone(minetest.registered_nodes["default:ice"])
def.groups.not_in_creative_inventory = 1
def.drops = {}
minetest.register_node("seasons:ice_water_flowing", def)

def = deepclone(minetest.registered_nodes["default:ice"])
def.groups.not_in_creative_inventory = 1
def.drops = {"default:ice"} -- TODO: riverwater ice
minetest.register_node("seasons:ice_river_water_source", def)

def = deepclone(minetest.registered_nodes["default:ice"])
def.groups.not_in_creative_inventory = 1
def.drops = {}
minetest.register_node("seasons:ice_river_water_flowing", def)

local ice_lookup = {
	["default:water_source"] = "seasons:ice_water_source",
	["default:water_flowing"] = "seasons:ice_water_flowing",
	["default:river_water_source"] = "seasons:ice_river_water_source",
	["default:river_water_flowing"] = "seasons:ice_river_water_flowing",
}
local water_lookup = {
	["seasons:ice_water_source"] = "default:water_source",
	["seasons:ice_water_flowing"] = "default:water_flowing",
	["seasons:ice_river_water_source"] = "default:river_water_source",
	["seasons:ice_river_water_flowing"] = "default:river_water_flowing",
}


minetest.register_abm({
	label = "Water Freeze",
	nodenames = {
		"default:water_source",
		"default:water_flowing",
		"default:river_water_source",
		"default:river_water_flowing",
	},
	neighbors = "air",
	interval = 1,
	chance = 5,
	catch_up = true,
	action = function(pos, node)
		local s, progress = get_season()

		local name
		if s ~= "winter" then
			return
		end
		
		minetest.set_node(pos, {name = ice_lookup[node.name]})
		
	end,
})
minetest.register_abm({
	label = "Water Thaw",
	nodenames = {
		"seasons:ice_water_source",
		"seasons:ice_water_flowing",
		"seasons:ice_river_water_source",
		"seasons:ice_river_water_flowing",
	},
	interval = 1,
	chance = 5,
	catch_up = true,
	action = function(pos, node)
		local s, progress = get_season()

		local name
		if s == "winter" then
			return
		end
		
		minetest.set_node(pos, {name = water_lookup[node.name]})
		
	end,
})



local last_season = {
	spring = "winter",
	summer = "spring",
	fall = "summer",
	winter = "fall",
}

minetest.register_lbm({
	name = "seasons:catchup",
	nodenames = abm_list,
	run_at_every_load = true,
	action = function(pos, node)
		local s, progress = get_season()
		
		if math.random() > (progress * 1.2) then
			-- use last season's node
			s = last_season[s]
		end

		--local name = changes[s][node.name]
		local core = core_lookup[node.name]
		local name = changes_lookup[s][core]

		if name == nil or name == node.name then return end
		
		minetest.set_node(pos, {name = name})
	end,
})




if minetest.global_exists("storms") then
	
	storms.register_heat_bias(function(pos, orig) 
		local season, stime, spin = get_season()
		
		spin = math.sin(spin * 2 * math.pi) * 20
		
-- 		print("heat bias: ".. spin)
		return spin
	end)
	
	
	--[[
	storms.register_freq_bias(function(pos, orig) 
		local season, stime, spin = get_season()
		
		spin = math.sin(spin * 2 * math.pi)
		
		print("freq bias: ".. spin)
		return spin
	end)
	]]
	
end

