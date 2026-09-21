-- wOS.DynaBase:RegisterSource({
--     Name = "ZCity | NPC Animations",
--     Type = WOS_DYNABASE.EXTENSION,

--     -- model paths per gender:
--     Shared = "models/humans/male_shared.mdl",      -- default or neutral model
--     Female = "models/humans/female_shared.mdl",    -- female-specific model (optional)
--     Male   = "models/humans/male_shared.mdl"     -- optional if you have a male version
-- })

-- wOS.DynaBase:RegisterSource({
--     Name = "ZCity | NPC Gestures",
--     Type = WOS_DYNABASE.EXTENSION,

--     -- model paths per gender:
--     Shared = "models/humans/male_gestures.mdl",      -- default or neutral model
--     Female = "models/humans/female_gestures.mdl",    -- female-specific model (optional)
--     Male   = "models/humans/male_gestures.mdl"     -- optional if you have a male version
-- })

-- wOS.DynaBase:RegisterSource({
--     Name = "ZCity | NPC Postures",
--     Type = WOS_DYNABASE.EXTENSION,

--     -- model paths per gender:
--     Shared = "models/humans/male_postures.mdl",      -- default or neutral model
--     Female = "models/humans/female_postures.mdl",    -- female-specific model (optional)
--     Male   = "models/humans/male_postures.mdl"     -- optional if you have a male version
-- })

-- hook.Add("PreLoadAnimations", "wOS.DynaBase.MountNPCAnims", function(gender)
--     if gender == WOS_DYNABASE.SHARED then
--         IncludeModel("models/humans/male_gestures.mdl")
--         IncludeModel("models/humans/male_postures.mdl")
--         -- IncludeModel("models/humans/male_shared.mdl")
--     elseif gender == WOS_DYNABASE.FEMALE then
--         IncludeModel("models/humans/female_gestures.mdl")
--         IncludeModel("models/humans/female_postures.mdl")
--         -- IncludeModel("models/humans/female_shared.mdl")
--     elseif gender == WOS_DYNABASE.MALE then
--         IncludeModel("models/humans/male_gestures.mdl")
--         IncludeModel("models/humans/male_postures.mdl")
--         -- IncludeModel("models/humans/male_shared.mdl")
--     end
-- end)
