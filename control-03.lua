local smog={}

function get_umax(tabl)
	local max
--	game.print('max serp '.. serpent.line(tabl))
	for i, v in pairs (tabl) do
		max=max and math.max(v, max) or v
	end
--	local max = math.max(unpack(tabl))
--	game.print('max '..max)
	return max
end

function get_umin(tabl)
	local min
	for i, v in pairs (tabl) do
		min=min and math.min(v, min) or v
	end
--	local min = math.min(unpack(tabl))
	return min
end


function smog.pollution_to_color (pollution)
	local mm=settings.global['svp-min-pollution'].value 
	local mx=settings.global['svp-max-pollution'].value
	local v=math.min(pollution,mx) 
	local pct=math.max(0,v-mm)/(mx-mm) -- from 0 to 1
	return {r=pct*0.3,g=pct*0.3,b=pct*0.3,a=pct*0.6} 
end


function get_chunk_pollution (surface, cx, cy)
	local pollution = surface.get_pollution({cx*32,cy*32})
--	local color = {1,1,1}
--	rendering.draw_text{text=pollution, surface=surface, target={cx*32+16,cy*32+16}, color=color, time_to_live=time_to_live}
	return pollution
end


function get_udata (surface, cx, cy)
	local data = {}
	table.insert (data, surface.get_pollution({(cx-1)*32,(cy-1)*32}))
	table.insert (data, surface.get_pollution({(cx  )*32,(cy-1)*32}))
	table.insert (data, surface.get_pollution({(cx+1)*32,(cy-1)*32}))
	table.insert (data, surface.get_pollution({(cx-1)*32,(cy  )*32}))
	table.insert (data, surface.get_pollution({(cx  )*32,(cy  )*32}))
	table.insert (data, surface.get_pollution({(cx+1)*32,(cy  )*32}))
	table.insert (data, surface.get_pollution({(cx-1)*32,(cy+1)*32}))
	table.insert (data, surface.get_pollution({(cx  )*32,(cy+1)*32}))
	table.insert (data, surface.get_pollution({(cx+1)*32,(cy+1)*32}))
--	game.print ('data '.. #data)
	local udata = {}
	udata.a = (data[1]+data[2]+data[4]+data[5])/4
	udata.b = (data[2]+data[3]+data[5]+data[6])/4
	udata.c = (data[5]+data[6]+data[8]+data[9])/4
	udata.d = (data[4]+data[5]+data[7]+data[8])/4
--	game.print ('udata '.. serpent.line(udata))
	return udata
end


function in_range ( value, min, max)
	min=min or 0
	max=max or min+32
	return (min<=value) and (value<=max) and true or false
end


function as (a, b)
	if not a or not b then return false end
	if a > 1 and b>1 then 
		a=math.floor(a + 0.5)
		b=math.floor(b + 0.5)
	end
	return (math.floor (a*1000) == math.floor (b*1000)) and true or false
end


function remove_rendering (rendering_ids)
	for i, id in pairs (rendering_ids) do
		rendering.destroy(id)
	end
end


function get_ingex (tabl, value)
	for index, v in pairs (value) do
		if v == value then return index end
	end
end

function get_x (a, b, x)
	return 32*(x-a)/(b-a)
end

function c4_points_to_polygon (points)
	local result = {}
		result[#result+1]={target=points[1]}
		result[#result+1]={target=points[2]}
		result[#result+1]={target=points[4]}
		result[#result+1]={target=points[3]}
	return result
end

function update_chunk (surface, cx,cy)
	local chunk = global.chunks[cx][cy]
	if chunk.rendering_ids then
--		rendering.destroy(chunk.rendering_ids)
		remove_rendering(chunk.rendering_ids)
		chunk.rendering_ids = {}
	else
		chunk.rendering_ids = {}
	end
	local udata = get_udata(surface, cx,cy)
--	game.print ('1 udata '.. serpent.line (udata))
	local umin = get_umin(udata)
--	game.print ('2 udata '.. serpent.line (udata))
	local umax = get_umax(udata)
	if umax == 0 then return end
--	game.print ('3 udata '.. serpent.line (udata))
	local gx, gy = cx*32, cy*32
	local point_a,point_b,point_c,point_d={gx,gy},{gx+32,gy},{gx+32,gy+32},{gx,gy+32}
	local points_min = {}
	local points_max = {}
	
	local usection = (umax+umin)/2
	if usection == 0 then return end
	
	if in_range ( usection, get_umin({udata.a, udata.b}), get_umax({udata.a, udata.b})) then
		local x = gx+get_x (udata.a, udata.b, usection)
		local y = gy
		local point = {x, y}
		if udata.a < usection then
			points_min[#points_min+1] = point_a
			points_min[#points_min+1] = point
			
			points_max[#points_max+1] = point
			points_max[#points_max+1] = point_b
		else
			points_max[#points_max+1] = point_a
			points_max[#points_max+1] = point
			
			points_min[#points_min+1] = point
			points_min[#points_min+1] = point_b
		end
	end
	if in_range ( usection, get_umin({udata.d, udata.c}), get_umax({udata.d, udata.c})) then
		local x = gx+get_x (udata.d, udata.c, usection)
		local y = gy+32
		local point = {x, y}
		if udata.d < usection then
			points_min[#points_min+1] = point
			points_min[#points_min+1] = point_d
			
			points_max[#points_max+1] = point_c
			points_max[#points_max+1] = point
		else
			points_max[#points_max+1] = point
			points_max[#points_max+1] = point_d
			
			points_min[#points_min+1] = point_c
			points_min[#points_min+1] = point
		end
	end
	
	if #points_max == 4 and #points_min==4 then
		local colormax = smog.pollution_to_color ((umax+usection)/2)
		local colormin = smog.pollution_to_color ((umin+usection)/2)
		local verticesmax = c4_points_to_polygon (points_max)
--		game.print ('verticesmax '..serpent.line(verticesmax))
		local idmax = rendering.draw_polygon{
			color=colormax, 
			vertices=verticesmax, 
			surface=surface}
		local idmin = rendering.draw_polygon{color=colormin, vertices=c4_points_to_polygon (points_min), surface=surface}
		chunk.rendering_ids[#chunk.rendering_ids+1]=idmax
		chunk.rendering_ids[#chunk.rendering_ids+1]=idmin
	end
end


function smog.tick() -- no arguments in tick
	local surface = game.surfaces[1]
	local chunk = surface.get_random_chunk()
	local cx, cy = chunk.x, chunk.y -- chunk position
	local mm=settings.global['svp-min-pollution'].value 
	local mx=settings.global['svp-max-pollution'].value
	
	
--	get_polygons (surface, {x=cx,y=cy}, mm, mx)

	if not global.chunks then global.chunks = {} end
	if not global.chunks[cx] then global.chunks[cx] = {} end
	if not global.chunks[cx][cy] then global.chunks[cx][cy] = {} end
	
	
	update_chunk(surface, cx, cy)
	
	
	
	
	
end


script.on_event(defines.events.on_tick, smog.tick)
