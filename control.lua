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

function get_udata (surface, cx, cy)
	local udata = {}
	for i=1, 3 do -- as y
		for j=1, 3 do -- as x
			udata[j]=udata[j]or{}
			udata[j][i]=get_chunk_pollution (surface, cx+j-2, cy+i-2) -- from cx-1 to cx+1
		end
	end
	return udata
end

function get_data (surface, udata, cx, cy)
	local data = {}
	local color = {0,1,0}
	for i=1, 2 do
		data[i]={}
		for j=1, 2 do
			
			local value = (udata[i][j]+udata[i+1][j]+udata[i][j+1]+udata[i+1][j+1])/4
			data[i][j]=value
			rendering.draw_text{text=value, surface=surface, target={(cx+j-2)*32,(cy+i-2)*32}, color=color, time_to_live=time_to_live}
		end
	end
	return data
end

function get_levels ()
	local levels = {}
--	for level = 0, 1000, 10 do
--		levels[#levels+1]=level
--	end
	levels[#levels+1]=0
	levels[#levels+1]=0.1
	local k = 10^(1/10)
	for i = 1, 1000 do
		levels[#levels+1]=k^i
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

function genMPoints(data, levels, cx, cy)
	local tileSize = 32
	local mpoints = {}
	local a,b,c,d  = data[1][1], data[2][1], data[2][2], data[1][2]
	local e = (a+b+c+d)/4
	for k, level in pairs (levels) do
		mpoints[level]={}
		local m = mpoints[level]
		
		local xa = cx*tileSize+tileSize*(level-a)/(b-a)
		local ya = cy*tileSize
		if in_range (xa, cx*tileSize) and in_range (ya, cy*tileSize) then
			table.insert (mpoints[level], xa)
			table.insert (mpoints[level], ya)
		end
		
		local xb = cx*tileSize+tileSize
		local yb = cy*tileSize+tileSize*(level-b)/(c-b)
		if not (as(m[#m-1],xb) and as(m[#m],yb)) then
			if in_range (xb, cx*tileSize) and in_range (yb, cy*tileSize) then
				table.insert (m, xb)
				table.insert (m, yb)
			end
		elseif #m>2 then
			print ('b double: '..level)
			table.insert (m, 1, xb)
			table.insert (m, 2, yb)
		end
		
		local xc = cx*tileSize+tileSize - tileSize*(level-c)/(d-c)
		local yc = cy*tileSize+tileSize
		if not (as(m[#m-1],xc) and as(m[#m],yc)) then
			if in_range (xc, cx*tileSize) and in_range (yc, cy*tileSize) then
				table.insert (m, xc)
				table.insert (m, yc)
			end
		elseif #m>2 then
			print ('c double: '..level)
			table.insert (m, 1, xc)
			table.insert (m, 2, yc)
		end
		
		local xd = cx*tileSize
		local yd = cy*tileSize+tileSize - tileSize*(level-d)/(a-d)
--		print ('yd:'..yd)
		if not (as(m[#m-1],xd) and as(m[#m],yd)) then
			if in_range (xd, cx*tileSize) and in_range (yd, cy*tileSize) then
				table.insert (m, xd)
				table.insert (m, yd)
			end
		elseif #m>2 then
			print ('d double: '..level)
			table.insert (m, 1, xd)
			table.insert (m, 2, yd)
		end
		
		if #m>2 then
			print (level..': ' .. #m)
			print (unpack(m))
		end
	end
	return mpoints
end

function drawMPoints(surface, mpoints)
	local color = {1,1,1}
	for name, points in pairs (mpoints) do
--		love.graphics.points(points)
		for j = 1, #points-1, 2 do
			local x = points[j]
			local y = points[j+1]
--			love.graphics.print(name, x-3,y-9, -math.pi/4)
			rendering.draw_circle{color=color, radius=0.25, surface=surface, target={x,y}, time_to_live=time_to_live}
			rendering.draw_text{text=name, surface=surface, target={x,y}, color=color, time_to_live=time_to_live}
		end
	end
end

function drawLines(surface, mpoints)
	local color = {0,1,1}
	for name, points in pairs (mpoints) do
		if #points == 4 then
			local x  = points[1]
			local y  = points[2]
			local x1 = points[3]
			local y1 = points[4]
			rendering.draw_line{color=color, width=1, surface=surface, from={x,y}, to={x1, y1}, time_to_live=time_to_live}
		end
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
	local data = get_data (surface, udata, cx, cy)
	local levels = get_levels ()
	
	local mpoints = genMPoints (data, levels, cx, cy)
	
	drawMPoints(surface, mpoints)
	drawLines(surface, mpoints)
	
end


script.on_event(defines.events.on_tick, smog.tick)
