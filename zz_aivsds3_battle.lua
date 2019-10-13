
GOAL_ShitbirdBattle_27481 = 27481;

RegisterTableGoal(GOAL_ShitbirdBattle_27481, "GOAL_ShitbirdBattle_27481");
REGISTER_GOAL_NO_SUB_GOAL( GOAL_ShitbirdBattle_27481, true );

local Shitbird = Goal;
function Shitbird:Initialize( ai, goal )
	
	local actTbl = {};
	ai:SetStringIndexedArray( "cemetaryBattleActs", actTbl );
	ai:SetStringIndexedNumber("Dist_Rolling", 4.4);
	
end

local function chooseTarget( ai )
	if ( ai:GetDist( TARGET_EVENT ) < 0 ) then
		return TARGET_ENE_0;
	end
	if ( ai:GetDist( TARGET_ENE_0 ) <= ai:GetDist( TARGET_EVENT ) ) then
		return TARGET_ENE_0;
	end
	return TARGET_EVENT;
end

-- check if we want this target
function Shitbird:WantsCurrentTarget( ai )
	local target = chooseTarget( ai );
	return ai:GetDist( target ) <= ai:GetDistAtoB( target, TARGET_FRI_0 );
end

function Shitbird:Activate( ai, goal )
	
	local battleType = ai:GetStringIndexedNumber( "battleType" );
	
	-- team's got it, we don't want to touch that
	if ( not self:WantsCurrentTarget( ai ) and battleType == 0 ) then
		return true;
	end
	
	local target = chooseTarget( ai );
	
	local dist = ai:GetDist( target );
	-- dash attack if we're kinda far
	if ( dist >= 8 ) then
		self:DashAttack_Act01( ai, goal );
	-- spam L1 if we're closer
	elseif ( dist < 8 ) then
		self:ClawSpam_Act02( ai, goal );
	end
	
	return true;
	
end

function Shitbird:DashAttack_Act01( ai, goal ) 
	
	local target = chooseTarget( ai );
	-- tell the team we want this target
	ai:AddTeamRecord( COORDINATE_TYPE_Attack, target, 0 );
	
	-- dash and l1 spooky attack
	goal:AddSubGoal(GOAL_COMMON_DashTarget, 3, target, 5, TARGET_SELF, -1)
	goal:AddSubGoal(GOAL_COMMON_AttackTunableSpin, 10, NPC_ATK_L1, target, 999, 0, 0)
	
	return 100;
	
end

function Shitbird:ClawSpam_Act02( ai, goal )

	local target = chooseTarget( ai );
	-- tell the team we want this target
	ai:AddTeamRecord( COORDINATE_TYPE_Attack, target, 0 );

	local stam = ai:GetSp( TARGET_SELF );
	local dist = ai:GetDist( target );
	
	if ( ai:GetHpRate( target ) <= 0 ) then
		return 0;
	end
	
	-- if we have a lot of stam and target is decent range we can dash
	if ( stam >= 70 and dist >= 7 ) then
		goal:AddSubGoal( GOAL_COMMON_DashTarget, 7, target, 2, TARGET_SELF, -1 );
		-- make sure we don't do running attack
		goal:AddSubGoal( GOAL_COMMON_AttackTunableSpin, 0.1, 141, TARGET_SELF, -1, 0, 0 );
	-- run normally
	else
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 5, target, 2, target, false, -1 );
	end
	
	stam = ai:GetSp( TARGET_SELF );
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, target, 3, 0 );
	if ( ai:GetHpRate( target ) > 0 and stam > 0 ) then
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, target, 3, 0 );
	end
	if ( ai:GetHpRate( target ) > 0 and stam > 16 * 1 ) then
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, target, 3, 0 );
	end
	if ( ai:GetHpRate( target ) > 0 and stam > 16 * 2 ) then
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, target, 3, 0 );
	end
	if ( ai:GetHpRate( target ) > 0 and stam > 16 * 3 ) then
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, target, 3, 0 );
	end
	
	return 100;	
	
end

function Shitbird:Dodge_Act22( ai, goal )

	local targetDist = ai:GetDist(TARGET_ENE_0);
	local fateDodgeDir = ai:GetRandam_Int(1, 2);
	local fateCounter = ai:GetRandam_Int(1, 100);
	
	-- dodge forward if we're far
	-- if targetDist >= 3.5 then
		-- goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, NPC_ATK_Up_ButtonXmark, TARGET_ENE_0, 999, 0, 0);
	-- else
	
	local spaceLeft = SpaceCheck(ai, goal, -45, ai:GetStringIndexedNumber("Dist_Rolling"));
	local spaceRight = SpaceCheck(ai, goal, 45, ai:GetStringIndexedNumber("Dist_Rolling"));
	
	-- if enough space left and right dodge based on rng
	if ( spaceLeft and spaceRight ) then
		
		if ( fateDodgeDir == 1 ) then
			goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, NPC_ATK_UpRight_ButtonXmark, TARGET_ENE_0, 999, 0, 0);
		else
			goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, NPC_ATK_UpLeft_ButtonXmark, TARGET_ENE_0, 999, 0, 0);
		end
	
	-- only enough space on the left
	elseif ( spaceLeft ) then
		goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, NPC_ATK_UpLeft_ButtonXmark, TARGET_ENE_0, 999, 0, 0);
	-- only enough space on the right
	elseif ( spaceRight ) then
		goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, NPC_ATK_UpRight_ButtonXmark, TARGET_ENE_0, 999, 0, 0);
	else
		-- we still want to dodge even if not enough space anywhere
		-- rather fall of cliff and die than get hit by degenerates
		goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, NPC_ATK_Up_ButtonXmark, TARGET_ENE_0, 999, 0, 0);
	end
	
	
	-- end
	
	local stam = ai:GetSp(TARGET_SELF);
	-- 80% to roll attack if target was close enough initially
	if fateCounter <= 80 and stam > 0 and targetDist <= 4 then
		local r1range = 1.8;
		local r2range = 2.1;
		local r1per = 80;
		-- goal:AddSubGoal(GOAL_COMMON_NPCStepAttack, 10, TARGET_ENE_0, r1range, r2range, r1per);
	end
	
	return 100;
	
end

function Shitbird:Update( ai, goal )
	return Update_Default_NoSubGoal( self, ai, goal );
end

function Shitbird:Interrupt( ai, goal )
	return false;
end

-- try to dodge bolts
function Shitbird:Interrupt_Shoot( ai, goal )
	goal:ClearSubGoal();
	self:Dodge_Act22( ai, goal );
	return true;
end

function Shitbird:Interrupt_FindEnemy( ai, goal )
	goal:ClearSubGoal();
	ai:Replaning();
	return true;
end

function Shitbird:Terminate( ai, goal )
end
