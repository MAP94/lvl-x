AddEventListener("OnNetData", "NetData")
AddEventListener("OnAmmoRender", "AmmoRender")
AddEventListener("OnHealthRender", "HealthRender")
AddEventListener("OnArmorRender", "ArmorRender")


function HealthRender()
    Health = GetLocalCharacterHealth()
    if (Health == nil) then
        Health = 0
    end
    RenderSprite(UiGetGameTextureID(), 10, 10, 10, 14)
    UiDirectLabel(10, 20, Health, 0, 8)
    return true
end

function ArmorRender()
    Armor = GetLocalCharacterArmor()
    if (Armor == nil) then
        Armor = 0
    end
    RenderSprite(UiGetGameTextureID(), 12, 30, 10, 14)
    UiDirectLabel(30, 20, Armor, 0, 8)
    return true
end

function AmmoRender()
    Ammo = GetLocalCharacterWeaponAmmo()
    if (Ammo == nil) then
        Ammo = 0
    end
    if (GetLocalCharacterWeapon() == 0) then
        RenderSprite(UiGetGameTextureID(), 41, 50, 10, 14)
    end
    if (GetLocalCharacterWeapon() == 1) then
        RenderSprite(UiGetGameTextureID(), 28, 50, 10, 14)
    end
    if (GetLocalCharacterWeapon() == 2) then
        RenderSprite(UiGetGameTextureID(), 34, 50, 10, 14)
    end
    if (GetLocalCharacterWeapon() == 3) then
        RenderSprite(UiGetGameTextureID(), 40, 50, 10, 14)
    end
    if (GetLocalCharacterWeapon() == 4) then
        RenderSprite(UiGetGameTextureID(), 49, 50, 10, 14)
    end
    if (GetLocalCharacterWeapon() == 5) then
        RenderSprite(UiGetGameTextureID(), 44, 50, 10, 14)
    end
    UiDirectLabel(50, 20, Ammo, 0, 8)
    return true
end

function NetData(Data)

end

function Tick()

end

