-----------------------------------------------------------------
-- custom gundyr battle goal for testing
-----------------------------------------------------------------
GOAL_Gundyr3012Spam = 27484;
RegisterTableGoal( GOAL_Gundyr3012Spam, "GOAL_Gundyr3012Spam" );
REGISTER_GOAL_NO_SUB_GOAL( GOAL_Gundyr3012Spam, true );

function Goal:Activate( ai, goal )
	-- Init_Pseudo_Global(ai, goal);
	-- ai:SetStringIndexedNumber("Dist_SideStep", 4);
	-- ai:SetStringIndexedNumber("Dist_BackStep", 3.8);
	-- ai:SetStringIndexedNumber("Gunda_ADAdjustment", 0);
	-- ai:SetStringIndexedNumber("Gunda_ForceRunDist", 999);
	-- ai:SetStringIndexedNumber("Gunda_Odds_Run", 0);
	-- GundaBattle_Act09( ai, goal );
	goal:AddSubGoal( GOAL_Gunda_511000_Battle, goal:GetLife() );
	return true;
end

function Goal:Update( ai, goal )
	return Update_Default_NoSubGoal( self, ai, goal );
end

function Goal:Terminate( ai, goal ) end
function Goal:Interrupt( ai, goal ) return true; end

-----------------------------------------------------------------
-- gundyr boss fight goal
-----------------------------------------------------------------

-- 5035

GOAL_ShitbirdGundyr_27483 = 27483;

local dodgeForward = 0;
local dodgeLeft    = -45;	-- is actually diagonal left
local dodgeRight   = 45;	-- is actually diagonal right
local dodgeBack    = 180;

-- REGIONS
local bossRoomMiddle = 5500007;

RegisterTableGoal( GOAL_ShitbirdGundyr_27483, "GOAL_ShitbirdGundyr_27483" );
REGISTER_GOAL_NO_SUB_GOAL( GOAL_ShitbirdGundyr_27483, true );
REGISTER_GOAL_UPDATE_TIME( GOAL_ShitbirdGundyr_27483, 0, 0 );

local lname = "logboss";

local Shitbird = Goal;

-- dodge direction is reversed compared to the attack cos the characters are facing each other
-- [ezStateId] = { dodge_dir, bCanCounter, bCanFollowUp, iCooldownTime, iMinDist };
Shitbird.attackTable = {
	
	-- att 1500, phase 2 switch.
	[ 10 ] = { nil, true, false, 0, 0 },
	-- running smash
	-- condition: distance >= 8
	[3000] = { dodgeForward, true, true, 10, 8 },
	-- swing right to left, mid combo
	[3001] = { dodgeLeft, true, true, 0, 0 },
	-- jump and plunge
	-- condition: distance >= 8 and some interrupt based on sp effects that i dont understand
	[3002] = { dodgeLeft, true, false, 8, 8 },
	-- fist attack, should never counter as shoulder follow up is too quick
	-- condition: distance < 1.5
	[3003] = { dodgeRight, false, true, 8, 0 },
	-- swing left to right
	-- condition: enemy within arc
	[3004] = { dodgeRight, true, true, 8, 0 },
	-- shoulder attack
	-- condition: part of 3004 combo
	[3005] = { dodgeForward, true, true, 0, 0 },
	-- heavy thrust, only used as finisher for many combos, best counter time
	[3006] = { dodgeRight, true, false, 0, 0 },
	-- 2handed swing right to left, only used in 1 combo, always followed up by 3008
	-- condition: distance < 8 (10%) or target is to the either sides
	[3007] = { dodgeRight, true, true, 8, 0 },
	-- heavy smash with boulders, mostly a finisher
	[3008] = { dodgeRight, true, true, 0, 0 },
	-- grab attack
	[3010] = { dodgeForward, true, false, 8, 0 },
	-- running swing right to left
	[3011] = { dodgeLeft, true, true, 0, 0 },
	-- thrust quick, start
	[3012] = { dodgeRight, true, true, 0, 0 },
	-- thrust quick, combo
	[3013] = { dodgeRight, true, true, 0, 0 },
	-- smash, combo ender
	[3014] = { dodgeRight, true, false, 0, 0 },
	-- fist attack
	[3026] = { dodgeRight, false, true, 0, 0 },
	-- shoulder attack
	[3027] = { dodgeForward, true, false, 0, 0 },
	-- swing right to left, mid combo
	[3028] = { dodgeLeft, true, true, 0, 0 },
	-- swing left to right, start
	[3029] = { dodgeRight, true, true, 0, 0 }
	
};

Shitbird.phase = 1;

-- reverse bool
function Shitbird:SetPunish( ai, val )
	ai:SetStringIndexedNumber( "dontPunish", val );
end
-- reverse bool
function Shitbird:SetDodge( ai, val )
	ai:SetStringIndexedNumber( "dontDodge", val );
end

function Shitbird:ShouldPunish( ai )
	return ai:GetStringIndexedNumber( "dontPunish" ) == 0;
end

function Shitbird:ShouldDodge( ai )
	return ai:GetStringIndexedNumber( "dontDodge" ) == 0;
end

function Shitbird:Initialize( ai, goal )

	ai:SetStringIndexedNumber( "Dist_Rolling", 4.4 );
	ai:SetStringIndexedNumber( "enableDodging", 1 );
	ai:SetStringIndexedNumber( "bossState", 0 );
	
	-- disable logging this
	log:setState( lname, true );
	-- log:setThinkId( ai:GetNpcThinkParamID() );		-- whichever is initialized first
	log:clear( lname );
	
	log( ai, lname, "Initializing GOAL_ShitbirdGundyr_27483..." );
	
	AttackManager:RegisterAI( ai, self );
	
	-- thrust combo
	AttackManager:RegisterAttack( 3012, self.Att3012_OnStart, nil, self.Att3012_OnAttack, self.Att3012_OnEndAttack, self.Att3012_OnLockRotation );
	AttackManager:RegisterAttack( 3013, self.Att3013_OnStart, nil, self.Att3013_OnAttack, self.Att3013_OnEndAttack, self.Att3013_OnLockRotation );
	AttackManager:RegisterAttack( 3014, self.Att3014_OnStart, nil, self.Att3014_OnAttack, self.Att3014_OnEndAttack, self.Att3014_OnLockRotation );
	-- end thrust combo
	
	AttackManager:InjectInterrupt( ai, self );
	
	log( ai, lname, "Reigstered..." );
	
end

function Shitbird:Activate( ai, goal )
	
	-- if we killed it, we don't do anything
	if ( ai:GetHpRate( TARGET_EVENT ) <= 0.0 ) then
		log( ai, lname, "State 7 reached, entity dead" );
		ai:SetStringIndexedNumber( "state", 7 );
		goal:ClearSubGoal();
		return true;
	end
	
	-- when gundyr is knocked back on his knees
	ai:AddObserveSpecialEffectAttribute( TARGET_EVENT, 30 );
	-- phase 2 switch
	ai:AddObserveSpecialEffectAttribute( TARGET_EVENT, 12304 );
	-- is phase 2
	ai:AddObserveSpecialEffectAttribute( TARGET_EVENT, 5404 );
	-- phase 2 is it attacking
	ai:AddObserveSpecialEffectAttribute( TARGET_EVENT, 5035 );
	-- idle watcher
	ai:AddObserveSpecialEffectAttribute( TARGET_EVENT, 5032 );
	
	-- init
	if ( ai:GetStringIndexedNumber( "GundyrInitialize" ) == 0 ) then
		self:Initialize( ai, goal );
		ai:SetStringIndexedNumber( "GundyrInitialize", 1 );
	end
	
	ai:SetEventMoveTarget( bossRoomMiddle );
	-- stay near middle of the arena
	if ( ai:GetDist( POINT_EVENT ) >= 16 or ai:GetStringIndexedNumber( "bossState" ) == 1 ) then
		ai:SetStringIndexedNumber( "bossState", 1 );	-- move to middle state
		ai:SetStringIndexedNumber( "dontDodge", 0 );	-- make sure we reset our dodge state
	-- stay point blank to boss
	elseif ( ai:GetDist( TARGET_EVENT ) >= 1.2 ) then
		ai:SetStringIndexedNumber( "bossState", 2 );	-- move to boss state
	end
	
	local state = ai:GetStringIndexedNumber( "bossState" );
	-- gundyr is staggered
	if ( ai:HasSpecialEffectId( TARGET_EVENT, 30 ) ) then
		self:PunishStagger_Act06( ai, goal );
	-- moving sideways around the boss
	elseif ( state == 0 ) then
		
		-- in phase 1 we merely circle waiting for it to attack
		if ( self.phase == 1 ) then
			self:SideWayMove_Act04( ai, goal );
		-- in phase 2 we are aggressive
		elseif ( self.phase == 2 ) then
			if ( ai:HasSpecialEffectId( TARGET_EVENT, 5035 ) ) then
				-- occupy ourselves till we dodge
				goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, TARGET_EVENT, 0.8, TARGET_SELF, false, -1 );
			else
				-- just attack if it is being passive
				self:AttackPhase2_Act09( ai, goal );
			end
		end
		
	-- moving towards middle
	elseif ( state == 1 ) then
		self:MoveToMid_Act02( ai, goal );
	-- moving towards boss
	elseif ( state == 2 ) then
		self:MoveToBoss_Act03( ai, goal );
	end
	
	return true;
	
end

------------- 3012 -------------
function Shitbird:Att3012_OnStart( ai, goal )
	log( ai, lname, "Att3012_OnStart" );
	self:SetDodge( ai, 1 );
end

function Shitbird:Att3012_OnLockRotation( ai, goal )

	
	local dist = ai:GetDist( TARGET_EVENT );
	local right = ai:IsInsideTargetEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_L, 140, 4 );
	local extreme = ai:IsInsideTargetEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_L, 100, 4 )
		or ai:IsInsideTargetEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_B, 100, 4 );
	
	log( ai, lname, "Att3012_OnLockRotation, ", dist, " ", right, " ", extreme );
	
	-- if we're not in a good position dodge
	if ( dist > 1.2 or right == false or self:ShouldPunish( ai ) == false ) then
		goal:ClearSubGoal();
		self:Dodge_Act01( ai, goal, dodgeRight );
		self:SetDodge( ai, 0 );	-- reset dodge
		self:SetPunish( ai, 0 );-- reset punish
	elseif ( extreme ) then
		log( ai, lname, "3012 extreme, chose to punish" );
		goal:ClearSubGoal();
		self:PunishR1_Act05( ai, goal );
		self:SetPunish( ai, 1 );
	end
	
end

function Shitbird:Att3012_OnAttack( ai, goal )
	log( ai, lname, "Att3012_OnAttack" );
	ai:SetStringIndexedNumber( "dontDodge", 1 );
end

function Shitbird:Att3012_OnEndAttack( ai, goal )

	log( ai, lname, "Att3012_OnEndAttack" );
	
	-- if we decided all is good
	if ( ai:GetStringIndexedNumber( "dontDodge" ) == 1 ) then
		-- don't try to punish 3012, 3013 will come too quick
		-- goal:ClearSubGoal();
		-- self:PunishR1_Act05( ai, goal );
		self:SetDodge( ai, 0 );
	end
	
end

------------- 3013 -------------
function Shitbird:Att3013_OnStart( ai, goal )
	log( ai, lname, "Att3013_OnStart" );
	ai:SetStringIndexedNumber( "dontDodge", 1 );
end

function Shitbird:Att3013_OnLockRotation( ai, goal )

	local dist = ai:GetDist( TARGET_EVENT );
	local right = ai:IsInsideTargetEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_L, 120, 4 );
	
	log( ai, lname, "Att3013_OnLockRotation, ", dist, " ", right );
	
	-- if we're not in a good position dodge, or if 3012 was punished
	if ( dist > 1.2 or right == false or self:ShouldPunish( ai ) == false ) then
		log( ai, lname, "3013 Panick! Must dodge!" );
		goal:ClearSubGoal();
		self:Dodge_Act01( ai, goal, dodgeRight );
		-- self:PunishR1_Act05( ai, goal );
		self:SetDodge( ai, 0 );
		-- reset punish;
		self:SetPunish( ai, 0 );
	end
	
end

function Shitbird:Att3013_OnAttack( ai, goal )
	log( ai, lname, "Att3013_OnAttack" );
end

function Shitbird:Att3013_OnEndAttack( ai, goal )

	log( ai, lname, "Att3013_OnEndAttack" );
	-- if we decided all is good
	if ( not self:ShouldDodge( ai ) ) then
		log( ai, lname, "3013 chose to punish" );
		-- try punish
		goal:ClearSubGoal();
		self:PunishR1_Act05( ai, goal );
		self:SetDodge( ai, 0 );
	end
	
end

------------- 3014 -------------
function Shitbird:Att3014_OnStart( ai, goal )
	log( ai, lname, "Att3014_OnStart" );
	ai:SetStringIndexedNumber( "dontDodge", 1 );
end

function Shitbird:Att3014_OnLockRotation( ai, goal )

	local dist = ai:GetDist( TARGET_EVENT );
	local right = ai:IsInsideTargetEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_L, 110, 4 );
	
	log( ai, lname, "Att3014_OnLockRotation, ", dist, " ", right );
	
	-- if we're not in a good position dodge
	if ( dist > 1 or right == false ) then
		goal:ClearSubGoal();
		self:Dodge_Act01( ai, goal, dodgeForward );
		self:PunishR1_Act05( ai, goal );
		ai:SetStringIndexedNumber( "dontDodge", 0 );
	end
	
end

function Shitbird:Att3014_OnAttack( ai, goal )
	log( ai, lname, "Att3014_OnAttack" );
end

function Shitbird:Att3014_OnEndAttack( ai, goal )

	log( ai, lname, "Att3014_OnEndAttack" );
	if ( ai:GetStringIndexedNumber( "dontDodge" ) == 1 ) then
		log( ai, lname, "3013 chose to punish" );
		-- try punish
		goal:ClearSubGoal();
		self:PunishR1_Act05( ai, goal );
		ai:SetStringIndexedNumber( "dontDodge", 0 );
	end
	
end

function Shitbird:Dodge_Act01( ai, goal, dir )
	
	-- determine direction
	local action = NPC_ATK_Up_ButtonXmark;
	if ( dir == dodgeLeft ) then
		action = NPC_ATK_UpLeft_ButtonXmark;
	elseif ( dir == dodgeRight ) then
		action = NPC_ATK_UpRight_ButtonXmark;
	elseif ( dir == dodgeBack ) then
		action = NPC_ATK_Down_ButtonXmark;
	end
	-- dodge
	goal:AddSubGoal(GOAL_COMMON_ComboTunable_SuccessAngle180, 2, action, TARGET_EVENT, 999, 0, 0);

	return 0;
	
end

function Shitbird:MoveToMid_Act02( ai, goal )
	
	ai:SetEventMoveTarget( bossRoomMiddle );
	if ( ai:GetDist( POINT_EVENT ) >= 1.5 ) then
		-- move
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, POINT_EVENT, 1, TARGET_SELF, false, -1, 1, true );
	else
		-- reset state if we close enough
		ai:SetStringIndexedNumber( "bossState", 0 );
	end
	
	return 0;
	
end

function Shitbird:MoveToBoss_Act03( ai, goal )

	if ( ai:GetDist( TARGET_EVENT ) >= 1.2 ) then
		-- move
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, TARGET_EVENT, 0.8, TARGET_SELF, false, -1 );
	else
		-- reset state if we close enough
		ai:SetStringIndexedNumber( "bossState", 0 );
	end
	return 0;
	
end

function Shitbird:SideWayMove_Act04( ai, goal )
	goal:AddSubGoal( GOAL_COMMON_SidewayMove, 2, TARGET_EVENT, 1, 60, false, true, -1 );
	return 0;
end

function Shitbird:PunishR1_Act05( ai, goal )
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_R1, TARGET_EVENT, 999, 0, 0 );
	return 100;
end

function Shitbird:PunishStagger_Act06( ai, goal )
	
	-- come over
	NPC_Approach_Act_Flex(ai, goal, 1.2, 0, 999, 100, 0, 0, 1);
	
	-- spam l1, inactivate interrupt should save us
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );

	return 100;
	
end

function Shitbird:PunishCommon_Act07( ai, goal, dontFill )
	
	-- come over
	NPC_Approach_Act_Flex(ai, goal, 1.5, 0, 999, 100, 0, 0, 1);
	-- r1
	if ( dontFill ~= true ) then
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 0.1, NPC_ATK_Up, TARGET_EVENT, 1.5, 0, 0 ):SetLifeEndSuccess( true );
	end
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_R1, TARGET_EVENT, 1.5, 0, 0 );
	
	return 100;
	
end

function Shitbird:PunishPhaseSwitch_Act08( ai, goal )

	local dist = ai:GetDist( TARGET_EVENT );
	local right = ai:IsInsideTargetEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_B, 40, 4 );
	
	if ( dist > 2 or right == false ) then
		goal:AddSubGoal( GOAL_COMMON_MoveToSomewhere, 3, TARGET_EVENT, AI_DIR_TYPE_B, 0.1, TARGET_EVENT, false );
	else
		-- spam l1, inactivate interrupt should save us
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
		-- goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
	end
	
	return 100;
	
end

function Shitbird:AttackPhase2_Act09( ai, goal )
	
	NPC_Approach_Act_Flex(ai, goal, 1.2, 0, 999, 100, 0, 0, 1);
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
	goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 1.5, 0, 0 );
	
	return 100;
	
end

function Shitbird:Update( ai, goal )
	return Update_Default_NoSubGoal( self, ai, goal );
end

function Shitbird:Interrupt( ai, goal )
	return false;
end

function Shitbird:Interrupt_EventRequest( ai, goal )
	
	-- event request at slot 1 is where we expect it to be
	local eventNo = ai:GetEventRequest(1);
	-- log( ai, lname, eventNo );
	
	-- dodge timing is in 50xx range, whereas attack ids are in 30xx range
	-- dont dodge should only be used by attack listeners
	if ( ai:GetStringIndexedNumber( "dontDodge" ) == 0 and self.attackTable[ eventNo - 2000 ] ~= nil ) then
		goal:ClearSubGoal();
		self:Dodge_Act01( ai, goal, self.attackTable[ eventNo - 2000 ][1] );
		
		-- punishable things
			-- 3010, Grab
		if ( eventNo == 5010
			-- 3008, heavy smash
			or eventNo == 5008
			-- 3011, running swing left to right
			or eventNo == 5011
			-- 3006, heavy thrust
			or eventNo == 5006
			-- 3002, jump and plunge
			or eventNo == 5002
			-- 3007, start of heavy thrust combo
			or eventNo == 5007
			-- 3027, shoulder finisher
			or eventNo == 5027 )
		then
			self:PunishCommon_Act07( ai, goal );
		end
		
		return true;
	end

	return false;
	
end

function Shitbird:Interrupt_Damaged( ai, goal )
	
	log( ai, lname, "----------DAMAGED!----------" );
	return false;
	
end

function Shitbird:Interrupt_ActivateSpecialEffect( ai, goal, effect )
	
	-- if gundyr got staggered
	if ( effect == 30 ) then
	
		log( ai, lname, "--------STAGGER!---------" );
		goal:ClearSubGoal();
		self:PunishStagger_Act06( ai, goal );
		return true;
	
	-- is gundyr being passive
	elseif ( effect == 5032 ) then
		
		if ( ai:GetDist( TARGET_EVENT ) <= 7 and ai:IsFinishTimer(3) and ai:IsInsideRangeEx( TARGET_EVENT, TARGET_SELF, AI_DIR_TYPE_F, 60 ) == false ) then
			goal:ClearSubGoal();
			self:PunishCommon_Act07( ai, goal, true );
			ai:SetTimer( 3, 3 );
		end
	
	-- phase 2 switch
	elseif ( effect == 12304 ) then
		
		goal:ClearSubGoal();
		self:PunishPhaseSwitch_Act08( ai, goal );
	
	-- phase 2 flag
	elseif ( effect == 5404 ) then
		self.phase = 2;
	
	-- phase 2 attack incoming
	elseif ( effect == 5035 ) then
		
		goal:ClearSubGoal();
		
	end
	
	return false;
	
end

function Shitbird:Interrupt_InactivateSpecialEffect( ai, goal, effect )

	-- if gundyr stagger ends
	if ( effect == 30 ) then
		
		log( ai, lname, "--------STAGGER END!--------" );
		goal:ClearSubGoal();
		self:PunishR1_Act05( ai, goal );
		return true;
	
	-- phase switch is over
	elseif ( effect == 12304 ) then
		
		goal:ClearSubGoal();
		return true;
		
	end
	
	return false;
	
end

-- function Shitbird:Interrupt_CANNOT_MOVE( ai, goal )
	-- log( ai, lname, "CANTMOVE" );
	-- goal:ClearSubGoal();
	-- try moving to mid
	-- ai:SetEventMoveTarget( bossRoomMiddle );
	-- goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, POINT_EVENT, 3, TARGET_SELF, false, -1, 1, true );
	-- return true;
-- end

function	Shitbird:Terminate( ai, goal )	end
