-----------------------------------------------------------------------------------------------
--	Shitbird logic for beating the whole game
--	Description:
-----------------------------------------------------------------------------------------------
LOGIC_ID_Shitbird27480 = 27480
REGISTER_LOGIC_FUNC(LOGIC_ID_Shitbird27480, "Shitbird27480_Logic", "Shitbird27480_Interupt");
REGISTER_GOAL_UPDATE_TIME(LOGIC_ID_Shitbird27480, 0, 0);

-----------------------------------------------------------------------------------------------
--	Shitbird logic for beating the whole game
--	Determines top goal to use
-----------------------------------------------------------------------------------------------
function	Shitbird27480_Logic(ai)
	local topGoal = ai:GetTopGoal();

	if ( ai:GetStringIndexedNumber( "LogicInit" ) == 0 ) then
		ai:SetStringIndexedNumber( "LogicInit", 1 );
		Birdteam:Add( ai );
		-- log:setState( "logic_interrupt", false );
		-- log:clear( "logic_interrupt" );
	end
	local topGoal = ai:GetTopGoal();
	local eventNo = ai:GetEventRequest();
	local friend = ai:IsSearchTarget( TARGET_FRI_0 );
	local enemy = ai:IsSearchTarget( TARGET_ENE_0 );
	
	local enemyDist = ai:GetDist( TARGET_ENE_0 );
	
	-- walk if there is no enemies
	if ( not ai:HasGoal( GOAL_ShitbirdMovement_27482 ) ) then
		ai:AddTopGoal( GOAL_ShitbirdMovement_27482, 2 );
	end
	
end

-----------------------------------------------------------------------------------------------
--	Shitbird interrupts
--	Empty atm.
--	Doesn't respond to any interrupts so just return false. Leave it to the battle goals.
-----------------------------------------------------------------------------------------------
function	Shitbird27480_Interupt(ai, goal)

	-- for i = INTERUPT_First, INTERUPT_Last do
		-- if (ai:IsInterupt( i )) then
			-- log( ai, "logic_interrupt", i );
		-- end
	-- end

	return false;
end


