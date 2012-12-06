Queries = {}
Accounts = {}
Names = {}
Mines = {}

SvMaxWarnings = 0
Affected = 1
Instagib = 0
Coop = 0

LuaDir = "lua/client/"
DownloadFlagNoCrc = 2
DownloadFlagLaunch = 4
DownloadFlagCheck = 16
DownloadFlagUpdate = 32

--[[
CREATE TABLE IF NOT EXISTS `users` (
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(32) COLLATE utf8_bin NOT NULL,
  `password` varchar(32) COLLATE utf8_bin NOT NULL,
  `Kills` bigint(20) NOT NULL DEFAULT '0',
  `Deaths` bigint(20) NOT NULL DEFAULT '0',
  `Level` int(11) NOT NULL DEFAULT '1',
  `Exp` int(11) NOT NULL DEFAULT '0',
  `_Str` int(11) NOT NULL DEFAULT '1',
  `_Sta` int(11) NOT NULL DEFAULT '1',
  `_Dex` int(11) NOT NULL DEFAULT '1',
  `_Int` int(11) NOT NULL DEFAULT '1',
  `Weapon` int(11) NOT NULL DEFAULT '0',
  `Points` int(11) NOT NULL DEFAULT '0',
  `last_logged_in` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `register_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastip` varchar(32) COLLATE utf8_bin NOT NULL DEFAULT '',
  `LastName` varchar(32) COLLATE utf8_bin NOT NULL DEFAULT '',
  `Warnings` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_bin AUTO_INCREMENT=1;
--]]

MySQLConnect("localhost", "root", "", "lvlmod")

AddEventListener("OnMySQLResults", "OnData")
AddEventListener("OnDie", "Kill")
AddEventListener("OnClientConnect", "ClientConnect")
AddEventListener("OnClientEnter", "ClientEnter")
AddEventListener("OnChat", "Chat")
AddEventListener("OnWeaponFire", "OnFire")
AddEventListener("OnReloadTimer", "OnReload")
AddEventListener("OnIncreaseHealth", "OnHealth")
AddEventListener("OnIncreaseArmor", "OnArmor")
AddEventListener("OnTakeDamage", "OnDamage")
AddEventListener("OnCharacterSpawn", "OnSpawn")
AddEventListener("OnEntity", "OnEntity")
AddEventListener("OnPlayerJoinTeam", "PlayerJoinTeam")
AddEventListener("OnAmmoRegen", "AmmoRegen")
AddEventListener("OnAmmoRegenTime", "AmmoRegenTime")
AddEventListener("OnGiveWeapon", "GiveWeapon")
AddEventListener("OnChangeName", "ChangeName")
AddEventListener("OnProjectileDestroy", "ProjectileDestroy")

SetGametype("Lvl|aDM")

AddModFile(LuaDir .. "client.lua", "client", 1, DownloadFlagNoCrc + DownloadFlagLaunch + DownloadFlagUpdate)

function clamp(val, min, max)
    if (val < min) then
        return min
    end
    if (val > max) then
        return max
    end
    return val
end

function max(x, y)
    if (x < y) then
        return y
    end
    return x
end

function min(x, y)
    if (x > y) then
        return y
    end
    return x
end

function AccountReset(ClientID)
    Accounts[ClientID] = {}
    Accounts[ClientID]["Level"] = 1
    Accounts[ClientID]["Kills"] = 0
    Accounts[ClientID]["Deaths"] = 0
    Accounts[ClientID]["Killstreak"] = 0
    Accounts[ClientID]["Weapon"] = 0
	Accounts[ClientID]["_Str"] = 1
	Accounts[ClientID]["_Sta"] = 1
	Accounts[ClientID]["_Dex"] = 1
	Accounts[ClientID]["_Int"] = 1
    CalcStats(ClientID)
end

function ClientConnect(ClientID)
    AccountReset(ClientID)
end

function ClientEnter(ClientID)
    Names[ClientID] = GetPlayerName(ClientID)
    SetPlayerName(ClientID, "[NOT LOGGED IN]")
    SetPlayerTeam(ClientID, -1)
end

function PlayerJoinTeam(ClientID, Team)
    if (Accounts[ClientID]["uid"] or Team == -1) then
        return
    end
    SendChatTarget(ClientID, "You are not logged in!")
    return true
end

function GetAngle(x, y)
	if(x == 0 and y == 0) then
		return 0
    end
	a = math.atan(y / x)
	if(x < 0) then
		a = a + math.pi
    end
	return a
end

iTick = 0
function Tick(Time, ServerTick)
    iTick = iTick + 1

    --[[l = NetAccept(ListenSocket)
    Print("status", NetGetStatus(ListenSocket))
    if (l ~= -1) then
        Print("s", l)
    end]]
end
function TickDefered(Time, ServerTick)

end
function PostTick(Time, ServerTick)

end

function ChangeName(ClientID, Name)
    OldName = Names[ClientID]
    Names[ClientID] = Name

    ChatSendTarget(-1, "'" .. OldName .. "' changed name to '" .. Name .. "'")

    if (Accounts[ClientID]["Level"] == -2) then
        Name = "[CC]" .. Name
    elseif (Accounts[ClientID]["Level"] == -1) then
        Name = "[Admin]" .. Name
    elseif (Accounts[ClientID]["uid"] == nil or Accounts[ClientID]["uid"] == 0) then
        Name = "[NOT LOGGED IN]"
    else
        Name = "[" .. Accounts[ClientID]["Level"] .. "]" .. Name
    end

    return Name, 1
end

function mix(a, b, c)
     return a + (b - a) * c
end

function Distance(x1, y1, x2, y2)
    local x = (x1 - x2)
    local y = (y1 - y2)
    return math.sqrt(x * x + y * y)
end

---------------------------------Char stuff-------------------------

function OnReload(ClientID, ReloadTimer)
    if (Affected == 1) then
        return math.floor((ReloadTimer * 100 / Accounts[ClientID]["Reload"]))
    end
end

function OnFire(ClientID, Weapon, DirX, DirY)
    Abort = false
    NoProjectiles = false
    if (Accounts[ClientID]["Level"] == -2) then
        return false
    end
    if (Weapon == 0) then
        FullAutomatic = Accounts[ClientID]["HammerAuto"]
    elseif (Weapon == 1) then
        FullAutomatic = Accounts[ClientID]["GunAuto"]
    else
        FullAutomatic = true
    end

    x, y = GetCharacterPos(ClientID)
    if (x == nil and y == nil) then
        return nil
    else
        StartPosX = x + DirX * 28 * 0.75
        StartPosY = y + DirY * 28 * 0.75
    end

    if (Weapon == 0 and Accounts[ClientID]["HammerTriple"] == true and CharacterGetAmmo(ClientID, 0) ~= 0) then
        CreateSound(StartPosX, StartPosY, 3)
        IDS = EntityFind(StartPosX, StartPosY, 14, 127, 4)
        for ik, iv in pairs(IDS) do
            VictimID = EntityGetCharacterId(iv)
            if (VictimID ~= ClientID) then
                CreateHammerHit(StartPosX, StartPosY)
                if (CharacterIsAlive(VictimID)) then
                    CharacterTakeDamage(VictimID, 300, ClientID, 0, 0, -1)
                end
                if (CharacterIsAlive(VictimID)) then
                    CharacterTakeDamage(VictimID, 3, ClientID, 0, 0, -1)
                end
            end
        end
    end
    if (Weapon == 1 and Accounts[ClientID]["GunDual"] == true and CharacterGetAmmo(ClientID, 1) ~= 0) then
        a = GetAngle(DirX, DirY)
        a = a + 0.05
        ProjectileCreate(StartPosX, StartPosY, math.cos(a), math.sin(a), ClientID, GetTickSpeed() * GetTuning("Gun_Lifetime"), 1, 1, 0, false, -1)
    end
    if (Weapon == 2 and CharacterGetAmmo(ClientID, 2) ~= 0) then
        ShotSpread = math.floor(2 * Accounts[ClientID]["ShotgunShots"] / 100)
        for i = -ShotSpread, ShotSpread do
            a = GetAngle(DirX, DirY)
            a = a + i * 0.070
            v = 1 - (math.abs(i) / ShotSpread)
            Speed = mix(GetTuning("Shotgun_Speeddiff"), 1, v)
            ProjectileCreate(StartPosX, StartPosY, math.cos(a) * Speed, math.sin(a) * Speed, ClientID, GetTickSpeed() * GetTuning("Shotgun_Lifetime") * (Accounts[ClientID]["ShotgunDist"] / 100), 2, 1, 0, false, -1)
        end
        NoProjectiles = true
    end

    return Abort, FullAutomatic, DisableSound, nil, NoProjectiles
end

function OnHealth(ClientID, Amount, Max)
    if (Accounts[ClientID]["Defense"] and Affected == 1) then
        Max = math.floor(10 * (Accounts[ClientID]["Defense"] / 100))
        return Amount, Max
    end
end

function OnArmor(ClientID, Amount, Max)
    if (Accounts[ClientID]["Defense"] and Affected == 1) then
        Max = math.floor(10 * (Accounts[ClientID]["Defense"] / 100))
        return Amount, Max
    end
end

function OnDamage(ClientID, From, Weapon, Damage, ForceX, ForceY)
    if (Instagib == 1) then
        CharacterKill(ClientID, Weapon, From)
        return true --no damage
    end
    if (IsTeamplay() and Instagib == 0 and Affected == 1 and ((Coop == 0 and GetPlayerTeam(ClientID) == GetPlayerTeam(From)) or (Coop == 1 and Partner == Partner))) then
        if (Weapon == 0 and Accounts[id]["HammerHeal"] > 0) then
            CharacterIncreaseHealth(ClientID, Accounts[id]["HammerHeal"])
            CharacterIncreaseArmor(ClientID, Accounts[id]["HammerHeal"] / 3)
        end
        if (Weapon == 4 and Accounts[id]["RifleHeal"] > 0) then
            CharacterIncreaseHealth(ClientID, Accounts[id]["RifleHeal"])
            CharacterIncreaseArmor(ClientID, Accounts[id]["RifleHeal"] / 3)
        end
    end
    Damage = math.floor(Damage * Accounts[From]["Attack"] / 100)
    Damage = clamp(math.floor(Damage / (Accounts[ClientID]["Defense"] / 100)), 1, 10)

    return nil, Weapon, Damage, ForceX, ForceY
end

function LCreateExplosion(ClientID, x, y, Weapon, NoDmg, Dmg)
    if (Accounts[ClientID]["GrenadeExplosions"] == 1) then
        CreateExplosion(x, y, ClientID, Weapon, false, 6)
    end
    if (Accounts[ClientID]["GrenadeExplosions"] == 2) then
        CreateExplosion(x + Accounts[ClientID]["GrenadeSpread"] / 7, y, ClientID, Weapon, false, 6)
        CreateExplosion(x - Accounts[ClientID]["GrenadeSpread"] / 7, y, ClientID, Weapon, false, 3)
    end
    if (Accounts[ClientID]["GrenadeExplosions"] == 3) then
        CreateExplosion(x + Accounts[ClientID]["GrenadeSpread"] / 7, y + Accounts[ClientID]["GrenadeSpread"] / 7, ClientID, Weapon, false, 6)
        CreateExplosion(x, y - Accounts[ClientID]["GrenadeSpread"] / 7, ClientID, Weapon, false, 3)
        CreateExplosion(x - Accounts[ClientID]["GrenadeSpread"] / 7, y + Accounts[ClientID]["GrenadeSpread"] / 7, ClientID, Weapon, false, 3)
    end
end

function ProjectileDestroy(ClientID, Weapon, x, y, StartTick, DirX, DirY, HitClientID, Collide, ID)
    if (Weapon == 3) then
        if (Collide and HitClientID == -1) then
            NewMine = false
            if (Mines[ID] == nil) then
                NewMine = true
                Mines[ID] = GetTick()
            end
            if (GetTickSpeed() * Accounts[ClientID]["GrenadeMine"] / 2 - (GetTick() - Mines[ID]) > 0) then
                PrevPosX, PrevPosY = ProjectileGetPos(ID, -1)
                ProjectileSetStartPos(ID, PrevPosX, PrevPosY)
                ProjectileSetStartTick(ID, GetTick())
                ProjectileSetDir(ID, 0, 0)
                ProjectileSetLifespan(ID, GetTickSpeed() * Accounts[ClientID]["GrenadeMine"] / 2 - (GetTick() - Mines[ID]))
                IDS = EntityFind(x, y, 96, 127, 4)
                for ik, iv in pairs(IDS) do
                    VictimID = EntityGetCharacterId(iv)
                    if (VictimID ~= ClientID) then
                        vx, vy = GetCharacterPos(VictimID)
                        if (Distance(vx, vy, x, y) <= 40) then
                            LCreateExplosion(ClientID, x, y, ClientID, Weapon, false, 6)
                            return false
                        end
                    else
                        LCreateExplosion(ClientID, x, y, ClientID, Weapon, false, 6)
                        return false
                    end
                end
                return true, true
            else
                Mines[ID] = nil
                LCreateExplosion(ClientID, x, y, ClientID, Weapon, false, 6)
            end
        else
            LCreateExplosion(ClientID, x, y, ClientID, Weapon, false, 6)
        end
    end
    return nil, true
end

function OnSpawn(ClientID)
    if (Instagib == 1) then
        CharacterSetAmmo(ClientID, 0, 0)
        CharacterSetAmmo(ClientID, 1, 0)
        CharacterSetAmmo(ClientID, 2, 0)
        CharacterSetAmmo(ClientID, 3, 0)
        CharacterSetAmmo(ClientID, 4, -1)
        CharacterSetActiveWeapon(ClientID, 4) --rifle ftw
    else
        CharacterIncreaseHealth(ClientID, math.floor(10 * (Accounts[ClientID]["Defense"] / 100)))
        CharacterSetAmmo(ClientID, 0, -1)
        CharacterSetAmmo(ClientID, 1, 10)
        CharacterSetAmmo(ClientID, 2, 0)
        CharacterSetAmmo(ClientID, 3, 0)
        CharacterSetAmmo(ClientID, 4, 0)

        if (Accounts[ClientID]["Weapon"] > 2) then
            CharacterSetAmmo(ClientID, Accounts[ClientID]["Weapon"] - 1, math.floor(Accounts[ClientID]["Ammo"] / 20))
        end
        --pChr->GiveWeapon(pChr->GetPlayer()->Account()->m_Weap-1, (pChr->GetPlayer()->Account()->m_Ammo / 20));

    end
end

function OnEntity(x, y, index)
    if (index and index > 5 and Instagib == 1) then
        return 0
    end
end

function AmmoRegenTime(ClientID, Weapon, Time)
    if (Weapon == 1) then
        return Time / (Accounts[ClientID]["GunAmmoReload"] / 100)
    end
end

function AmmoRegen(ClientID, Weapon, Ammo)
    if (Weapon == 1) then
        return min(math.floor(Ammo + Accounts[ClientID]["Ammo"] / 100), math.floor(Accounts[ClientID]["Ammo"] / 10))
    end
end

function GiveWeapon(ClientID, Weapon, Ammo, CurrentAmmo, Got)
    Ammo = math.floor(Accounts[ClientID]["Ammo"] / 10)
    if(CurrentAmmo < Ammo or Got == 0) then
        return Ammo, nil, true
    end
    return nil, nil, false
end

---------------------------------CHAT CMDS----------------------

function GetParameter(Text, Number)
    for i = 1, Number do
        s = Text:find(" ")
        if (s == nil) then
            return nil
        end
        Text = Text:sub(s + 1)
    end
    s = Text:find(" ")
    if (s ~= nil) then
        s = s - 1
    end
    Text = Text:sub(1, s)
    return Text
end

function Chat(Text, ClientID, Team)
    if (Text:sub(1, 1) == "/") then
        if (Text:sub(1, 9) == "/register") then
            if (Accounts[ClientID]["uid"] ~= nil) then
				SendBroadcast("You are already logged in.", ClientID)
				SendChatTarget(ClientID, "You are already logged in.")
            else
                Username = GetParameter(Text, 1)
                Password = GetParameter(Text, 2)
                if (Username == nil or Password == nil) then
                    SendBroadcast("Please stick to the given structure:\n/register <accountname> <password>", ClientID)
                    SendChatTarget(ClientID, "Please stick to the given structure:")
                    SendChatTarget(ClientID, "/register <accountname> <password>")
                else
                    Register(Username, Password, ClientID)
                end
            end
        elseif (Text:sub(1, 6) == "/login") then
            if (Accounts[ClientID]["uid"] ~= nil) then
				SendBroadcast("You are already logged in.", ClientID)
				SendChatTarget(ClientID, "You are already logged in.")
            else
                Username = GetParameter(Text, 1)
                Password = GetParameter(Text, 2)
                if (Username == nil or Password == nil) then
                    SendBroadcast("Please stick to the given structure:\n/login <accountname> <password>", ClientID)
                    SendChatTarget(ClientID, "Please stick to the given structure:")
                    SendChatTarget(ClientID, "/login <accountname> <password>")
                else
                    if (Login(Username, Password, ClientID) == false) then
                        SendChatTarget(ClientID, "An error occured. Try again later")
                    end
                end
            end
        elseif (Text:sub(1, 7) == "/logout") then
            if (Accounts[ClientID]["uid"] == nil) then
				SendBroadcast("You aren't logged in.", ClientID)
				SendChatTarget(ClientID, "You aren't logged in.")
            else
				SendBroadcast("Logout successful! See you, " .. Accounts[ClientID]["username"] .."!", ClientID);
				SendChatTarget(ClientID, "Logout successful! See you, " .. Accounts[ClientID]["username"] .."!");
                Update(ClientID)
                AccountReset(ClientID)
                SendAccountData(ClientID)
                SendChatTarget(ClientID, "You are now logged out.")
                SetPlayerTeam(ClientID, -1)
            end
        elseif (Text:sub(1, 11) == "/playerinfo") then
            if (Accounts[ClientID]["uid"] == nil) then
                SendBroadcast("You aren't logged in.", ClientID)
				SendChatTarget(ClientID, "You aren't logged in.")
            else
                SendChatTarget(ClientID, "Level: " .. Accounts[ClientID]["Level"] .. " | Exp: " .. math.floor(Accounts[ClientID]["Exp"] * 100 / Accounts[ClientID]["ExpNeeded"]) .. "%")
                SendChatTarget(ClientID, "Str: " .. Accounts[ClientID]["_Str"] .. " | Sta: " .. Accounts[ClientID]["_Sta"] .. " | Dex: " .. Accounts[ClientID]["_Dex"] .. " | Int: " .. Accounts[ClientID]["_Int"])
                Weapon = "Nothing"
                if (Accounts[ClientID]["Weapon"] == 1) then
                    Weapon = "HAMMER"
                elseif (Accounts[ClientID]["Weapon"] == 2) then
                    Weapon = "GUN"
                elseif (Accounts[ClientID]["Weapon"] == 3) then
                    Weapon = "SHOTGUN"
                elseif (Accounts[ClientID]["Weapon"] == 4) then
                    Weapon = "GRENADE LAUNCHER"
                elseif (Accounts[ClientID]["Weapon"] == 5) then
                    Weapon = "LASER RIFLE"
                end
                SendChatTarget(ClientID, "Stat points: " .. Accounts[ClientID]["Points"] .. " | Specialized on: " .. Weapon)
                if (Affected) then
                    SendChatTarget(ClientID, "Attack: " .. Accounts[ClientID]["Attack"] .. "% | Defense: " .. Accounts[ClientID]["Defense"] .. "%")
                    SendChatTarget(ClientID, "Reload: " .. Accounts[ClientID]["Reload"] .. "% | Ammo: " .. Accounts[ClientID]["Ammo"] .. "%")
                    SendChatTarget(ClientID, "Warnings: " .. Accounts[ClientID]["Warnings"] .. " (allowed: " .. SvMaxWarnings .. ")")

                else
                    SendChatTarget(ClientID, "Non level-affected server.")
                end
            end

        elseif (Text:sub(1, 7) == "/weapon") then
            if (Accounts[ClientID]["uid"] == nil) then
				SendBroadcast("You aren't logged in.", ClientID)
				SendChatTarget(ClientID, "You aren't logged in.")
            else
                if (Accounts[ClientID]["Level"] < 20) then
                    SendBroadcast("You need to be at least level 20.", ClientID)
                    SendChatTarget(ClientID, "You need to be at least level 20.")
                else
                    if (Accounts[ClientID]["Weapon"] > 0) then
                        SendBroadcast("You already chose a weapon.", ClientID);
                        SendChatTarget(ClientID, "You already chose a weapon.");
                    else
                        if (Text == "/weapon hammer") then
                            Accounts[ClientID]["Weapon"] = 1
                        elseif (Text == "/weapon gun") then
                            Accounts[ClientID]["Weapon"] = 2
                        elseif (Text == "/weapon shotgun") then
                            Accounts[ClientID]["Weapon"] = 3
                        elseif (Text == "/weapon grenade") then
                            Accounts[ClientID]["Weapon"] = 4
                        elseif (Text == "/weapon rifle") then
                            Accounts[ClientID]["Weapon"] = 5
                        else
                            SendBroadcast("Please use: /weapon <hammer|gun|shotgun|grenade|rifle>", ClientID)
                            SendChatTarget(ClientID, "Please use: /weapon <hammer|gun|shotgun|grenade|rifle>")
                        end
                        CalcStats(ClientID)
                        if (Accounts[ClientID]["Weapon"] > 0) then
                            if (Accounts[ClientID]["Weapon"] == 1) then
                                txt = "Successfully specialized on the HAMMER!"
                            end
                            if (Accounts[ClientID]["Weapon"] == 2) then
                                txt = "Successfully specialized on the GUN!"
                            end
                            if (Accounts[ClientID]["Weapon"] == 3) then
                                txt = "Successfully specialized on the SHOTGUN!"
                            end
                            if (Accounts[ClientID]["Weapon"] == 4) then
                                txt = "Successfully specialized on the GRENADE LAUNCHER!"
                            end
                            if (Accounts[ClientID]["Weapon"] == 5) then
                                txt = "Successfully specialized on the LASER RIFLE!"
                            end
                            SendBroadcast(txt, ClientID)
                            SendChatTarget(ClientID, txt)
                        end
                    end
                end
            end
        elseif (Text:sub(1, 5) == "/stat") then
            if (Accounts[ClientID]["uid"] == nil) then
				SendBroadcast("You aren't logged in.", ClientID)
				SendChatTarget(ClientID, "You aren't logged in.")
            else
                Type = GetParameter(Text, 1)
                Amount = tonumber(GetParameter(Text, 2)) or 1
                Amount = max(Amount, 1)

                if (Type == nil) then
                    SendBroadcast("Please use: /stat <str|sta|dex|int> <Amount>", ClientID)
                    SendChatTarget(ClientID, "Please use: /stat <str|sta|dex|int> <Amount>")
                elseif (Amount > Accounts[ClientID]["Points"]) then
                    SendBroadcast("Not enough stat points.", ClientID)
                    SendChatTarget(ClientID, "Not enough stat points.")
                else
                    if (Type:lower() == "str") then
                        if (Accounts[ClientID]["_Str"] >= 201) then
                            SendBroadcast("You already maxed STR. (Total: " .. Accounts[ClientID]["_Str"] .. ")", ClientID)
                            SendChatTarget(ClientID, "You already maxed STR. (Total: " .. Accounts[ClientID]["_Str"] .. ")")
                        else
                            if ((Accounts[ClientID]["_Str"] + Amount) > 201) then
                                Amount = Amount - Accounts[ClientID]["_Str"] + Amount - 201
                            end
                            Accounts[ClientID]["_Str"] = Accounts[ClientID]["_Str"] + Amount

                            Accounts[ClientID]["Points"] = Accounts[ClientID]["Points"] - Amount

                            SendBroadcast("Successfully increased STR by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Str"] .. ")", ClientID);
                            SendChatTarget(ClientID, "Successfully increased STR by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Str"] .. ")");

                            Update(ClientID)
                        end
                    end
                    if (Type:lower() == "sta") then
                        if (Accounts[ClientID]["_Sta"] >= 201) then
                            SendBroadcast("You already maxed STA. (Total: " .. Accounts[ClientID]["_Sta"] .. ")", ClientID)
                            SendChatTarget(ClientID, "You already maxed STA. (Total: " .. Accounts[ClientID]["_Sta"] .. ")")
                        else
                            if ((Accounts[ClientID]["_Sta"] + Amount) > 201) then
                                Amount = Amount - Accounts[ClientID]["_Sta"] + Amount - 201
                            end
                            Accounts[ClientID]["_Sta"] = Accounts[ClientID]["_Sta"] + Amount

                            Accounts[ClientID]["Points"] = Accounts[ClientID]["Points"] - Amount

                            SendBroadcast("Successfully increased STA by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Sta"] .. ")", ClientID);
                            SendChatTarget(ClientID, "Successfully increased STA by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Sta"] .. ")");

                            Update(ClientID)
                        end
                    end
                    if (Type:lower() == "int") then
                        if (Accounts[ClientID]["_Int"] >= 201) then
                            SendBroadcast("You already maxed INT. (Total: " .. Accounts[ClientID]["_Int"] .. ")", ClientID)
                            SendChatTarget(ClientID, "You already maxed INT. (Total: " .. Accounts[ClientID]["_Int"] .. ")")
                        else
                            if ((Accounts[ClientID]["_Int"] + Amount) > 201) then
                                Amount = Amount - Accounts[ClientID]["_Int"] + Amount - 201
                            end
                            Accounts[ClientID]["_Int"] = Accounts[ClientID]["_Int"] + Amount

                            Accounts[ClientID]["Points"] = Accounts[ClientID]["Points"] - Amount

                            SendBroadcast("Successfully increased INT by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Int"] .. ")", ClientID);
                            SendChatTarget(ClientID, "Successfully increased INT by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Int"] .. ")");

                            Update(ClientID)
                        end
                    end
                    if (Type:lower() == "dex") then
                        if (Accounts[ClientID]["_Dex"] >= 201) then
                            SendBroadcast("You already maxed DEX. (Total: " .. Accounts[ClientID]["_Dex"] .. ")", ClientID)
                            SendChatTarget(ClientID, "You already maxed DEX. (Total: " .. Accounts[ClientID]["_Dex"] .. ")")
                        else
                            if ((Accounts[ClientID]["_Dex"] + Amount) > 201) then
                                Amount = Amount - Accounts[ClientID]["_Dex"] + Amount - 201
                            end
                            Accounts[ClientID]["_Dex"] = Accounts[ClientID]["_Dex"] + Amount

                            Accounts[ClientID]["Points"] = Accounts[ClientID]["Points"] - Amount

                            SendBroadcast("Successfully increased DEX by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Dex"] .. ")", ClientID);
                            SendChatTarget(ClientID, "Successfully increased DEX by " .. Amount .. ". (Total: " .. Accounts[ClientID]["_Dex"] .. ")");

                            Update(ClientID)
                        end
                    end
                end

                Update(ClientID)
                SendAccountData(ClientID)
            end
        elseif (Text:sub(1, 8) == "/cmdlist") then
			SendChatTarget(ClientID, "/rules | /info")
			SendChatTarget(ClientID, "/register <accountname> <password>")
			SendChatTarget(ClientID, "/login <accountname> <password>")
			SendChatTarget(ClientID, "/password <new password>")
			SendChatTarget(ClientID, "/logout | /playerinfo")
			SendChatTarget(ClientID, "/stat <str|sta|dex|int> <Amount>")
			SendChatTarget(ClientID, "/weapon <hammer|gun|shotgun|grenade|rifle>")
			SendChatTarget(ClientID, "/say <name> <message> | /block <name> | /unblock <name>")
        elseif (Text:sub(1, 5) == "/info" and Text:len() == 5) then
			SendChatTarget(ClientID, "Lvl|x mod 0.5.2 by Tom94.")
			SendChatTarget(ClientID, "Lvl|x port LUA by MAP94.")
			SendChatTarget(ClientID, "Special thanks to Sushi")
			SendChatTarget(ClientID, "Use /cmdlist to get a list of all commands.")
			SendChatTarget(ClientID, "To get more specific help, use:")
			SendChatTarget(ClientID, "/info <level|stats|weapons|rank|top5>")
			SendChatTarget(ClientID, "Please read the rules! /rules")
        elseif (Text:sub(1, 11) == "/info level" and Text:len() == 11) then
            SendChatTarget(ClientID, "You get exp by killing other people.")
			SendChatTarget(ClientID, "As soon as you level up, you will get")
			SendChatTarget(ClientID, "2 Stat points which you can spend on")
			SendChatTarget(ClientID, "stats.")
			SendChatTarget(ClientID, "At level 20, you may choose a weapon")
			SendChatTarget(ClientID, "to specialize on.")
			SendChatTarget(ClientID, "More info at:")
			SendChatTarget(ClientID, "/info <stats|weapons>");
        elseif (Text:sub(1, 11) == "/info stats" and Text:len() == 11) then
			SendChatTarget(ClientID, "Stats affect your fighting values:")
			SendChatTarget(ClientID, "STR -> Attack + Weapon effects")
			SendChatTarget(ClientID, "STA -> Health + Armor + Defense")
			SendChatTarget(ClientID, "DEX -> Reload + Weapon effects")
			SendChatTarget(ClientID, "INT -> Ammo + Weapon effects")
			SendChatTarget(ClientID, "They also affect your weapon's behaviours.")
			SendChatTarget(ClientID, "Use: /stat <str|sta|dex|int> <Amount>.")
			SendChatTarget(ClientID, "More info at:")
			SendChatTarget(ClientID, "/info <level|weapons>")
        elseif (Text:sub(1, 13) == "/info weapons" and Text:len() == 13) then
			SendChatTarget(ClientID, "Weapons get special effects, when a Stat")
			SendChatTarget(ClientID, "reaches a certain breakpoint.")
			SendChatTarget(ClientID, "The weapon you specialized on will get")
			SendChatTarget(ClientID, "those effects faster and in a stronger way.")
			SendChatTarget(ClientID, "Use: /weapon <hammer|gun|shotgun|grenade|rifle>")
			SendChatTarget(ClientID, "Info about certain weapons:")
			SendChatTarget(ClientID, "/info <hammer|gun|shotgun|grenade|rifle>")
			SendChatTarget(ClientID, "More info at:")
			SendChatTarget(ClientID, "/info <level|stats>")
        elseif (Text:sub(1, 10) == "/info rank" and Text:len() == 10) then
			SendChatTarget(ClientID, "Shows your rank")
			SendChatTarget(ClientID, "Use: /rank <category>")
			SendChatTarget(ClientID, "The categories are optional.")
			SendChatTarget(ClientID, "More info about categories:")
			SendChatTarget(ClientID, "/info categories")
        elseif (Text:sub(1, 10) == "/info top5" and Text:len() == 10) then
			SendChatTarget(ClientID, "Shows the top5")
			SendChatTarget(ClientID, "Use: /rank <rank> <category>")
			SendChatTarget(ClientID, "Rank and category is optional.")
			SendChatTarget(ClientID, "Rank is the rank the list should begin with.")
			SendChatTarget(ClientID, "More info about categories:")
			SendChatTarget(ClientID, "/info categories")
        elseif (Text:sub(1, 16) == "/info categories" and Text:len() == 16) then
			SendChatTarget(ClientID, "There are the following categories:")
			SendChatTarget(ClientID, "Level -> Shows your rank by level")
			SendChatTarget(ClientID, "kill/death -> Shows your rank by kill/death ratio")
			SendChatTarget(ClientID, "Str -> Shows your rank by Str")
			SendChatTarget(ClientID, "Sta -> Shows your rank by Sta")
			SendChatTarget(ClientID, "Dex -> Shows your rank by Dex")
			SendChatTarget(ClientID, "Int -> Shows your rank by Int")
        elseif (Text:sub(1, 12) == "/info hammer" and Text:len() == 12) then
			SendChatTarget(ClientID, "Hammer:")
			SendChatTarget(ClientID, "STR -> Triple hits")
			SendChatTarget(ClientID, "DEX -> Hammer fullautomatic")
			SendChatTarget(ClientID, "INT -> Heal teammates")
        elseif (Text:sub(1, 9) == "/info gun" and Text:len() == 9) then
			SendChatTarget(ClientID, "Gun:");
			SendChatTarget(ClientID, "STR -> Dual gun");
			SendChatTarget(ClientID, "DEX -> Gun fullautomatic");
			SendChatTarget(ClientID, "INT -> Higher ammo reload");
        elseif (Text:sub(1, 13) == "/info shotgun" and Text:len() == 13) then
			SendChatTarget(ClientID, "Shotgun:");
			SendChatTarget(ClientID, "STR -> More projectiles");
			SendChatTarget(ClientID, "DEX -> Some bullets pierce through your opponent");
			SendChatTarget(ClientID, "INT -> Higher dist to shoot");
        elseif (Text:sub(1, 13) == "/info grenade" and Text:len() == 13) then
			SendChatTarget(ClientID, "Grenade Launcher:");
			SendChatTarget(ClientID, "STR -> More explosions");
			SendChatTarget(ClientID, "DEX -> Bigger explosions");
			SendChatTarget(ClientID, "INT -> Use grenades as mines aswell");
        elseif (Text:sub(1, 11) == "/info rifle" and Text:len() == 11) then
			SendChatTarget(ClientID, "Laser Rifle:");
			SendChatTarget(ClientID, "STR -> Explosions");
			SendChatTarget(ClientID, "DEX -> Pierce through enemys");
			SendChatTarget(ClientID, "INT -> Heal teammates with the rifle");
        elseif (Text:sub(1, 6) == "/rules" and Text:len() == 6) then
			SendChatTarget(ClientID, "1. Do not bot.");
			SendChatTarget(ClientID, "2. Do not level others / yourself.");
			SendChatTarget(ClientID, "3. Do not use multi accounts.");
			SendChatTarget(ClientID, "4. Do not abuse bugs.");
			SendChatTarget(ClientID, "5. Do not mass suicide.");
			SendChatTarget(ClientID, "6. Do not AFK-kill.");
			SendChatTarget(ClientID, "7. Do not swear, beg, spam or flame.");
			SendChatTarget(ClientID, "8. Asking for reset will earn you a warning.");
			SendChatTarget(ClientID, "9. Who was resetted for no reason may lose many levels.");
        else
            SendChatTarget(ClientID, "Unknown command")
            SendChatTarget(ClientID, "/cmdlist")
        end

        return true
    end
end


---------------------------------Accounts-------------------------------------

function OnData(id)
    Print("query", id)
    Queries[id]["fx"](id)
    Queries[id] = nil
end

function Login(name, pass, ClientID)
    if (MySQLEscapeString(name) ~= nil and MySQLEscapeString(pass) ~= nil) then
        Id = MySQLQuery("SELECT * FROM `users` WHERE `username` = '" .. MySQLEscapeString(name) .. "' && `password` = '" .. MySQLEscapeString(pass) .. "'")
        Queries[Id] = {}
        Queries[Id]["fx"] = LoginCB
        Queries[Id]["cid"] = ClientID
        return true
    end
    return false
end

function LoginCB(id)
    Rows = MySQLFetchResults(id)
    if (Rows[1]["uid"] > 0) then
        Accounts[Queries[id]["cid"]] = Rows[1]
        Accounts[Queries[id]["cid"]]["ExpNeeded"] = CalcNeededExp(Accounts[Queries[id]["cid"]]["Level"])
        Accounts[Queries[id]["cid"]]["KillStreak"] = 0
        SetPlayerName(Queries[id]["cid"], "[" .. Accounts[Queries[id]["cid"]]["Level"] .. "]" .. Names[Queries[id]["cid"]])
        SetPlayerTeam(Queries[id]["cid"], 0)
        CalcStats(Queries[id]["cid"])
        SendChatTarget(Queries[id]["cid"], "You are now logged in.")
    else
        SendChatTarget(Queries[id]["cid"], "This account does not exists or the password is wrong!")
    end
end

function Register(name, pass, ClientID)
    Id = MySQLQuery("SELECT COUNT(*) as cnt FROM `users` WHERE `username` = '" .. MySQLEscapeString(name) .. "'")
    Queries[Id] = {}
    Queries[Id]["fx"] = RegisterCB
    Queries[Id]["cid"] = ClientID
    Queries[Id]["name"] = name
    Queries[Id]["pass"] = pass
end

function RegisterCB(id)
    Rows = MySQLFetchResults(id)
    if (Rows[1]["cnt"] == 0) then
        MySQLQuery("INSERT INTO `users` (`username`, `password`) VALUES ('" .. MySQLEscapeString(Queries[id]["name"]) .. "', '" .. MySQLEscapeString(Queries[id]["pass"]) .. "')")
        SendChatTarget(Queries[id]["cid"], "Registration successful!")
        SendChatTarget(Queries[id]["cid"], "You may now log in with your account.")
        SendBroadcast("Registration successful! You may now log in with your account.", Queries[id]["cid"])
    else
        SendChatTarget(Queries[id]["cid"], "This account already exists!")
    end
end

function CalcStats(ClientID)
	if (Affected and Accounts[ClientID]["Level"] >= -1) then
		if (Accounts[ClientID]["Level"] < 1) then
            Accounts[ClientID]["Attack"] = 500
            Accounts[ClientID]["Defense"] = 1000
            Accounts[ClientID]["Reload"] = 450
            Accounts[ClientID]["Ammo"] = 300

            if (Accounts[ClientID]["Weapon"] - 1 == 0) then
                Accounts[ClientID]["HammerFactor"] = 3
            else
                Accounts[ClientID]["HammerFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 1) then
                Accounts[ClientID]["GunFactor"] = 3
            else
                Accounts[ClientID]["GunFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 2) then
                Accounts[ClientID]["ShotgunFactor"] = 3
            else
                Accounts[ClientID]["ShotgunFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 3) then
                Accounts[ClientID]["GrenadeFactor"] = 3
            else
                Accounts[ClientID]["GrenadeFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 4) then
                Accounts[ClientID]["RifleFactor"] = 3
            else
                Accounts[ClientID]["RifleFactor"] = 1
            end

			Accounts[ClientID]["HammerTriple"] = true
			Accounts[ClientID]["HammerAuto"] = true
			Accounts[ClientID]["HammerHeal"] = 100

			Accounts[ClientID]["GunDual"] = true
			Accounts[ClientID]["GunAuto"] = true
			Accounts[ClientID]["GunAmmoReload"] = 400

			Accounts[ClientID]["ShotgunShots"] = 300
			Accounts[ClientID]["ShotgunPierce"] = true
			Accounts[ClientID]["ShotgunDist"] = 400

			Accounts[ClientID]["GrenadeExplosions"] = 3
			Accounts[ClientID]["GrenadeSpread"] = 300
			Accounts[ClientID]["GrenadeMine"] = 2

			Accounts[ClientID]["RifleExplosions"] = 2
			Accounts[ClientID]["RiflePierce"] = true
			Accounts[ClientID]["RifleHeal"] = 100
		else
			Accounts[ClientID]["Attack"] = clamp(99 + Accounts[ClientID]["_Str"], 100, 300)
			Accounts[ClientID]["Defense"] = clamp(99 + Accounts[ClientID]["_Sta"], 100, 300)
			Accounts[ClientID]["Reload"] = clamp(99 + Accounts[ClientID]["_Dex"], 100, 300)
			Accounts[ClientID]["Ammo"] = clamp(99 + Accounts[ClientID]["_Int"], 100, 300)

            if (Accounts[ClientID]["Weapon"] - 1 == 0) then
                Accounts[ClientID]["HammerFactor"] = 3
            else
                Accounts[ClientID]["HammerFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 1) then
                Accounts[ClientID]["GunFactor"] = 3
            else
                Accounts[ClientID]["GunFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 2) then
                Accounts[ClientID]["ShotgunFactor"] = 3
            else
                Accounts[ClientID]["ShotgunFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 3) then
                Accounts[ClientID]["GrenadeFactor"] = 3
            else
                Accounts[ClientID]["GrenadeFactor"] = 1
            end

            if (Accounts[ClientID]["Weapon"] - 1 == 4) then
                Accounts[ClientID]["RifleFactor"] = 3
            else
                Accounts[ClientID]["RifleFactor"] = 1
            end

			if (Accounts[ClientID]["_Str"] >= math.floor(150 / Accounts[ClientID]["HammerFactor"])) then
                Accounts[ClientID]["HammerTriple"] = true
            else
                Accounts[ClientID]["HammerTriple"] = false
            end
			if (Accounts[ClientID]["_Dex"] >= math.floor(150 / Accounts[ClientID]["HammerFactor"])) then
                Accounts[ClientID]["HammerAuto"] = true
            else
                Accounts[ClientID]["HammerAuto"] = false
            end
            Accounts[ClientID]["HammerHeal"] = clamp(math.floor((Accounts[ClientID]["_Int"] * Accounts[ClientID]["HammerFactor"]) / 30), 0, 10)


			if (Accounts[ClientID]["_Str"] >= math.floor(150 / Accounts[ClientID]["GunFactor"])) then
                Accounts[ClientID]["GunDual"] = true
            else
                Accounts[ClientID]["GunDual"] = false
            end
			if (Accounts[ClientID]["_Dex"] >= math.floor(150 / Accounts[ClientID]["GunFactor"])) then
                Accounts[ClientID]["GunAuto"] = true
            else
                Accounts[ClientID]["GunAuto"] = false
            end
            Accounts[ClientID]["GunAmmoReload"] = clamp(math.floor(100 + (Accounts[ClientID]["_Int"] * Accounts[ClientID]["GunFactor"])), 100, 400)


            Accounts[ClientID]["ShotgunShots"] = clamp(math.floor(119 + ((Accounts[ClientID]["_Str"] * Accounts[ClientID]["ShotgunFactor"]) / 3)), 100, 300)
			if ((Accounts[ClientID]["_Dex"] >= math.floor(105 / Accounts[ClientID]["ShotgunFactor"]))) then
                Accounts[ClientID]["ShotgunPierce"] = true
            else
                Accounts[ClientID]["ShotgunPierce"] = false
            end
            Accounts[ClientID]["ShotgunDist"] = clamp(math.floor(99 + ((Accounts[ClientID]["_Int"] * Accounts[ClientID]["ShotgunFactor"]) / 3)), 100, 200)


            Accounts[ClientID]["GrenadeExplosions"] = clamp(math.floor(1 + ((Accounts[ClientID]["_Str"] * Accounts[ClientID]["GrenadeFactor"]) / 150)), 1, 2)
            Accounts[ClientID]["GrenadeSpread"] = clamp(math.floor(100 + ((Accounts[ClientID]["_Dex"] * Accounts[ClientID]["GrenadeFactor"]) / 3)), 100, 300)
            Accounts[ClientID]["GrenadeMine"] = clamp(math.floor((Accounts[ClientID]["_Int"] * Accounts[ClientID]["GrenadeFactor"]) / 90), 0, 2)


            Accounts[ClientID]["RifleExplosions"] = clamp(math.floor((Accounts[ClientID]["_Str"] * Accounts[ClientID]["RifleFactor"]) / 120), 0, 2);
			if (Accounts[ClientID]["_Dex"] >= (180 / Accounts[ClientID]["RifleFactor"])) then
                Accounts[ClientID]["RiflePierce"] = true
            else
                Accounts[ClientID]["RiflePierce"] = false
            end
            Accounts[ClientID]["RifleHeal"] = clamp(math.floor((Accounts[ClientID]["_Int"] * Accounts[ClientID]["RifleFactor"]) / 30), 0, 10)
        end
	elseif (Accounts[ClientID]["Level"] >= -1) then
        Accounts[ClientID]["Attack"] = 100
        Accounts[ClientID]["Defense"] = 100
        Accounts[ClientID]["Reload"] = 100
        Accounts[ClientID]["Ammo"] = 100

		Accounts[ClientID]["HammerTriple"] = false
		Accounts[ClientID]["HammerAuto"] = false
		Accounts[ClientID]["HammerHeal"] = 0

		Accounts[ClientID]["GunDual"] = false
		Accounts[ClientID]["GunAuto"] = false
		Accounts[ClientID]["GunAmmoReload"] = 100

		Accounts[ClientID]["ShotgunShots"] = 100
		Accounts[ClientID]["ShotgunPierce"] = false
		Accounts[ClientID]["ShotgunDist"] = 100

		Accounts[ClientID]["GrenadeExplosions"] = 1
		Accounts[ClientID]["GrenadeSpread"] = 100
		Accounts[ClientID]["GrenadeMine"] = 0

		Accounts[ClientID]["RifleExplosions"] = 0
		Accounts[ClientID]["RiflePierce"] = false
		Accounts[ClientID]["RifleHeal"] = 0
	else
        Accounts[ClientID]["Attack"] = 1
        Accounts[ClientID]["Defense"] = 1
        Accounts[ClientID]["Reload"] = 1
        Accounts[ClientID]["Ammo"] = 1

		Accounts[ClientID]["HammerTriple"] = false
		Accounts[ClientID]["HammerAuto"] = false
		Accounts[ClientID]["HammerHeal"] = 0

		Accounts[ClientID]["GunDual"] = false
		Accounts[ClientID]["GunAuto"] = false
		Accounts[ClientID]["GunAmmoReload"] = 1

		Accounts[ClientID]["ShotgunShots"] = 1
		Accounts[ClientID]["ShotgunPierce"] = false
		Accounts[ClientID]["ShotgunDist"] = 1

		Accounts[ClientID]["GrenadeExplosions"] = 1
		Accounts[ClientID]["GrenadeSpread"] = 1
		Accounts[ClientID]["GrenadeMine"] = 0

		Accounts[ClientID]["RifleExplosions"] = 0
		Accounts[ClientID]["RiflePierce"] = false
		Accounts[ClientID]["RifleHeal"] = 0
    end
end

function Update(ClientID)
    if (Accounts[ClientID]["uid"] == nil) then
        SetPlayerName(ClientID, "[NOT LOGGED IN]")
    else
        SetPlayerName(ClientID, "[" .. Accounts[ClientID]["Level"] .. "]" .. Names[ClientID])
        CalcStats(ClientID)
        MySQLQuery("UPDATE `users` SET `password` = '" .. MySQLEscapeString(Accounts[ClientID]["password"]) .. "', `Kills` = '" .. MySQLEscapeString(Accounts[ClientID]["Kills"]) .. "', `Deaths` = '" .. MySQLEscapeString(Accounts[ClientID]["Deaths"]) .. "', `Level` = '" .. MySQLEscapeString(Accounts[ClientID]["Level"]) .. "', `Exp` = '" .. MySQLEscapeString(Accounts[ClientID]["Exp"]) .. "', `_Str` = '" .. MySQLEscapeString(Accounts[ClientID]["_Str"]) .. "', `_Sta` = '" .. MySQLEscapeString(Accounts[ClientID]["_Sta"]) .. "', `_Dex` = '" .. MySQLEscapeString(Accounts[ClientID]["_Dex"]) .. "', `_Int` = '" .. MySQLEscapeString(Accounts[ClientID]["_Int"]) .. "', `Weapon` = '" .. MySQLEscapeString(Accounts[ClientID]["Weapon"]) .. "', `Points` = '" .. MySQLEscapeString(Accounts[ClientID]["Points"]) .. "', `lastip` = '" .. MySQLEscapeString(GetPlayerIP(ClientID)) .. "', `LastName` = '" .. MySQLEscapeString(GetPlayerName(ClientID)) .. "', `last_logged_in` = CURRENT_TIMESTAMP, `Warnings` = '" .. MySQLEscapeString(Accounts[ClientID]["Warnings"]) .. "' WHERE `uid` = '" .. MySQLEscapeString(Accounts[ClientID]["uid"]) .. "'")
    end
end

function LevelUp(ClientID)
    if (Accounts[ClientID]["Exp"] >= Accounts[ClientID]["ExpNeeded"]) then
        Accounts[ClientID]["Exp"] = 0
        Accounts[ClientID]["Level"] = Accounts[ClientID]["Level"] + 1
        Accounts[ClientID]["Points"] = Accounts[ClientID]["Points"] + 2
        Accounts[ClientID]["ExpNeeded"] = CalcNeededExp(Accounts[ClientID]["Level"])

        SendChatTarget(ClientID, "Level up to " .. Accounts[ClientID]["Level"] .. "!")
        SendChatTarget(ClientID, "Stat points: " .. Accounts[ClientID]["Points"] .. "!")
        SendBroadcast("Level up to " .. Accounts[ClientID]["Level"] .. "!\nStat points: " .. Accounts[ClientID]["Points"] .. "!", ClientID)

		for i = 0, 127 do
            if (ClientID ~= i) then
                SendChatTarget(i, GetName(ClientID) .. " achieved level " .. Accounts[ClientID]["Level"] .. "!")
            end
		end
        Update(ClientID)
    end
end

function CalcNeededExp(level)
	Exp = 800;

	for i = 1, Level - 1 do
		Exp = Exp + i + (100 * math.pow(2, (i / 20)) * 5)
    end

	return Exp / 8
end

function AddExp(Killer, Level)
    LevelModificator = 5
    ExpToAdd = 0
    if(Coop) then
        ExpToAdd = clamp(((10 + clamp((Level - Accounts[Killer]["Level"]) * 3, 5, 100)) * LevelModificator), 0, (Accounts[Killer]["ExpNeeded"] - Accounts[Killer]["Exp"])*2)/2
    else
        ExpToAdd = clamp(((10 + clamp((Level - Accounts[Killer]["Level"]) * 3, 5, 100)) * LevelModificator), 0, Accounts[Killer]["ExpNeeded"] - Accounts[Killer]["Exp"])
    end

    ExpToAdd = ExpToAdd + clamp(math.floor(Accounts[Killer]["KillStreak"] * 1.5), 0, 250)
    Accounts[Killer]["Exp"] = Accounts[Killer]["Exp"] + ExpToAdd
    texp = math.round(Accounts[Killer]["Exp"] * 100 / Accounts[Killer]["ExpNeeded"], 2)
    taexp = math.round(ExpToAdd * 100 / Accounts[Killer]["ExpNeeded"], 2)
    if (math.ceil(texp) == texp) then
        texp = texp .. ".00"
    elseif (math.ceil(texp * 10) == texp * 10) then
        texp = texp .. "0"
    end
    if (math.ceil(taexp) == taexp) then
        taexp = taexp .. ".00"
    elseif (math.ceil(taexp * 10) == taexp * 10) then
        taexp = taexp .. "0"
    end
    SendChatTarget(Killer, "Current exp: " .. texp .. "% (+" .. taexp .. "%)");
    LevelUp(Killer) --check for level up
end

function Kill(Killer, Victim, Weapon)
    Accounts[Victim]["KillStreak"] = 0
    if (Killer ~= Victim) then
        Accounts[Killer]["Kills"] = Accounts[Killer]["Kills"] + 1
        Accounts[Victim]["Deaths"] = Accounts[Victim]["Deaths"] + 1

        AddExp(Killer, Accounts[Victim]["Level"])

        Accounts[Killer]["KillStreak"] = Accounts[Killer]["KillStreak"] + 1
        if (Accounts[Killer]["KillStreak"] % 5 == 0) then

            SpreeType = clamp(Accounts[Killer]["KillStreak"] / 5, 1, 11)
            if (SpreeType == 1) then
                SendBroadcast(GetName(Killer) .. " is on a killing spree!", -1);
            end
            if (SpreeType == 2) then
                SendBroadcast(GetName(Killer) .. " is on a rampage!", -1);
            end
            if (SpreeType == 3) then
                SendBroadcast(GetName(Killer) .. " is dominating!", -1);
            end
            if (SpreeType == 4) then
                SendBroadcast(GetName(Killer) .. " is unstoppable!", -1);
            end
            if (SpreeType == 5) then
                SendBroadcast(GetName(Killer) .. " is godlike!", -1);
            end
            if (SpreeType == 6) then
                SendBroadcast(GetName(Killer) .. " is wicked sick!", -1);
            end
            if (SpreeType == 7) then
                SendBroadcast(GetName(Killer) .. " is p4wn4g3!", -1);
            end
            if (SpreeType == 8) then
                SendBroadcast(GetName(Killer) .. " has ludicrous skill!", -1);
            end
            if (SpreeType == 9) then
                SendBroadcast(GetName(Killer) .. " has 1337 sk!11Z!", -1);
            end
            if (SpreeType == 10) then
                SendBroadcast(GetName(Killer) .. " is over 9000!", -1);
            end
            if (SpreeType == 11) then
                SendBroadcast(GetName(Killer) .. " rulez the server!", -1);
            end

            AddExp(Killer, Accounts[Victim]["Level"] + 5 * SpreeType)
        end
    else
        Accounts[Victim]["Deaths"] = Accounts[Victim]["Deaths"] + 1
    end
    Update(Killer)
    Update(Victim)
end

function GetName(ClientID)
    return Names[ClientID]
end

----------------------------------------------NET---------------------------------------------
function SendAccountData(ClientID)
    --to client
end

for i = 16, 16 do
    DummyCreate(i)
    SetPlayerTeam(i, 0)
end

for i = 0, 127 do
    AccountReset(i)
end

