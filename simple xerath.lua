if GetObjectName(GetMyHero()) ~= "Xerath" then return end
-- known issue:
-- dead buff(kog, karthus) cause get target fail
-- recall cause pred fail(way point bug? only happen with AI)

require 'Inspired'
require 'Interrupter'

local debug = false
local DrawDebugText = DrawText
if not debug then DrawDebugText = function ( ... ) end end
local castname = "nope"
local myHero = GetMyHero()

local semiAuto = false
local semiAutoDelay = 0



local qTime = 0
local qRange = 0
local function checkQ()
	if GotBuff(myHero,"XerathArcanopulseChargeUp") > 0 then
		if qTime == 0 then qTime = GetTickCount() end
	else
    qTime = 0
	end

  local timeWaste = 0 
	if qTime ~= 0 then  timeWaste = GetTickCount() - qTime end
	if timeWaste > 1500 then 
  	qRange = 1500 
	else
  	qRange = GetCastRange(myHero,_Q) + 500 * (timeWaste / 1000)
	end

  DrawDebugText("Q range "..qRange,20,200,100,0xff00ff00)
end

local function castQ( target )
	
	if IsInDistance(target, 1500) and CanUseSpell(myHero,_Q) == READY then	
		
		-- start castQ
		if GotBuff(myHero,"XerathArcanopulseChargeUp") == 0 then
			local mousePos = GetMousePos()
      CastSkillShot(_Q,mousePos.x,mousePos.y,mousePos.z)
      return
    end

    -- release castQ
    local myHeroPos = GetMyHeroPos()
    if IsInDistance(target, qRange) then 
    	-- CastStartPosVec,EnemyChampionPtr,EnemyMoveSpeed,YourSkillshotSpeed,SkillShotDelay,SkillShotRange,SkillShotWidth,MinionCollisionCheck,AddHitBox;
    	local pred = GetPredictionForPlayer(myHeroPos,target,GetMoveSpeed(target),math.huge,500,qRange,200,false,true)
    	if pred.HitChance == 1 then 
    		CastSkillShot2(_Q,pred.PredPos.x,pred.PredPos.y,pred.PredPos.z)
    		-- PrintChat("qRange "..qRange)
    	end
		end
	end
end

local function castW( target )	
	if IsInDistance(target, GetCastRange(myHero,_W)) and CanUseSpell(myHero,_W) == READY then	
		-- CastStartPosVec,EnemyChampionPtr,EnemyMoveSpeed,YourSkillshotSpeed,SkillShotDelay,SkillShotRange,SkillShotWidth,MinionCollisionCheck,AddHitBox;
		local pred = GetPredictionForPlayer(GetOrigin(target),target,GetMoveSpeed(target),math.huge,500,GetCastRange(myHero,_W),150,false,true)
		if pred.HitChance == 1 then
			CastSkillShot(_W,pred.PredPos.x,pred.PredPos.y,pred.PredPos.z)
		end
	end
end

local function castE( target )	
	if IsInDistance(target, GetCastRange(myHero,_E)) and CanUseSpell(myHero,_E) == READY then	
		local myHeroPos = GetMyHeroPos()
		-- CastStartPosVec,EnemyChampionPtr,EnemyMoveSpeed,YourSkillshotSpeed,SkillShotDelay,SkillShotRange,SkillShotWidth,MinionCollisionCheck,AddHitBox;
		local pred = GetPredictionForPlayer(myHeroPos,target,GetMoveSpeed(target),1600,250,GetCastRange(myHero,_E),70,true,true)
		-- DrawDebugText("cast E: "..pred.HitChance,20,0,135,0xff00ff00)
		if pred.HitChance == 1 then
			CastSkillShot(_E,pred.PredPos.x,pred.PredPos.y,pred.PredPos.z)
		end
	end
end

local rTarget
local rDelay
local rChangeTargetDelay
local rRange = 0
local function castR( target )
	-- save r range because r range change to 25000 when casting
	if GotBuff(myHero,"XerathLocusOfPower2") == 0 then 	rRange = GetCastRange(myHero,_R) end

	-- change target when target is dead
	if not rTarget or IsDead(rTarget) or not ( GetOrigin(rTarget) and IsInDistance(rTarget, rRange) ) then 
		local old = rTarget
		rTarget = GetTarget(rRange, DAMAGE_MAGIC)
		
		if old and rTarget then
			local range = GetDistance(old, rTarget)
			-- PrintChat("ChangeTargetrange "..range)
			-- delay range / 2 ms
			rChangeTargetDelay = GetTickCount() + range / 2
		end
	end
	if not rTarget then return end	
	if semiAuto and GetDistance(GetMousePos(), GetOrigin(rTarget)) > 800 then 
		rTarget = nil
		rDelay = nil
		rChangeTargetDelay = nil
		return 
	end

	DrawDebugText("R target : "..GetObjectName(rTarget),20,0,120,0xff00ff00)

	if GotBuff(myHero,"XerathLocusOfPower2") == 0 then 
		rTarget = nil
		rDelay = nil
		rChangeTargetDelay = nil
		return 
	end

	local danger = IsInDistance(target, 700)
	if not danger then
		-- if rDelay then PrintChat("rDelay "..rDelay- GetTickCount()) end
		-- if rChangeTargetDelay then PrintChat("rChangeTargetDelay "..rChangeTargetDelay- GetTickCount()) end
		if rDelay and rDelay > GetTickCount() then return end
		if rChangeTargetDelay and rChangeTargetDelay > GetTickCount() then return end
	end

	local myHeroPos = GetMyHeroPos()
	if IsInDistance(rTarget, rRange) then
		-- CastStartPosVec,EnemyChampionPtr,EnemyMoveSpeed,YourSkillshotSpeed,SkillShotDelay,SkillShotRange,SkillShotWidth,MinionCollisionCheck,AddHitBox;
		local pred = GetPredictionForPlayer(myHeroPos,rTarget,GetMoveSpeed(rTarget),math.huge,600,rRange,170,false,true);
	 	if pred.HitChance == 1 then
			CastSkillShot(_R,pred.PredPos.x,pred.PredPos.y,pred.PredPos.z)
			rDelay = GetTickCount() + 800
			-- PrintChat(rRange.."  "..GetObjectName(rTarget))
		end
	end
end

local function killableInfo()
	-- skip when R in cd
	-- if CanUseSpell(myHero,_R) ~= READY then return end

	-- skip when not learn R yet
	if GetCastLevel(myHero,_R) == 0 then return end

	local rDmg = 135 + GetCastLevel(myHero,_R) * 55 + GetBonusAP(myHero) * 0.43
	rDmg = rDmg * 3
	local info = ""
	for nID, enemy in pairs(GetEnemyHeroes()) do
		if IsObjectAlive(enemy) and IsVisible(enemy) then
			realdmg = CalcDamage(myHero, enemy, 0, rDmg)
			hp = GetCurrentHP(enemy)
			if realdmg > hp then
				info = info..GetObjectName(enemy).."  killable by 3 R\n"
			end
			-- info = info..GetObjectName(enemy).."    HP:"..hp.."  dmg: "..realdmg.." "..killable.."\n"
		end
  end
  DrawText(info,40,500,0,0xffff0000) 
end

OnLoop(function(myHero)

	DrawDebugText("Q range "..GetCastRange(myHero,_Q),20,200,30,0xff00ff00)
	DrawDebugText("R range "..GetCastRange(myHero,_R),20,0,30,0xff00ff00)
	DrawDebugText("buff XerathArcanopulseChargeUp: "..GotBuff(myHero,"XerathArcanopulseChargeUp"),20,0,150,0xff00ff00)
	DrawDebugText("buff XerathLocusOfPower2: "..GotBuff(myHero,"XerathLocusOfPower2"),20,0,170,0xff00ff00)
	DrawDebugText("OnProcessSpell name : "..castname,20,0,250,0xff00ff00)

	killableInfo()

	-- TODO: rework this toggle feature with new api(hope we have)
	if KeyIsDown(17) and semiAutoDelay < GetTickCount() then
		semiAuto = not semiAuto
		semiAutoDelay = GetTickCount() + 500
	end
	if semiAuto then
		DrawText("semi-auto R mode : ON", 40,600,200,0xffffff00)
	end


	local target = GetCurrentTarget()
	if ValidTarget(target) then
		if GetObjectName(target) then
			DrawDebugText("target "..GetObjectName(target),20,0,100,0xff00ff00)
		end
	
		castR(target)

		checkQ()
		if KeyIsDown(32) then	
			castQ(target)
			castW(target)
			castE(target)
		end
	end
end)

OnProcessSpell(function(unit,spell)
	if spell.name:lower():find("xerath") then
		castname = spell.name
	end
end)

addInterrupterCallback(function(target, spellType)
	castE(target)
end)

PrintChat("simple xerath script loaded")