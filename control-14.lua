local smog={}


function get_min(tabl)
	local min, index
	for i, v in pairs (tabl) do
		if (min and (min > v)) or not min then
			min=v
			index=i
		end
	end
	return min, index
end

function get_max(tabl)
	local max, index
--	game.print('max serp '.. serpent.line(tabl))
	for i, v in pairs (tabl) do
		if (max and (max < v)) or not max then
			max=v
			index=i
		end
	end
	return max, index
end

function polygon_to_ts (polygon)
	local ts = {polygon[1], polygon[2]}
	local i_max = #polygon
	
	for i_min = 3, i_max do
		ts[#ts+1]=polygon[i_max]
		if i_max <= i_min then return ts end
		ts[#ts+1]=polygon[i_min]
		i_max=i_max-1
		if i_max <= i_min then return ts end
	end
	return ts
end



function smog.pollution_to_color (pollution)
	local mm=settings.global['svp-min-pollution'].value 
--	local mm=0
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
	-- it takes pollution from this and near chunks
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
	-- translate chunk pollution to vertex pollution
	local udata = {}
	udata.a = (data[1]+data[2]+data[4]+data[5])/4 -- top left
	udata.b = (data[2]+data[3]+data[5]+data[6])/4 -- top right
	udata.c = (data[5]+data[6]+data[8]+data[9])/4 -- bottom left
	udata.d = (data[4]+data[5]+data[7]+data[8])/4 -- bottom right
	udata.e = (udata.a+udata.b+udata.c+udata.d)/4 -- middle
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

function get_section (a, b, x)
	return 32*(x-a)/(b-a)
end

function ts_to_vertices (ts)
	local vertices = {}
	for i, point in pairs (ts) do
--		game.print('point: '..serpent.line(point))
		table.insert(vertices, {target={point.x,point.y}})
	end
--	table.insert(vertices, {target={0,0}})
--	game.print('vertices: '..serpent.line(vertices))
	return vertices
end


--function get_position (section, u1, u2, p1, p2) -- local
--	local sides = {ab="A",ba="A",bc="B",cb="B",cd="C",dc="C",da="D",ad="D"}
--	local side = sides[p1..p2]
--	local s = get_section (u1, u2, section)
--	if side == "A" then
--		return {x=s,y=0}
--	elseif side == "B" then
--		return {x=32,y=s}
--	elseif side == "C" then
--		return {x=s,y=32}
--	else -- elseif side == "D" then
--		return {x=0,y=s}
--	end
--end


--function update_points (points, section, udata, t, first_line)
--	local pstart = t[1]
--	local ustart = udata[pstart]
--	local pmiddle = first_line and t[2] or t[4]
--	local umiddle = udata[pmiddle]
--	local pend = t[3]
--	local uend = udata[pend]	
	
--	if in_range (section, ustart, umiddle) then -- a to b
--		local pos = get_position (section, ustart, umiddle, pstart, pmiddle)
--		local point = {x=pos.x, y=pos.y, section=section, second=false}
--		points[#points+1]=point
--	else -- b to c
--		local pos = get_position (section, umiddle, uend, pmiddle, pend)
--		local point = {x=pos.x, y=pos.y, section=section, second=true}
--		points[#points+1]=point
--	end
--end

--function render_polygons (surface, cx, cy, points_1, points_2, t)
----	local t = {'a','b','c','d'}
--	local gx, gy = cx*32, cy*32
--	local points={a={x=gx,y=gy},b={x=gx+32,y=gy},c={x=gx+32,y=gy+32},d={x=gx,y=gy+32}}
--	for i = 1, #points_1 do
--		local polygon = {}
--		if i == 1 then -- min
----			polygon[#polygon+1]=t[1]
--			polygon[#polygon+1]=points[t[1]]
--			if points_1[i].second then 
--				fl1 = false
--				polygon[#polygon+1]=points[t[2]]
--			end
--			polygon[#polygon+1]=points_1[i]
--			polygon[#polygon+1]=points_2[i]
--			if points_2[i].second then 
--				polygon[#polygon+1]=t[3]
--			end
--			local ts = polygon_to_ts (polygon)
--			local vertices = ts_to_vertices (ts)
--			local pollution = points_1[i].section
--			local color = smog.pollution_to_color (pollution)
			
--			game.print ('vertices: '..serpent.line(vertices))
--			local id = rendering.draw_polygon{color=color, vertices=vertices, surface=surface}
--			table.insert(global.chunks[cx][cy].rendering_ids, id)
			
--		else -- more than 1
--			polygon[#polygon+1]=points_1[i-1]
--			if not (points_1[i-1].second == points_1[i].second) then 
--				fl1 = false
--				polygon[#polygon+1]=points[t[2]] -- b
--			end
--			polygon[#polygon+1]=points_1[i]
			
--			if i == #points_1 then -- max
--				polygon[#polygon+1]=points[points[3]]
--			end
			
--			polygon[#polygon+1]=points_2[i]
--			if not (points_2[i-1].second == points_2[i].second) then 
--				fl2 = false
--				polygon[#polygon+1]=points[t[4]] -- d
--			end
--			polygon[#polygon+1]=points_2[i-1]
			
--			local ts = polygon_to_ts (polygon)
--			local vertices = ts_to_vertices (ts)
--			local pollution = points_1[i].section
----			local color = {1/#points_1,1/#points_1,1/#points_1,0.5}
--			local color = smog.pollution_to_color (pollution)
--			local id = rendering.draw_polygon{color=color, vertices=vertices, surface=surface}
--			table.insert(global.chunks[cx][cy].rendering_ids, id)
--		end
--	end
--end

--function update_trivial (surface, cx, cy, udata, pmin)
--	local trivials = {
--		a = {'a','b','c','d'},
--		b = {'b','c','d','a'},
--		c = {'c','d','a','b'},
--		d = {'d','a','b','c'},
--	}
--	-- was a to c; t=trivials[a]; a=t[1], c=t[3]
--	local t=trivials[pmin] -- t is 1 of 4 trivial fields
--	local step = 6
--	local gx, gy = cx*32, cy*32
	
	
--	local minvalue = math.ceil(udata[t[1]]/step)*step
--	local maxvalue = math.floor(udata[t[3]]/step)*step

--	local points_1 = {}
--	local points_2 = {}
--	for section = minvalue, maxvalue do -- or minvalue+1, maxvalue-1
--		update_points (points_1, section, udata, t, true)
--		update_points (points_2, section, udata, t, false)
--	end

--	if #points_1 == 0 then
--		return
--	end

--	render_polygons (surface, cx, cy, points_1, points_2, t)
	
--end



function get_point (p1,p2,u1,u2,u)
	if u1 == u2 then return end -- no gradient here
	if u > math.max(u1,u2) or u < math.min(u1,u2) then return end -- out of range
	local s = (u-u1)/(u2-u1)
	local dx = (p2.x-p1.x)
	local dy = (p2.y-p1.y)
	return {x=p1.x+s*dx,y=p1.y+s*dy}
end

function draw_isolines (surface,cx,cy,level)
--	local color = smog.pollution_to_color (level.u)
	local c = math.min(level.u, 100)/100
	local w = math.max(level.u/100, 1)
	local color = {0,c,c, c}
	local x1,y1=cx*32+level.point_1.x,cy*32+level.point_1.y
	local x2,y2=cx*32+level.point_2.x,cy*32+level.point_2.y
	local id = rendering.draw_line{color=color,width=w,from={x=x1,y=y1},to={x=x2,y=y2}, surface=surface}
	table.insert(global.chunks[cx][cy].rendering_ids, id)
end

function get_polygons (surface,cx,cy,u1,u2,u3, p1,p2,p3)
	local polygons = {}
	local step = 6
	local umin, umax = math.min(u1,u2,u3), math.max(u1,u2,u3)
	
	local pmin, pmax
	if u1 == umin then pmin = p1 elseif u2 == umin then pmin = p2 else pmin = p3 end
	if u1 == umax then pmax = p1 elseif u2 == umax then pmax = p2 else pmax = p3 end
	local from, to = math.ceil(umin/step)*step, math.floor(umax/step)*step
	if to == 0 or (from == to) then return end
	local levels = {} --actually isolines
	for u = from, to, step do
--		game.print('u: '..u .. ' from: '..from.. 'to: '..to)
		local point_a = get_point (p1,p2,u1,u2,u)
--		game.print('point_a: '..serpent.line(point_a))
		local point_b = get_point (p2,p3,u2,u3,u)
--		game.print('point_b: '..serpent.line(point_b))
		local point_c = get_point (p3,p1,u3,u1,u)
--		game.print('point_c: '..serpent.line(point_c))
		local point_1 = point_a or point_b
		local point_2 = point_a and point_b or point_c
		local level = {u=u, point_1=point_1, point_2=point_2}
		
		draw_isolines (surface,cx,cy,level)
	end
	
	
	return polygons
end

function update_saddle (surface,cx,cy,udata)
	local triangles = {a={"a","b","e"},b={"b","c","e"},c={"c","d","e"},d={"d","a","e"}}
	local positions = {a={x=0,y=0},b={x=32,y=0},c={x=32,y=32},d={x=0,y=32},e={x=16,y=16}}
	for tr_letter, triangle in pairs (triangles) do
		local l1,l2,l3 = triangle[1],triangle[2],triangle[3] -- l - point letter
		local u1,u2,u3 = udata[l1],udata[l2],udata[l3] -- pollution value
		local p1,p2,p3 = positions[l1],positions[l2],positions[l3] -- position
		local polygons = get_polygons (surface,cx,cy,u1,u2,u3, p1,p2,p3)
	end
end



function remove_rendering_ids(chunk)
	if chunk.rendering_ids then
		remove_rendering(chunk.rendering_ids)
		chunk.rendering_ids = {}
	else
		chunk.rendering_ids = {}
	end
end

function update_chunk (surface, cx,cy)
	local chunk = global.chunks[cx][cy]

	local udata = get_udata(surface, cx,cy)
--	game.print ('1 udata '.. serpent.line (udata))
--	local umin, pmin = get_min(udata)
--	game.print ('2 udata '.. serpent.line (udata))
--	local umax, pmax = get_max(udata)
	if umax == 0 then return end
	
	remove_rendering_ids(chunk)
	
	update_saddle (surface,cx,cy,udata)
end


function smog.tick() -- no arguments in tick
	local surface = game.surfaces[1]
	local chunk = surface.get_random_chunk()
	local cx, cy = chunk.x, chunk.y -- chunk position
	local mm=settings.global['svp-min-pollution'].value 
	local mx=settings.global['svp-max-pollution'].value
	if not global.chunks then global.chunks = {} end
	if not global.chunks[cx] then global.chunks[cx] = {} end
	if not global.chunks[cx][cy] then global.chunks[cx][cy] = {} end
	update_chunk(surface, cx, cy)
end


script.on_event(defines.events.on_tick, smog.tick)
