invulnerable_modifier = class({})

function invulnerable_modifier:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
    return funcs
end

function invulnerable_modifier:GetModifierIncomingDamage_Percentage(params)
    return -100
end