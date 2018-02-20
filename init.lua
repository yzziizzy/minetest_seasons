
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



local SEASONS_YEARLEN = 60 * 2



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



function reg_changes(ssn, oldmod, oldname)
	local old = oldmod..":"..oldname
	local new = "seasons:"..ssn.."_"..oldname

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

function reg_generic(oldmod, oldname, tiles, drops)
	local old = oldmod..":"..oldname
	
	function reg(ssn)
		local new
		if ssn == "summer" then -- minetest is in "summer" by default
			new = old
		else
			new = "seasons:"..ssn.."_"..oldmod.."_"..oldname
		end
		
		
		if ssn ~= "summer" then
			local def = deepclone(minetest.registered_nodes[old])
			
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
	
	minetest.register_node("seasons:"..ssn.."_leaves", {
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
					items = {'seasons:'..ssn..'_leaves'},
				}
			}
		},
		sounds = default.node_sound_leaves_defaults(),

		after_place_node = default.after_place_leaves,
	})
end
reg_leaves("spring")
reg_leaves("fall")
reg_leaves("winter")
reg_changes("summer", "default", "leaves")


function reg_aspen_leaves(ssn)
	reg_changes(ssn, "default", "aspen_leaves")
	
	minetest.register_node("seasons:"..ssn.."_aspen_leaves", {
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
				{items = {"seasons:"..ssn.."_aspen_leaves"}}
			}
		},
		sounds = default.node_sound_leaves_defaults(),

		after_place_node = default.after_place_leaves,
	})
end

reg_aspen_leaves("spring")
reg_aspen_leaves("fall")
reg_aspen_leaves("winter")
reg_changes("summer", "default", "aspen_leaves")




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

	return season, time
end




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

		if name == nil then return end
		
		minetest.set_node(pos, {name = name})
		
	end,
})



