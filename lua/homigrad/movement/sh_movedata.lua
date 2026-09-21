--\\ Add RemoveKey to CMoveData
	local CMoveData = FindMetaTable( "CMoveData" )

	function CMoveData:RemoveKeys( keys )
		local newbuttons = bit.band( self:GetButtons(), bit.bnot( keys ) )
		self:SetButtons( newbuttons )
	end

	function CMoveData:RemoveKey( keys )
		local newbuttons = bit.band( self:GetButtons(), bit.bnot( keys ) )
		self:SetButtons( newbuttons )
	end
--//