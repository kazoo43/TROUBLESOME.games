hg.organism = hg.organism or {}

function hg.organism.GetOBBTransform(pos, ang, obbMins, obbMaxs, obbCenter, half, mins)
	half:Set(obbMins)
	half:Sub(obbMaxs)
	half:Div(2)
	half:Rotate(ang)

	mins:Set(obbMins)
	mins:Rotate(ang)
	mins:Sub(half)

	local center = pos + mins

	return center, (obbCenter - center):Length() + half:Length() / 2
end
