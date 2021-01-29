-- simple realization
-- convex only
-- up to 8 points

-- examples ho to do it:
function convert_1 (polygon)
	local ts = {} -- triangle strip
	if #polygon == 3 then
		return polygon
	elseif #polygon == 4 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		
		ts[3]=polygon[4]
		ts[4]=polygon[3]
		return ts
	elseif #polygon == 5 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		
		ts[3]=polygon[5]
		ts[4]=polygon[3]
		ts[5]=polygon[4]
		return ts
	elseif #polygon == 6 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		
		ts[3]=polygon[6]
		ts[4]=polygon[3]
		ts[5]=polygon[5]
		ts[6]=polygon[4]
		return ts
	elseif #polygon == 7 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		
		ts[3]=polygon[7]
		ts[4]=polygon[3]
		ts[5]=polygon[6]
		ts[6]=polygon[4]
		ts[7]=polygon[5]
		return ts
	elseif #polygon == 8 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		
		ts[3]=polygon[8]
		ts[4]=polygon[3]
		ts[5]=polygon[7]
		ts[6]=polygon[4]
		ts[7]=polygon[6]
		ts[8]=polygon[5]
		return ts
	end
end



-- code	how to do it
function convert_2 (polygon)
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

local ts = convert_2 ({1,2})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2
print(' ')

ts = convert_2 ({1,2,3})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2 3
print(' ')

ts = convert_2 ({1,2,3,4})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2 4 3
print(' ')

ts = convert_2 ({1,2,3,4,5})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2 5 3 4
print(' ')

ts = convert_2 ({1,2,3,4,5,6})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2 6 3 5 4
print(' ')

ts = convert_2 ({1,2,3,4,5,6,7})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2 7 3 6 4 5
print(' ')

ts = convert_2 ({1,2,3,4,5,6,7,8})
for i, v in pairs (ts) do
	print(v)
end
 -- 1 2 8 3 7 4 6 5
