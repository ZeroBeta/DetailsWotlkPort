-- Animation API compatibility for WotLK 3.3.5a
-- In 3.3.5a, Alpha animations use SetChange() instead of SetFromAlpha()/SetToAlpha()

-- print("|cFFFF0000Details! Animation.lua is loading!|r")

-- Store original CreateAnimationGroup
-- Hook CreateAnimationGroup to add compatibility when creating Alpha animations
local function HookCreateAnimationGroup(objectType)
    local obj = CreateFrame(objectType)
    local mt = getmetatable(obj).__index
    
    -- print("Hooking CreateAnimationGroup for " .. objectType)
    
    if mt.CreateAnimationGroup and not mt.IsCreateAnimationGroupHooked then
        -- print("  - Found CreateAnimationGroup, hooking...")
        local OriginalCreateAnimationGroup = mt.CreateAnimationGroup
        
        mt.CreateAnimationGroup = function(self, ...)
            -- print("  - Hooked CreateAnimationGroup called for " .. self:GetObjectType())
            local animGroup = OriginalCreateAnimationGroup(self, ...)
            
            -- Store original CreateAnimation
            local OriginalCreateAnimation = animGroup.CreateAnimation
            
            -- Override CreateAnimation for this group
            animGroup.CreateAnimation = function(animGroupSelf, animationType, ...)
                -- print("  - Hooked CreateAnimation called: " .. tostring(animationType))
                local animation = OriginalCreateAnimation(animGroupSelf, animationType, ...)
                local upperType = string.upper(animationType)
                
                -- Add polyfills for Alpha animations
                if upperType == "ALPHA" and animation and not animation.SetFromAlpha then
                    -- print("    - Adding SetFromAlpha polyfill")
                    animation.fromAlpha = 0
                    animation.toAlpha = 1
                    
                    animation.SetFromAlpha = function(self, alpha)
                        self.fromAlpha = alpha
                        if self.toAlpha then
                            self:SetChange(self.toAlpha - alpha)
                        end
                    end
                    
                    animation.SetToAlpha = function(self, alpha)
                        self.toAlpha = alpha
                        if self.fromAlpha then
                            self:SetChange(alpha - self.fromAlpha)
                        else
                            self:SetChange(alpha)
                        end
                    end
                end
                
                -- Add polyfills for Scale animations
                if upperType == "SCALE" and animation and not animation.SetFromScale then
                    -- print("    - Adding SetFromScale polyfill")
                    animation.fromScaleX = 1
                    animation.fromScaleY = 1
                    animation.toScaleX = 1
                    animation.toScaleY = 1
                    
                    animation.SetFromScale = function(self, x, y)
                        self.fromScaleX = x
                        self.fromScaleY = y or x
                        if self.toScaleX and self.toScaleY then
                            self:SetScale(self.toScaleX, self.toScaleY)
                        end
                    end
                    
                    animation.SetToScale = function(self, x, y)
                        self.toScaleX = x
                        self.toScaleY = y or x
                        self:SetScale(x, y or x)
                    end
                end
                
                return animation
            end
            
            return animGroup
        end
        
        mt.IsCreateAnimationGroupHooked = true
    end
end

-- Apply to common widget types
local widgetTypes = {"Frame", "Button", "CheckButton", "Slider", "StatusBar", "ScrollFrame", "MessageFrame"}
for _, widgetType in ipairs(widgetTypes) do
    pcall(HookCreateAnimationGroup, widgetType)
end

-- CreateMaskTexture polyfill for 3.3.5a
-- In 3.3.5a, CreateMaskTexture doesn't exist
-- This is now handled by AddPolyfillsToMetatable below

-- Get texture metatable to add methods
local dummyTexture = UIParent:CreateTexture()
local TextureMetatable = getmetatable(dummyTexture).__index

-- AddMaskTexture polyfill for textures
if not TextureMetatable.AddMaskTexture then
    TextureMetatable.AddMaskTexture = function(self, maskTexture)
        -- No-op in 3.3.5a - masking not fully supported
        return maskTexture
    end
end

-- SetScale polyfill for textures (they don't have this in 3.3.5a)
if not TextureMetatable.SetScale then
    TextureMetatable.SetScale = function(self, scale)
        -- Textures don't support SetScale in 3.3.5a
        -- This is a no-op for compatibility
    end
end

if not TextureMetatable.SetTexelSnappingBias then
    TextureMetatable.SetTexelSnappingBias = function(self, bias)
        -- No-op in 3.3.5a
    end
end

if not TextureMetatable.SetSnapToPixelGrid then
    TextureMetatable.SetSnapToPixelGrid = function(self, snap)
        -- No-op in 3.3.5a
    end
end

-- AddMaskTexture polyfill for frames (calls on frame should also work)
local function AddPolyfillsToMetatable(objectType)
    local obj = CreateFrame(objectType)
    local mt = getmetatable(obj).__index
    
    if not mt.CreateMaskTexture then
        mt.CreateMaskTexture = function(self, ...)
            local texture = self:CreateTexture(...)
            if texture then
                texture.SetMaskTexture = texture.SetMaskTexture or function() end
                -- masks are unsupported in 3.3.5a, keep any faux mask fully hidden
                local function hideMask()
                    texture:SetColorTexture(1, 1, 1, 0)
                    texture:Hide()
                end
                texture.SetTexture = function() hideMask() end
                texture.Show = function() hideMask() end
                hideMask()
            end
            return texture
        end
    end
    
    if not mt.AddMaskTexture then
        mt.AddMaskTexture = function(self, maskTexture)
            if maskTexture and maskTexture.Hide then
                maskTexture:Hide()
            end
            return maskTexture
        end
    end

    if not mt.SetClipsChildren then
        mt.SetClipsChildren = function(self, clips)
            -- No-op in 3.3.5a
        end
    end
end

-- FontString polyfills
local fs = UIParent:CreateFontString()
local fsMt = getmetatable(fs).__index
if not fsMt.GetUnboundedStringWidth then
    fsMt.GetUnboundedStringWidth = fsMt.GetStringWidth
end

-- Apply to common widget types
local widgetTypes = {"Frame", "Button", "CheckButton", "Slider", "StatusBar", "ScrollFrame", "MessageFrame"}
for _, widgetType in ipairs(widgetTypes) do
    pcall(AddPolyfillsToMetatable, widgetType)
end

-- C_Texture polyfill
if not C_Texture then
    C_Texture = {}
    -- GetAtlasInfo is used to check if a texture string is an atlas
    C_Texture.GetAtlasInfo = function(atlas)
        -- In 3.3.5a, we don't have atlas support, return nil
        return nil
    end
end

-- Slider polyfills
local dummySlider = CreateFrame("Slider", nil, UIParent)
local SliderMetatable = getmetatable(dummySlider).__index

if not SliderMetatable.SetObeyStepOnDrag then
    SliderMetatable.SetObeyStepOnDrag = function(self, obey)
        -- In 3.3.5a, sliders always obey step on drag
        -- This is a no-op for compatibility
    end
end

-- DeathRecap_LoadUI polyfill - this function doesn't exist in 3.3.5a
if not DeathRecap_LoadUI then
    DeathRecap_LoadUI = function()
        -- No-op in 3.3.5a
    end
end
