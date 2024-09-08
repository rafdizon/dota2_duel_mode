if GameSetup == nil then
    GameSetup = class({})
end

LinkLuaModifier("invulnerable_modifier", LUA_MODIFIER_MOTION_NONE)

function GameSetup:init()
  print("setup function-----------------")
  GameRules:EnableCustomGameSetupAutoLaunch(true)
  GameRules:SetCustomGameSetupAutoLaunchDelay(120)
  GameRules:SetHeroSelectionTime(60)
  GameRules:SetStrategyTime(10)
  GameRules:SetPreGameTime(30)
  GameRules:SetShowcaseTime(0)
  GameRules:SetPostGameTime(5)
  GameRules:SetStartingGold(999999)

  local GameMode = GameRules:GetGameModeEntity()
  GameMode:SetLoseGoldOnDeath(false)
  GameMode:SetFixedRespawnTime(15)
  GameMode:SetDaynightCycleDisabled(true)
  GameMode:DisableHudFlip(true)
  GameMode:SetDeathOverlayDisabled(true)
  GameMode:SetWeatherEffectsDisabled(true)
  GameRules:SetSameHeroSelectionEnabled(true)
  GameRules:SetUseUniversalShopMode(true)

  ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnStateChange"), self)
  ListenToGameEvent("npc_spawned", Dynamic_Wrap(self, "OnNPCSpawned"), self)
end

function GameSetup:OnStateChange()
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_STRATEGY_TIME then 
    --Select random hero if a player did not pick a hero  
    GameSetup:RandomForNoHeroSelected()

  elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
    -- if in dev mode, respawn a NPC hero (SVEN)
    if IsInToolsMode() then
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 1)
      local unit = CreateUnitByName("npc_dota_hero_sven", Vector(0,0,0), true, nil, nil, DOTA_TEAM_BADGUYS)
      unit:SetControllableByPlayer(playerID, true)
    end
  elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    -- First to 10 kills wins
    Timers:CreateTimer(2, function()
      local radiant = GetTeamHeroKills(DOTA_TEAM_GOODGUYS)
      local dire = GetTeamHeroKills(DOTA_TEAM_BADGUYS)
      if radiant >= 10 then
        GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
        return nil
      elseif dire >=10 then
        GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        return nil
      end
      return 1
    end)
  end
end

function GameSetup:OnNPCSpawned(event)
  local spawnedUnit = EntIndexToHScript(event.entindex)
  if spawnedUnit:IsRealHero() then
    -- Apply invulnerability to heroes in the initial phase of the game
    Timers:CreateTimer(1, function()
      if GameRules:GetDOTATime(false, true) <= 0 then
        ApplyInvulnerability(spawnedUnit)
        return 1
      else
        RemoveInvulnerability(spawnedUnit)
        return nil
      end
    end)

    -- Level up hero to level 30 at the start of the game
    if spawnedUnit:GetLevel() < 30 then
      SetHeroToLevel30(spawnedUnit)
    end
  end
end

function GameSetup:RandomForNoHeroSelected()
  local maxPlayers = 2
  for teamNum = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
    for i=1, maxPlayers do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamNum, i)
      if playerID ~= nil then
        if not PlayerResource:HasSelectedHero(playerID) then
          local hPlayer = PlayerResource:GetPlayer(playerID)
          if hPlayer ~= nil then
            hPlayer:MakeRandomHeroSelection()
          end
        end
      end
    end
  end
end

function ApplyInvulnerability(hero)
  print("------------------------------NOW APPLYING INVULNERABILITY TO HEROES----------------------")
  hero:AddNewModifier(hero, nil, "invulnerable_modifier", nil)
end

function RemoveInvulnerability(hero)
  print("------------------------------REMOVING INVULNERABILITY-----------------------------------")
  hero:RemoveModifierByName("invulnerable_modifier")
end

function SetHeroToLevel30(hero)
    hero:AddExperience(64400, DOTA_ModifyXP_Unspecified, false, false)
end
