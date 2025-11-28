-- Animation and UI Polyfills for WotLK 3.3.5a
do
	local function HookCreateAnimationGroup(objectType)
		local success, obj = pcall(CreateFrame, objectType)
		if not success then return end
		
		local mt = getmetatable(obj).__index
		if mt.CreateAnimationGroup and not mt.IsCreateAnimationGroupHooked then
			local OriginalCreate = mt.CreateAnimationGroup
			mt.CreateAnimationGroup = function(self, ...)
				local grp = OriginalCreate(self, ...)
				local OrigAnim = grp.CreateAnimation
				grp.CreateAnimation = function(g, t, ...)
					local a = OrigAnim(g, t, ...)
					if not a then return end
					local ut = string.upper(t)
					if ut == "ALPHA" and not a.SetFromAlpha then
						a.fromAlpha, a.toAlpha = 0, 1
						a.SetFromAlpha = function(s, v) s.fromAlpha = v if s.toAlpha then s:SetChange(s.toAlpha - v) end end
						a.SetToAlpha = function(s, v) s.toAlpha = v s:SetChange(s.fromAlpha and (v - s.fromAlpha) or v) end
					end
					if ut == "SCALE" and not a.SetFromScale then
						a.fromScaleX, a.fromScaleY, a.toScaleX, a.toScaleY = 1, 1, 1, 1
						a.SetFromScale = function(s, x, y) s.fromScaleX, s.fromScaleY = x, y or x if s.toScaleX and s.toScaleY then s:SetScale(s.toScaleX, s.toScaleY) end end
						a.SetToScale = function(s, x, y) s.toScaleX, s.toScaleY = x, y or x s:SetScale(x, y or x) end
					end
					return a
				end
				return grp
			end
			mt.IsCreateAnimationGroupHooked = true
		end
	end

	for _, w in ipairs({"Frame","Button","CheckButton","Slider","StatusBar","ScrollFrame","MessageFrame"}) do pcall(HookCreateAnimationGroup, w) end

	local t = UIParent:CreateTexture()
	local tm = getmetatable(t).__index
	tm.AddMaskTexture = tm.AddMaskTexture or function(s, m) return m end
	tm.SetScale = tm.SetScale or function() end
	tm.SetTexelSnappingBias = tm.SetTexelSnappingBias or function() end
	tm.SetSnapToPixelGrid = tm.SetSnapToPixelGrid or function() end

	local function AddFramePolyfills(ot)
		local s, o = pcall(CreateFrame, ot)
		if not s then return end
		local m = getmetatable(o).__index
		m.CreateMaskTexture = m.CreateMaskTexture or function(self, ...) local tx = self:CreateTexture(...) if tx then tx.SetMaskTexture = function() end end return tx end
		m.AddMaskTexture = m.AddMaskTexture or function(s, m) return m end
		m.SetClipsChildren = m.SetClipsChildren or function() end
		m.SetIgnoreParentScale = m.SetIgnoreParentScale or function() end
		m.SetPropagateMouseClicks = m.SetPropagateMouseClicks or function() end
		m.SetReverseFill = m.SetReverseFill or function() end
		m.GetReverseFill = m.GetReverseFill or function() return false end
	end
	
	for _, w in ipairs({"Frame","Button","CheckButton","Slider","StatusBar","ScrollFrame","MessageFrame"}) do pcall(AddFramePolyfills, w) end

	local fs = UIParent:CreateFontString()
	getmetatable(fs).__index.GetUnboundedStringWidth = getmetatable(fs).__index.GetUnboundedStringWidth or getmetatable(fs).__index.GetStringWidth

	local sl = CreateFrame("Slider", nil, UIParent)
	getmetatable(sl).__index.SetObeyStepOnDrag = getmetatable(sl).__index.SetObeyStepOnDrag or function() end
	getmetatable(sl).__index.SetStepsPerPage = getmetatable(sl).__index.SetStepsPerPage or function() end

	if not C_Texture then C_Texture = {GetAtlasInfo = function() return nil end} end
	if not DeathRecap_LoadUI then DeathRecap_LoadUI = function() end end
end
