-- Polyfill for C_Timer
if not C_Timer then
    C_Timer = {}
end

local TickerPrototype = {}
local TickerMetatable = {
    __index = TickerPrototype,
    __metatable = true
}

function TickerPrototype:Cancel()
    self._cancelled = true
end

function TickerPrototype:IsCancelled()
    return self._cancelled
end

function C_Timer.After(duration, callback)
    local timer = CreateFrame("Frame")
    timer:Hide()
    timer:SetScript("OnUpdate", function(self, elapsed)
        self.time = (self.time or 0) + elapsed
        if self.time >= duration then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            if callback then callback() end
        end
    end)
    timer:Show()
end

function C_Timer.NewTicker(duration, callback, iterations)
    local ticker = setmetatable({}, TickerMetatable)
    ticker._cancelled = false
    
    local currentIterations = 0
    local timer = CreateFrame("Frame")
    timer:Hide()
    timer:SetScript("OnUpdate", function(self, elapsed)
        if ticker:IsCancelled() then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end

        self.time = (self.time or 0) + elapsed
        if self.time >= duration then
            self.time = self.time - duration
            currentIterations = currentIterations + 1
            if callback then callback(ticker) end
            
            if iterations and currentIterations >= iterations then
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        end
    end)
    timer:Show()
    return ticker
end

function C_Timer.NewTimer(duration, callback)
    -- print("C_Timer.NewTimer called")
    local ticker = setmetatable({}, TickerMetatable)
    ticker._cancelled = false
    
    local timer = CreateFrame("Frame")
    timer:Hide()
   timer:SetScript("OnUpdate", function(self, elapsed)
        if ticker:IsCancelled() then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end
        
        self.time = (self.time or 0) + elapsed
        if self.time >= duration then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            if callback then callback(ticker) end
        end
    end)
    timer:Show()
    return ticker
end

-- Animation/UI Polyfills (added here since Animation.lua doesn't load)
do
	-- Instead of hooking CreateAnimationGroup, directly patch the Animation metatable
	local testFrame = CreateFrame("Frame")
	local testAnimGroup = testFrame:CreateAnimationGroup()
	local testAnim = testAnimGroup:CreateAnimation("Alpha")
	local animMt = getmetatable(testAnim).__index
	
	-- Add SetFromAlpha/SetToAlpha if missing
	if not animMt.SetFromAlpha then
		animMt.SetFromAlpha = function(self, alpha)
			self.fromAlpha = alpha
			if self.toAlpha then
				self:SetChange(self.toAlpha - alpha)
			end
		end
	end
	
	if not animMt.SetToAlpha then
		animMt.SetToAlpha = function(self, alpha)
			self.toAlpha = alpha
			local from = self.fromAlpha or 0
			self:SetChange(alpha - from)
		end
	end
	
	-- Add SetFromScale/SetToScale for Scale animations
	if not animMt.SetFromScale then
		animMt.SetFromScale = function(self, x, y)
			self.fromScaleX = x
			self.fromScaleY = y or x
			if self.toScaleX and self.toScaleY then
				self:SetScale(self.toScaleX, self.toScaleY)
			end
		end
	end
	
	if not animMt.SetToScale then
		animMt.SetToScale = function(self, x, y)
			self.toScaleX = x
			self.toScaleY = y or x
			self:SetScale(x, y or x)
		end
	end
	
	-- Texture polyfills
	local t = UIParent:CreateTexture()
	local tm = getmetatable(t).__index
	tm.AddMaskTexture = tm.AddMaskTexture or function(s, m) return m end
	tm.SetScale = tm.SetScale or function() end
	tm.SetTexelSnappingBias = tm.SetTexelSnappingBias or function() end
	tm.SetSnapToPixelGrid = tm.SetSnapToPixelGrid or function() end
	
	-- Shared helper for AdjustPointsOffset (retail API)
	local function AdjustPointsOffset(self, dx, dy)
		dx = dx or 0
		dy = dy or 0

		local numPoints = self.GetNumPoints and self:GetNumPoints() or 0
		if numPoints == 0 then
			return
		end

		local points = {}
		for i = 1, numPoints do
			local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(i)
			points[#points+1] = {point, relativeTo, relativePoint, offsetX or 0, offsetY or 0}
		end

		self:ClearAllPoints()
		for i = 1, #points do
			local p = points[i]
			self:SetPoint(p[1], p[2], p[3], p[4] + dx, p[5] + dy)
		end
	end

	-- Frame polyfills
	local function AddFramePolyfills(ot)
		local ok, o = pcall(CreateFrame, ot)
		if not ok then return end
		local m = getmetatable(o).__index
		m.CreateMaskTexture = m.CreateMaskTexture or function(self, ...) local tx = self:CreateTexture(...) if tx then tx.SetMaskTexture = function() end end return tx end
		m.AddMaskTexture = m.AddMaskTexture or function(s, m) return m end
		m.SetClipsChildren = m.SetClipsChildren or function() end
		m.SetIgnoreParentScale = m.SetIgnoreParentScale or function() end
		m.AdjustPointsOffset = m.AdjustPointsOffset or AdjustPointsOffset
		m.SetPropagateMouseClicks = m.SetPropagateMouseClicks or function() end
		m.SetReverseFill = m.SetReverseFill or function() end
		m.GetReverseFill = m.GetReverseFill or function() return false end
	end
	
	local widgetTypes = {"Frame","Button","CheckButton","Slider","StatusBar","ScrollFrame","MessageFrame"}
	for _, w in ipairs(widgetTypes) do pcall(AddFramePolyfills, w) end
	
	-- FontString polyfills
	local fs = UIParent:CreateFontString()
	local fsMt = getmetatable(fs).__index
	fsMt.GetUnboundedStringWidth = fsMt.GetUnboundedStringWidth or fsMt.GetStringWidth
	fsMt.AdjustPointsOffset = fsMt.AdjustPointsOffset or AdjustPointsOffset
	
	-- Slider polyfills
	local sl = CreateFrame("Slider", nil, UIParent)
	getmetatable(sl).__index.SetObeyStepOnDrag = getmetatable(sl).__index.SetObeyStepOnDrag or function() end
	getmetatable(sl).__index.SetStepsPerPage = getmetatable(sl).__index.SetStepsPerPage or function() end
	
	-- Global polyfills
	if not C_Texture then C_Texture = {GetAtlasInfo = function() return nil end} end
	if not DeathRecap_LoadUI then DeathRecap_LoadUI = function() end end
end
