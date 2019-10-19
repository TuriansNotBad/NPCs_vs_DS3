
-- GOAL_ShitbirdMovement_27482 = 27482;

local nav = "nav"; -- lazy, for logging
COORDINATE_TYPE_PlungeReady = 120;
COORDINATE_TYPE_GreetsReady = 119;
COORDINATE_TYPE_Waiting     = 118;
COORDINATE_TYPE_CelebrationReady = 117;

RegisterTableGoal(GOAL_ShitbirdMovement_27482, "GOAL_ShitbirdMovement_27482");
REGISTER_GOAL_NO_SUB_GOAL( GOAL_ShitbirdMovement_27482, true );

local Shitbird = Goal;

-- to determine if we're on the cliff
local cliffRegion = 5500301;
local offLimitsRegion = 5500302; -- can't go here, pathfinding too crap
Shitbird.moveTargets = {
	{ 5500000, true },
	{ 5500001, true },
	{ 5500002, true },
	{ 5500003, true },
	{ 5500004, true },
	{ 5500005, true },
	{ 4002805, true },
};

function Shitbird:Initialize( ai, goal, changeBattleStateNum ) end

-- can't use the usual Initialize func cos we want to operate regardless of battle state
function Shitbird:Init( ai, goal )
	
	self.battleGoal = g_GoalTable[ GOAL_ShitbirdBattle_27481 ];
	
	ai:SetStringIndexedNumber( "moveTarget", 1 );	-- index of moveTargets table entry to which we want to go
	ai:SetStringIndexedNumber( "state", 0 );		-- our state defines which action we do
	ai:SetStringIndexedNumber( "battleType", 0 );	-- how do we engage enemies
	
	-- disable logging this
	log:setState( nav, true );
	log:setState( "nav_interrupt", false );
	
	-- log:setThinkId( ai:GetNpcThinkParamID() );		-- whichever is initialized first
	ai:SetEventMoveTarget( 4000202 );
	log:clearEx( ai, nav );
	log:clearEx( ai, "nav_interrupt" );
	log( ai, nav, "Test distance = ", ai:GetDist( POINT_EVENT ) );
	log( ai, nav, "Navigation init" );
	log( ai, nav, "moveTarget = ", ai:GetStringIndexedNumber( "moveTarget" ), " state = ", ai:GetStringIndexedNumber( "state" ) );
	log:section( ai, nav );
	
end

function Shitbird:Activate( ai, goal )

	local state = ai:GetStringIndexedNumber( "state" );
	
	-- boss fight state we do nothing else
	if ( state == 5 ) then
		log( ai, nav, "I am state 5 = ", ai:GetStringIndexedNumber( "state" ) );
		
		if (ai:GetEventRequest(0) == 90) then
			ai:SetStringIndexedNumber( "state", 7 );
			return true;
		end
		
		if ( ai:GetNpcThinkParamID() == 27481 ) then
			goal:AddSubGoal( GOAL_ShitbirdGundyr_27483, 10 );
		else
			self:GundyrFightInit_Act08( ai, goal );
		end
		return true;
	end
	
	-- init if we haven't yet
	if ( ai:GetStringIndexedNumber( "MovementInitialized" ) == 0 ) then
		ai:SetStringIndexedNumber( "MovementInitialized", 1 );
		self:Init( ai, goal );
	end

	if ( ai:GetNumber(3) ~= 0 and ai:IsFinishTimer(3) ) then
		ai:SetNumber( 3, 0 );
		ai:DeleteTeamReacor( COORDINATE_TYPE_GreetsReady );
		ai:DeleteTeamReacor( COORDINATE_TYPE_Waiting );
	end
	
	if ( ai:GetNumber(4) ~= 0 and ai:IsFinishTimer(4) ) then
		ai:SetNumber( 4, 0 );
		ai:AddTeamRecord( COORDINATE_TYPE_CelebrationReady, TARGET_NONE, 0 );
	end
	
	if ( not ai:IsBothHandMode( TARGET_SELF ) ) then
		goal:AddSubGoal( GOAL_COMMON_Attack, 10, NPC_ATK_ButtonTriangle, TARGET_SELF, 999, 0, 0 );
	end
	
	-- init if we haven't yet
	if ( ai:GetStringIndexedNumber( "MovementInitialized" ) == 0 ) then
		ai:SetStringIndexedNumber( "MovementInitialized", 1 );
		self:Init( ai, goal );
	end
	
	-- do battle if need to do battle
	if ( ai:IsBattleState() and ai:GetStringIndexedNumber( "battleType" ) ~= 2 and not ai:IsInsideTargetRegion( TARGET_ENE_0, offLimitsRegion ) and state < 3 ) then
		goal:AddSubGoal( GOAL_ShitbirdBattle_27481, 10 );
	end
	
	local eventNo = ai:GetEventRequest(0);	-- poll event to see if we're inside boss room
	-- event request to get into boss fight positions
	if ( eventNo == 98 ) then
		ai:SetStringIndexedNumber( "state", 3 );
	-- boss fight has begun
	elseif ( eventNo == 97 ) then
		ai:SetStringIndexedNumber( "state", 4 );
	end
	
	local moveTarget = ai:GetStringIndexedNumber( "moveTarget" );
	
	-- check if we're on cliff and should not attack anything
	if ( moveTarget == 6 and ai:IsInsideTargetRegion( TARGET_SELF, cliffRegion ) ) then
		ai:SetStringIndexedNumber( "battleType", 2 );
		log( ai, nav, "On the cliff, switching battleType to 2" );
	end
	
	-- if we haven't finished our path yet
	if ( moveTarget <= table.getn( self.moveTargets ) ) then
		
		-- make sure target is always set before we try to use it
		Birdteam:SetMoveTarget( ai, self.moveTargets[ moveTarget ][1], moveTarget );
		
		local pointDist = ai:GetDist( POINT_EVENT );
		if (pointDist <= 1.5) then
			
			log( ai, nav, "Point reached (dist=", pointDist, ") moveTarget = ", moveTarget, " pointId = ", self.moveTargets[ moveTarget ][1] );
			
			-- we've arrived, set next point target
			ai:SetStringIndexedNumber( "moveTarget", 1 + moveTarget );
			-- we're at the cliff
			if ( moveTarget == 3 ) then
				ai:SetStringIndexedNumber( "battleType", 1 ); -- we now gang on enemies
			elseif ( moveTarget == 6 ) then
				log( ai, nav, "State change to 1, plunge cliff" );
				ai:SetStringIndexedNumber( "state", 1 );
			-- we've reached the fog door
			elseif ( moveTarget == table.getn( self.moveTargets ) ) then
				log( ai, nav, "State change to 2, fog door" );
				ai:SetStringIndexedNumber( "state", 2 );
			end
			
		end
		
	end
	
	-- update state
	state = ai:GetStringIndexedNumber( "state" );
	moveTarget = ai:GetStringIndexedNumber( "moveTarget" );
	
	-- ################################
	-- is friend too far
	if ( moveTarget < 4 and state == 0 ) then
		if ( ai:GetDist( TARGET_FRI_0 ) >= 10 ) then
			if ( Birdteam:ShouldIWait( ai ) ) then
				-- wait state
				ai:SetStringIndexedNumber( "state", 99 );
				Birdteam:SetState( ai, 99 );
			else
				-- catch up state
				ai:SetStringIndexedNumber( "state", 98 );
				Birdteam:SetState( ai, 98 );
			end
		elseif ( ai:GetDist( TARGET_FRI_0 ) >= 4 and ai:GetTeamRecordCount( COORDINATE_TYPE_Attack, TARGET_ENE_0, 0 ) == 0 and state < 98 ) then
			-- dash catch up state
			if ( not Birdteam:ShouldIWait( ai ) and not ai:IsBattleState() ) then
				ai:SetStringIndexedNumber( "state", 97 );
			end
		end
	end


	-- state 0 means we can move
	if ( state == 0 ) then
		self:Progress_Act01( ai, goal );
		
	-- state 1 means we reached the cliff and should walk off of it
	elseif ( state == 1 ) then
		self:PlungeCliff_Act02( ai, goal );
		
	-- state 2 means we want to enter the fog arena
	elseif ( state == 2 ) then
		ai:SetEventMoveTarget( 4002805 );
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, POINT_EVENT, 0.3, TARGET_SELF, false, -1 );
		
	-- state 3 means we've entered the boss arena
	elseif ( state == 3 ) then
		self:WakeTheGundyr_Act03( ai, goal );
		
	-- boss fight initialization
	elseif ( state == 4 ) then
		self:GundyrFightInit_Act08( ai, goal );
	
	-- post boss fight
	elseif ( state == 7 ) then
		self:PostGundyr_Act09( ai, goal );
		
	-- claw celebration
	elseif ( state == 8 ) then
		self:ClawCelebration_Act10( ai, goal );
		
	-- waiting for a friend
	elseif ( state == 99 ) then
		self:Wait4Friend_Act04( ai, goal );
		
	-- coming to waiting friend
	elseif ( state == 98 ) then
		self:ComeToFriend_Act05( ai, goal );
		
	-- sprinting to nonwaiting friend
	elseif ( state == 97 ) then
		self:DashToFriend_Act06( ai, goal );
	
	-- greet each other with Call over gesture
	elseif ( state == 96 ) then
		self:CallOverFriend_Act07( ai, goal );
		
	end
	
	return true;
 
end

-- simply move towards next target
function Shitbird:Progress_Act01(ai, goal)
	
	local moveTarget = ai:GetStringIndexedNumber( "moveTarget" );
	
	log( ai, nav, "Progress_Act01, moving to ", moveTarget, " id ", self.moveTargets[ moveTarget ][1] );
	
	Birdteam:SetMoveTarget( ai, self.moveTargets[ moveTarget ][1], moveTarget );
	goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, POINT_EVENT, 1.5, TARGET_SELF, false, -1 );
	
end

-- do a plunging attack
function Shitbird:PlungeCliff_Act02( ai, goal )
	
	local moveTarget = ai:GetStringIndexedNumber( "moveTarget" );
	Birdteam:SetMoveTarget( ai, self.moveTargets[ moveTarget ][1], moveTarget );
	
	-- tell the team that we're waiting at the cliff
	ai:AddTeamRecord( COORDINATE_TYPE_PlungeReady, TARGET_EVENT, 0 );
	
	log( ai, nav, "PlungeCliff_Act02 adding team record, num = ", ai:GetTeamRecordCount( COORDINATE_TYPE_PlungeReady, TARGET_EVENT, 0 ) );
	
	-- when both are ready - plunge
	if ( ai:GetTeamRecordCount( COORDINATE_TYPE_PlungeReady, TARGET_EVENT, 0 ) >= 2 ) then
		goal:ClearSubGoal();
		-- turn and plunge
		-- ai:RequestEmergencyQuickTurn();
		-- ai:TurnTo( TARGET_EVENT );
		local plunge = goal:AddSubGoal( GOAL_WalkAndPlunge, 10, TARGET_EVENT, ai:GetDistYSigned(TARGET_EVENT) + 2 );
		-- if plunge goal is over we return to normal state
		-- if ( plunge:GetLastResult() == GOAL_RESULT_Success or plunge:GetLastResult() == GOAL_RESULT_Failed ) then
		
		log( ai, nav, "PlungeCliff_Act02 after, result=", plunge:GetLastResult(), ", state=", ai:GetStringIndexedNumber( "state" ) );
		
	end
	log( ai, nav, "Dist = ", ai:GetDistY( POINT_EVENT ) )
	if ( ai:GetDistY( POINT_EVENT ) <= 1 ) then
		ai:SetStringIndexedNumber( "state", 0 );
		ai:SetStringIndexedNumber( "battleType", 1 );
	end

end

function Shitbird:WakeTheGundyr_Act03( ai, goal )
	
	-- this one will wake the gundyr
	if ( ai:GetNpcThinkParamID() == 27481 ) then
	
		ai:SetEventMoveTarget( 5500007 );
		local dist = ai:GetDist( POINT_EVENT );
		-- move to pulling pos and let emevd handle the rest
		if ( dist >= 1 ) then
			goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, POINT_EVENT, 1, TARGET_SELF, false, -1 );
		end
		
	-- this one will do the anim
	else
	
		ai:SetEventMoveTarget( 5500006 );
		local dist = ai:GetDist( POINT_EVENT );
		-- sprint to position
		if ( dist >= 2 ) then
			goal:AddSubGoal( GOAL_COMMON_DashTarget, 1, POINT_EVENT, 0.5, TARGET_SELF, -1, 1, 1 );
		-- stretch out
		else
			goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_Gesture23, TARGET_SELF, 999, 0, 0 );
		end
		
	end

end

function Shitbird:Wait4Friend_Act04( ai, goal )
	
	ai:AddTeamRecord( COORDINATE_TYPE_Waiting, TARGET_NONE, 0 );
	
	-- if both waiting for some reason make one approach
	if ( ai:GetTeamRecordCount( COORDINATE_TYPE_Waiting, TARGET_NONE, 0 ) >= 2 ) then
		ai:DeleteTeamReacor( COORDINATE_TYPE_Waiting );
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, TARGET_FRI_0, 0, TARGET_SELF, false, -1 );
	else
		goal:AddSubGoal( GOAL_COMMON_Turn, 0.5, TARGET_FRI_0, 15 );
	end
	
	-- if we're close enough end this and reset state
	if ( ai:GetDist( TARGET_FRI_0 ) <= 2 ) then
		goal:ClearSubGoal();
		Birdteam:SyncMoveTargets( ai );
		ai:SetStringIndexedNumber( "state", 96 ); -- call over
		Birdteam:SetState( ai, 96 );
	else
		ai:TurnTo( TARGET_FRI_0 );
	end

end

-- friend is waiting, we just approach no rush
function Shitbird:ComeToFriend_Act05( ai, goal )
	
	-- run to friend
	goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, TARGET_FRI_0, 0, TARGET_SELF, false, -1 );
	
	-- if we're close enough stop, resync and reset state
	if ( ai:GetDist( TARGET_FRI_0 ) <= 2 ) then
		goal:ClearSubGoal();
		Birdteam:SyncMoveTargets( ai );
		ai:SetStringIndexedNumber( "state", 96 ); -- call over
		Birdteam:SetState( ai, 96 );
		-- this wait makes sure friend isn't stuck in a gesture animation while we run off, causing this to loop forever
		-- goal:AddSubGoal( GOAL_COMMON_Wait, 3, TARGET_SELF );
	end
	
end

-- friend is not waiting, we must dash to catch up
function Shitbird:DashToFriend_Act06( ai, goal )
	
	-- dash to friend
	goal:AddSubGoal( GOAL_COMMON_DashTarget, 1, TARGET_FRI_0, 2, TARGET_FRI_0, -1, 1, 1 );
	
	-- if we're close enough stop, resync and reset state
	if ( ai:GetDist( TARGET_FRI_0 ) <= 2 ) then
		goal:ClearSubGoal();
		Birdteam:SyncMoveTargets( ai );
		ai:SetStringIndexedNumber( "state", 0 );
	end
	
end

-- greet each other with call over
function Shitbird:CallOverFriend_Act07( ai, goal )
	
	ai:AddTeamRecord( COORDINATE_TYPE_Waiting, TARGET_NONE, 0 );
	
	-- if both waiting for some reason make one approach
	if ( ai:GetTeamRecordCount( COORDINATE_TYPE_Waiting, TARGET_NONE, 0 ) >= 2 and ai:GetDist( TARGET_FRI_0 ) > 2 ) then
		ai:DeleteTeamReacor( COORDINATE_TYPE_Waiting );
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 0.5, TARGET_FRI_0, 1, TARGET_SELF, false, -1 );
		return;
	end
	
	log ( ai, nav, "angle = ", ai:GetToTargetAngle( TARGET_FRI_0 ) );
	-- turn if we need to
	if not ( ai:IsLookToTarget( TARGET_FRI_0, 25 ) ) then
		goal:AddSubGoal( GOAL_COMMON_TurnAround, 1, TARGET_FRI_0, AI_DIR_TYPE_CENTER, 15, true, true, -1 );
		
	else
		log( ai, nav, "looking at it - ", ai:GetTeamRecordCount( COORDINATE_TYPE_GreetsReady, TARGET_NONE, 0 ) );
		-- tell team we're ready
		ai:AddTeamRecord( COORDINATE_TYPE_GreetsReady, TARGET_NONE, 0 );
		
		-- if both ready - call over
		if ( ai:GetTeamRecordCount( COORDINATE_TYPE_GreetsReady, TARGET_NONE, 0 ) >= 2 ) then
			goal:ClearSubGoal();
			goal:AddSubGoal( GOAL_COMMON_Attack, 10, NPC_ATK_Gesture24, TARGET_FRI_0, 999, 0, 0 );
			-- if attack is done - reset state
			-- if ( ai:IsStartAttack() and ai:IsFinishAttack() ) then
				ai:SetStringIndexedNumber( "state", 0 );
			-- end
			
			ai:SetNumber( 3, 1 );
			ai:SetTimer( 3, 1 );
			Birdteam:SetState( ai, nil );
			
		end
		
	end
	
end

function Shitbird:GundyrFightInit_Act08( ai, goal )
	
	goal:ClearSubGoal();
	-- one of them was stretching out, backstep out of it
	if ( ai:GetNpcThinkParamID() == 27480 ) then
		-- get up and move to entrance, emevd shall handle the rest
		ai:SetEventMoveTarget( 5500008 );
		if ( ai:GetDist( POINT_EVENT ) > 1 ) then
			goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 6, POINT_EVENT, 1, TARGET_SELF, false, -1 ):SetLifeEndSuccess( true );
		else
			goal:AddSubGoal( GOAL_COMMON_Wait, 2, TARGET_SELF );
		end
	end
	ai:SetStringIndexedNumber( "state", 5 );
	
end

function Shitbird:PostGundyr_Act09( ai, goal )
	
	local dist = ai:GetDist( TARGET_EVENT );
	
	log ( ai, lname, "dist = ", dist );
	
	if ( ai:GetNpcThinkParamID() == 27480 ) then
		
		if ( dist <= 2 ) then
			-- applause
			goal:ClearSubGoal();
			-- goal:AddSubGoal( GOAL_COMMON_Wait, 1, TARGET_SELF ):SetLifeEndSuccess( true );
			goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 5, NPC_ATK_Gesture28, TARGET_EVENT, 999, 0, 0 ):SetLifeEndSuccess( true );
			ai:SetTimer( 4, 4 );
			ai:SetNumber( 4, 1 );
			ai:SetStringIndexedNumber( "state", 8 );
		end
		
	else
		
		-- come over
		if ( dist > 2 ) then
			goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 5, TARGET_EVENT, 0, TARGET_SELF, false, -1 );
		else
			ai:AddTeamRecord( COORDINATE_TYPE_CelebrationReady, TARGET_NONE, 0 );
			ai:SetStringIndexedNumber( "state", 8 );
		end
		
	end
end

function Shitbird:ClawCelebration_Act10( ai, goal )
	if ( ai:GetTeamRecordCount( COORDINATE_TYPE_CelebrationReady, TARGET_NONE, 0 ) >= 2 ) then
		goal:AddSubGoal( GOAL_COMMON_ComboRepeat, 10, NPC_ATK_L1, TARGET_EVENT, 3, 0 );
	end
end

function Shitbird:Update( ai, goal )
	return Update_Default_NoSubGoal( self, ai, goal );
end

function Shitbird:Interrupt( ai, goal )

	for i = INTERUPT_First, INTERUPT_Last do
		if (ai:IsInterupt( i )) then
			log( ai, "nav_interrupt", i );
		end
	end

	return false;
	
end


function Shitbird:Interrupt_CANNOT_MOVE( ai, goal )
	local state = ai:GetStringIndexedNumber( "state" )
	-- if we got stuck trying to get to an ally
	if ( state == 98 or state == 97 ) then
		goal:ClearSubGoal();
		goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, TARGET_FRI_0, 0, TARGET_SELF, false, -1 );
		return true;
	end
	return false;
end

-- try to dodge bolts
function Shitbird:Interrupt_Shoot( ai, goal )
	-- need this so we don't try to handle gundyr's boulders outside of his goal
	local state = ai:GetStringIndexedNumber( "state" )
	if ( state >= 5 ) then
		return false;
	end
	goal:ClearSubGoal();
	self.battleGoal:Dodge_Act22( ai, goal );
	return true;
end

function Shitbird:Terminate( ai, goal )
end
