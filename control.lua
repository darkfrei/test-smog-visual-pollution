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
--	local color = {1,1,1}
--	rendering.draw_text{text=pollution, surface=surface, target={cx*32+16,cy*32+16}, color=color, time_to_live=time_to_live}
	return pollution
end

function new_chunk ()
	local c = 
	{
		pollution = nil, 
		h={}, -- horizontal top values
		v={}, -- vertical left values
--		udata_value=0, -- chunk pollution
--		udata_ids={},
		data_value=0, -- avarage top left edge chunks pollution
--		data_ids={},
		h_point_ids={}, -- 
		v_point_ids={}, -- 
		line_ids={}, -- 
		polygon_ids={}, -- 
	}
	return c
end

function get_udata (surface, cx, cy)
	-- udata is vanilla values
	local udata = {}
	local summ_p=0
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
				summ_p=summ_p+pollution
				global.chunks[cx1][cy1].pollution=pollution
				udata[j]=udata[j]or{}
				udata[j][i]=pollution
			elseif not (global.chunks[cx1] 
				and global.chunks[cx1][cy1]
				and global.chunks[cx1][cy1].pollution) then
				
				pollution = get_chunk_pollution (surface, cx1, cy1)
				summ_p=summ_p+pollution
--				game.print('added chunk: '..cx1..' '..cy1..' '..pollution)
				global.chunks[cx1]=global.chunks[cx1]or{}
				global.chunks[cx1][cy1]=global.chunks[cx1][cy1]or new_chunk ()
				global.chunks[cx1][cy1].pollution=pollution
				udata[j]=udata[j]or{}
				udata[j][i]=pollution
			else
				pollution=global.chunks[cx1][cy1].pollution
				summ_p=summ_p+pollution
				udata[j]=udata[j]or{}
				udata[j][i]=pollution
			end

		end
	end
	return udata, (summ_p==0)
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
--			rendering.draw_text{text=value, surface=surface, target={x,y}, 
--				color=color, time_to_live=time_to_live}
			chunks[cx1][cy1].vertex_pollution = value
--			game.print ('chunks cx1'..cx1..' cy1'..cy1..' value'..value)
		end
	end
--	return data
end

function set_levels ()
	local mm=settings.global['svp-min-pollution'].value 
	local mx=settings.global['svp-max-pollution'].value
	local levels_amount=100
	local step = (mx-mm)/levels_amount
	local levels = {}
--	levels[#levels+1]=0
--	levels[#levels+1]=0.1
	
	for i = mm, mx, step do
		levels[#levels+1] = i
	end
	global.levels = levels
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

function genMPoints(cx, cy)
	local levels = global.levels
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
	local a = {chunk=chunks[cx][cy], 	letter='h'}
	local b = {chunk=chunks[cx+1][cy], 	letter='v'}
	local c = {chunk=chunks[cx][cy+1], 	letter='h'}
	local d = {chunk=chunks[cx][cy], 	letter='v'}
	for i, side in pairs ({a,b,c,d}) do
		local chunk = side.chunk
		local letter = side.letter
		local point_ids
		if letter == "h" then
			chunk.h_point_ids = chunk.h_point_ids or {} -- for test, must remove
			remove_rendering (chunk.h_point_ids or {})
			point_ids = chunk.h_point_ids
		else
			chunk.v_point_ids = chunk.v_point_ids or {} -- for test, must remove
			remove_rendering (chunk.v_point_ids or {})
			point_ids = chunk.v_point_ids
		end
		
		local points = chunk[letter] -- side, v or h
		for i, point in pairs (points) do
			
			local x = point.x
			local y = point.y
			local value = point.value
			local circle_id = rendering.draw_circle{color=color, radius=0.25, surface=surface, target={x,y}}
			local text_id = rendering.draw_text{text=value, surface=surface, target={x,y}, color=color}
			point_ids[#point_ids+1] = circle_id
			point_ids[#point_ids+1] = text_id
		end
	end
end

function shortest_line_index (lines)
	local index, sqlenght
	
	for i, line in pairs (lines) do
--		game.print('line:'..serpent.line(line))
		local qlenght = (line.from.x-line.to.x)^2+(line.from.y-line.to.y)^2
		if not sqlenght then
			sqlenght = qlenght
			index = i
		elseif qlenght < sqlenght then
			sqlenght = qlenght
			index = i
		end
		sqlenght = sqlenght and math.min(sqlenght, qlenght) or qlenght
	end
	
	return index
end

function find_free_line (lines, s_line)
	for i, line in pairs (lines) do
		local fl = true
		for j, a in pairs (line) do
			for k, b in pairs (s_line) do
				if as (a.x, b.x) and as (a.y, b.y) then
					fl = false
				end
			end
		end
		if fl then
			return line
		end
	end
end

function optimize_6_lines (lines)
	local s_index = shortest_line_index (lines)
	local s_line = lines[s_index]
	table.remove(lines, s_index)
	local f_line = find_free_line (lines, s_line)
	
	return {s_line, f_line}
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
	
	local mlines = {} -- structured lines
	
	for i, con in pairs (cons) do
		local first_side = con[1]
		local second_side = con[2]
		for j, from_point in pairs (first_side) do
			for k, to_point in pairs (second_side) do
				if from_point.value == to_point.value then
					local value = from_point.value
					local line = {from=from_point, to=to_point}
					mlines[value]=mlines[value] or {}
					mlines[value][#mlines[value]+1] = line
					table.insert (lines, line)
				end
			end
		end
	end
	
	for value, lines in pairs (mlines) do
		if #lines == 6 then
			game.print('was:	' .. ' cx:'..cx..' cy:'..cy..' #lines:' .. #lines)
			lines = optimize_6_lines (lines)
			mlines[value] = lines
			game.print('now:	' .. ' cx:'..cx..' cy:'..cy..' #lines:' .. #lines)
		end
		
		if #lines > 2 then
--			game.print('cx:'..cx..' cy:'..cy..' #lines:' .. #lines)
		end
	end
	
	lines = {}
	
	for value, new_lines in pairs (mlines) do
		for i, line in pairs (new_lines) do
--			lines[#lines+1]=line
			table.insert (lines, line)
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

function update_isolines(surface, cx, cy)
	local mpoints = genMPoints (cx, cy)

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

function draw_udata_points (surface, cx,cy)
	local chunk = global.chunks[cx][cy]
	local color = {1,1,1}
--	local color = {1,1,0}
	if chunk.udata_id then
		rendering.destroy(chunk.udata_id)
	end
	local pollution = math.floor(chunk.pollution+0.5)
--	local pollution = chunk.vertex_pollution
	local x, y = cx*32+16, cy*32+16
	local id = rendering.draw_text{text=pollution, surface=surface, target={x=x,y=y}, color=color}
	chunk.udata_id = id
end

function draw_data_points (surface, cx,cy)
	local chunk = global.chunks[cx][cy]
--	local color = {1,1,1}
	local color = {1,1,0}
	if chunk.data_id then
		rendering.destroy(chunk.data_id)
	end
--	local pollution = chunk.pollution
	local pollution = math.floor(chunk.vertex_pollution+0.5)
	local x, y = cx*32, cy*32
	local id = rendering.draw_text{text=pollution, surface=surface, target={x=x,y=y}, color=color}
	chunk.data_id = id
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
	
	
	local udata, is_empty = get_udata (surface, cx, cy)
	local c = global.chunks[cx][cy]
	if is_empty and c.was_empty then 
		return 
	elseif is_empty then
		c.was_empty = true
	else
		c.was_empty = false
	end
	
--	local data = set_data (surface, udata, cx, cy)
	set_data (surface, udata, cx, cy)
	
	if not global.levels then
		set_levels ()
	end
	
	draw_udata_points (surface, cx,cy)
	draw_data_points (surface, cx,cy)
	
	update_isolines(surface, cx, cy)
	
	
	
	
	
	
end


script.on_event(defines.events.on_tick, smog.tick)
