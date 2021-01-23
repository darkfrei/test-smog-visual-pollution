local smog={}

time_to_live = 3*10*60


function max(tabl)
	local max = math.max(unpack(tabl))
	return max
end
function min(tabl)
	local min = math.min(unpack(tabl))
	return min
end


function smog.pollution_to_color (pollution)
	
	local mm=settings.global['svp-min-pollution'].value 
	local mx=settings.global['svp-max-pollution'].value
	local v=math.min(pollution,mx) 
	local pct=math.max(0,v-mm)/(mx-mm) -- from 0 to 1
	return {r=pct*0.3,g=pct*0.3,b=pct*0.3,a=pct*0.6} 
end



function get_lenght (i1, v1, i2, v2, v3)
	-- magick! (no)
	local k1 = v3-v1
	local k2 = v2-v1
	local i3 = i1 + (i2-i1)*(k1/k2)
	return i3
end


function get_polygons (surface, position, mm, mx)
	-- https://en.wikipedia.org/wiki/Marching_squares
	local color = {0.5,0.5,0.5, 0.5}
	local polygons = {}
	
	
	local x,y = position.x,position.y
	local s = 32
	
	local ps = {} -- average pollution in verticle, percent
	local shs = {{x=-1,y=-1},{x=0,y=-1},{x=-1,y=0},{x=0,y=0}}
	for i, sh1 in pairs (shs) do -- for every edge
		local p = 0
		for j, sh2 in pairs (shs) do
			local pos2 = {x=s*x+s*sh1.x+s*sh2.x,y=s*y+s*sh1.y+s*sh2.y}
			local pos3 = {x=pos2.x+sh1.x,y=pos2.y+sh1.y}
			local a = surface.get_pollution(pos2)
			rendering.draw_text{text=a, surface=surface, target=pos3, color=color, time_to_live=time_to_live}
			p=p+a
		end
		p=p/4
		ps[#ps+1]=p
	end
--	game.print ('min: '..min(ps) .. ' max: '..max(ps))

	local section = 50
	
	
--	local shape = 
--		{
--			{target={s*x, s*y}},
--			{target={s*x+8, s*y}},
--			{target={s*x, s*y+16}},
--			{target={s*x+16, s*y+8}},
--		}
	
--	rendering.draw_polygon{
--		color=color,
--		vertices = shape,
--		surface=surface, 
--		time_to_live=300}
	
	
--	return polygons
end


function get_chunk_pollution (surface, cx, cy)
	local pollution = surface.get_pollution({cx*32,cy*32})
	local color = {1,1,1}
	rendering.draw_text{text=pollution, surface=surface, target={cx*32+16,cy*32+16}, color=color, time_to_live=time_to_live}
	return pollution
end

function new_chunk ()
	local c = 
	{
		pollution = nil, 
		h={}, -- horizontal top values
		v={}, -- vertical left values
		point_ids={}, -- 
		line_ids={}, -- 
		polygon_ids={}, -- 
	}
	return c
end

function get_udata (surface, cx, cy)
	-- udata is vanilla values
	local udata = {}
	for i=1, 3 do -- as y
		for j=1, 3 do -- as x
			local cx1 = cx+j-2
			local cy1 = cy+i-2
			local pollution
			if (i==2 and j==2) then
				global.chunks[cx1]=global.chunks[cx1]or{}
				global.chunks[cx1][cy1]=global.chunks[cx1][cy1]or new_chunk ()
				global.chunks[cx1][cy1].pollution=pollution
				pollution = get_chunk_pollution (surface, cx1, cy1) -- from cx-1 to cx+1
				global.chunks[cx1][cy1].pollution=pollution
				udata[j]=udata[j]or{}
				udata[j][i]=pollution
			elseif not (global.chunks[cx1] 
				and global.chunks[cx1][cy1]
				and global.chunks[cx1][cy1].pollution) then
				
				pollution = get_chunk_pollution (surface, cx1, cy1)
--				game.print('added chunk: '..cx1..' '..cy1..' '..pollution)
				global.chunks[cx1]=global.chunks[cx1]or{}
				global.chunks[cx1][cy1]=global.chunks[cx1][cy1]or new_chunk ()
				global.chunks[cx1][cy1].pollution=pollution
				udata[j]=udata[j]or{}
				udata[j][i]=pollution
			else
				pollution=global.chunks[cx1][cy1].pollution
				udata[j]=udata[j]or{}
				udata[j][i]=pollution
			end

		end
	end
	return udata
end

function set_data (surface, udata, cx, cy)
--	local data = {}
	local chunks = global.chunks
	local color = {0,1,0}
	for i=1, 2 do -- as y (or not)
--		data[i]={}
		for j=1, 2 do -- as x (or not)
			local cx1 = cx+j-1
			local cy1 = cy+i-1
			local x = cx1*32+16
			local y = cy1*32+16
			local value = (udata[i][j]+udata[i+1][j]+udata[i][j+1]+udata[i+1][j+1])/4
--			data[i][j]=value
			rendering.draw_text{text=value, surface=surface, target={x,y}, 
				color=color, time_to_live=time_to_live}
			chunks[cx1][cy1].vertex_pollution = value
--			game.print ('chunks cx1'..cx1..' cy1'..cy1..' value'..value)
		end
	end
--	return data
end

function get_levels ()
	local levels = {}
	levels[#levels+1]=0
	levels[#levels+1]=0.1
	local k = 10^(1/10)
	for i = 1, 1000 do
		local level =k^i
		if (level > 10) then
			if (level < 100) then
				level = math.floor ((level+0.5)*10)/10
			else
				level = math.floor ((level+0.5))
			end
		end
		levels[#levels+1] = level
	end
	return levels
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

function genMPoints(levels, cx, cy)
--	game.print ('cy:'..cy)
	local chunks = global.chunks
	local a = chunks[cx][cy].vertex_pollution
	local b = chunks[cx][cy+1].vertex_pollution
	local c = chunks[cx+1][cy+1].vertex_pollution
	local d = chunks[cx+1][cy].vertex_pollution
	local e = (a+b+c+d)/4
	local tileSize = 32
	local mpoints = {}
	
	-- mpoints saved; AB and DA are saved in the chunk A
	-- mpoints BC are saved in chunk cx+1,cy; vertical
	-- mpoints CD are saved in chunk cx,cy+1; horizontal
	local side_a, side_b, side_c, side_d = {}, {}, {}, {}
	for k, level in pairs (levels) do
		-- mpoints or m - points on the chunk edges; two, three or four
		local m = {}
		
		-- point pA on the chunk side AB
		local xa = cx*tileSize+tileSize*(level-a)/(b-a)
		local ya = cy*tileSize
		if in_range (xa, cx*tileSize) and in_range (ya, cy*tileSize) then
			local mpoint = {x=xa, y=ya, side='a', value=level}
			table.insert (m, mpoint)
			table.insert (side_a, mpoint)
		end
		
		-- point pB on the chunk side BC
		local xb = (cx+1)*tileSize
		local yb = cy*tileSize+tileSize*(level-b)/(c-b)
		if in_range (xb, cx*tileSize) and in_range (yb, cy*tileSize) then
			local mpoint = {x=xb, y=yb, side='b', value=level}
			table.insert (m, mpoint)
			table.insert (side_b, mpoint)
		end
		
		-- point pC on the chunk side CD
		local xc = cx*tileSize+tileSize - tileSize*(level-c)/(d-c)
		local yc = cy*tileSize+tileSize
		if in_range (xc, cx*tileSize) and in_range (yc, cy*tileSize) then
			local mpoint = {x=xc, y=yc, side='c', value=level}
			table.insert (m, mpoint)
			table.insert (side_c, mpoint)
		end
		
		-- point pD on the chunk side DA
		local xd = cx*tileSize
		local yd = cy*tileSize+tileSize - tileSize*(level-d)/(a-d)
		if in_range (xd, cx*tileSize) and in_range (yd, cy*tileSize) then
			local mpoint = {x=xd, y=yd, side='d', value=level}
			table.insert (m, mpoint)
			table.insert (side_d, mpoint)
		end
	end
	
	
	chunks[cx][cy].h=side_a
	chunks[cx+1][cy].v=side_b
	chunks[cx][cy+1].h=side_c
	chunks[cx][cy].v=side_d
	
	return mpoints
end



function drawMPoints(surface, cx, cy)
	local color = {1,1,1}
	local chunks = global.chunks
	local a = chunks[cx][cy].h
	local b = chunks[cx+1][cy].v
	local c = chunks[cx][cy+1].h
	local d = chunks[cx][cy].v
	for i, side in pairs ({a,b,c,d}) do
		for i, point in pairs (side) do
			local x = point.x
			local y = point.y
			local value = point.value
			rendering.draw_circle{color=color, radius=0.25, surface=surface, target={x,y}, time_to_live=time_to_live}
			rendering.draw_text{text=value, surface=surface, target={x,y}, color=color, time_to_live=time_to_live}
		end
	end
end


function genMLines (cx, cy, levels)
	local chunks = global.chunks
	if not (chunks[cx+1] and chunks[cx+1][cy] and chunks[cx][cy+1]) then return end
	local a = chunks[cx][cy].h
	local b = chunks[cx+1][cy].v
	local c = chunks[cx][cy+1].h
	local d = chunks[cx][cy].v
	
	local lines = {}
	local cons = {{a, b}, {b, c}, {c, d}, {d, a}, {a, c}, {b, d}}
	
	for i, con in pairs (cons) do
		local first_side = con[1]
		local second_side = con[2]
		for j, from_point in pairs (first_side) do
			for k, to_point in pairs (second_side) do
				if from_point.value == to_point.value then
					table.insert (lines, {from=from_point, to=to_point})
				end
			end
		end
	end
	chunks[cx][cy].lines = lines
end

function remove_rendering (rendering_ids)
	for i, id in pairs (rendering_ids) do
		rendering.destroy(id)
	end
end

function drawMLines (surface, cx, cy)
	local color = {0,1,1}
	local chunk = global.chunks[cx][cy]
	
	remove_rendering (chunk.line_ids)
	
	local lines = chunk.lines
--	game.print ('cx:'..cx..' cy:'..cy..' lines:'..#lines)
	if lines then
		for i, line in pairs (lines) do
			local from=line.from
			local to=line.to
			local line_id = rendering.draw_line{color=color, width=1, surface=surface, from=from, to=to}
			table.insert (chunk.line_ids, line_id)
		end
	end
end

function update_isolines(surface, levels, cx, cy)
	local mpoints = genMPoints (levels, cx, cy)

	drawMPoints(surface, cx, cy)
	
	genMLines (cx, cy)
	
	drawMLines(surface, cx, cy)
	
	for i, pos in pairs ({
		{-1,-1}, { 0,-1},{0,-1},
		{-1, 0}, 		 { 1,0},
		{-1, 1}, { 0, 1},{ 1,1},
		}) do
		genMLines (cx+pos[1], cy+pos[2])
		drawMLines (surface, cx+pos[1], cy+pos[2])
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
	
	local udata = get_udata (surface, cx, cy)
--	local data = set_data (surface, udata, cx, cy)
	set_data (surface, udata, cx, cy)
	local levels = get_levels ()
	
	update_isolines(surface, levels, cx, cy)
	
	
	
	
	
	
end


script.on_event(defines.events.on_tick, smog.tick)
