
-- 5035

GOAL_ShitbirdGundyr_27483 = 27483

local dodgeForward = 0;
local dodgeLeft    = -45;	-- is actually diagonal left
local dodgeRight   = 45;	-- is actually diagonal right
local dodgeBack    = 180;

RegisterTableGoal(GOAL_ShitbirdGundyr_27483, "GOAL_ShitbirdGundyr_27483");
REGISTER_GOAL_NO_SUB_GOAL( GOAL_ShitbirdGundyr_27483, true );
REGISTER_GOAL_UPDATE_TIME(GOAL_ShitbirdGundyr_27483, 0, 0);

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
	[3010] = { dodgeRight, true, false, 8, 0 },
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
	[3027] = { dodgeLeft, true, false, 0, 0 },
	-- swing right to left, mid combo
	[3028] = { dodgeLeft, true, true, 0, 0 },
	-- swing left to right, start
	[3029] = { dodgeRight, true, true, 0, 0 }
	
};

function Shitbird:IsAttack( n1, eventNo )
	return n1 == eventNo or n1 == ( eventNo - 27000 );
end

function Shitbird:Initialize( ai, goal )

	ai:SetStringIndexedNumber("Dist_Rolling", 4.4);
	ai:SetStringIndexedNumber( "enableDodging", 1 );
	
	-- disable logging this
	log:setState( lname, true );
	-- log:setThinkId( ai:GetNpcThinkParamID() );		-- whichever is initialized first
	log:clear( lname );
	
	log( ai, lname, "Initializing GOAL_ShitbirdGundyr_27483..." );

end

function Shitbird:ResetStates( ai )
end

function Shitbird:Activate( ai, goal )
	
	if ( ai:GetStringIndexedNumber( "GundyrInitialize" ) == 0 ) then
		self:Initialize( ai, goal );
		ai:SetStringIndexedNumber( "GundyrInitialize", 1 )
	end
	
	
	goal:AddSubGoal( GOAL_COMMON_SidewayMove, 2, TARGET_EVENT, 1, 60, false, true, -1 );
	
	return true;
	
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

function Shitbird:ThrustCombo_Act02( ai, goal )
	
	
end

function Shitbird:Update( ai, goal )
	return Update_Default_NoSubGoal( self, ai, goal );
end

function Shitbird:Interrupt( ai, goal )
	return false;
end

function Shitbird:Interrupt_CANNOT_MOVE( ai, goal )
	log( ai, lname, "CANTMOVE" );
	goal:ClearSubGoal();
	goal:AddSubGoal( GOAL_COMMON_ApproachTarget, 2, POINT_EVENT, 3, TARGET_SELF, false, -1, 1, true );
	return true;
end

function Shitbird:Interrupt_EventRequest( ai, goal )

	return true;
	
end

function	Shitbird:Terminate( ai, goal )	end
