-- simple realization
-- convex only
-- up to 8 points

function convert (polygon)
	local ts = {} -- triangle strip
	if #polygon = 3 then
		return polygon
	elseif #polygon = 4 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		ts[3]=polygon[4]
		ts[4]=polygon[3]
		return ts
	elseif #polygon = 5 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		ts[3]=polygon[5]
		ts[4]=polygon[3]
		ts[5]=polygon[4]
		return ts
	elseif #polygon = 6 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		ts[3]=polygon[6]
		ts[4]=polygon[3]
		ts[5]=polygon[5]
		ts[6]=polygon[4]
		return ts
	elseif #polygon = 7 then
		ts[1]=polygon[1]
		ts[2]=polygon[2]
		ts[3]=polygon[7]
		ts[4]=polygon[3]
		ts[5]=polygon[6]
		ts[6]=polygon[4]
		ts[7]=polygon[5]
		return ts
	elseif #polygon = 8 then
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