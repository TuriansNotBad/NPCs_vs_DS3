-- log:clear("logAM");
-- list of managed AIs
local ais = {};
-- list of managed attacks
local attacks = { n = 0 };

-- event offsets
local eventStartOffset = 0;
local eventLockRotationOffset = 1000;
local eventAttackOffset = 2000;
local eventEndAttackOffset = 3000;
local eventFinishOffset = 4000;

AttackManager = {};
-- default event slot we listen on
AttackManager.eventSlot = 1;

function AttackManager:RegisterAI( ai, battleGoalTbl )
	ais[ ai:GetNpcThinkParamID() ] = { obj = ai, tbl = battleGoalTbl, injected = false };
end

function AttackManager:SetEventSlot( eventSlot )
	self.eventSlot = eventSlot;
end

function AttackManager:RegisterAttack( attackId, fOnStart, fOnFinish, fOnAttack, fOnEndAttack, fOnLockRotation )
	
	-- already registered
	for i = 1, attacks.n do
		if ( attacks[i].id == attackId ) then
			return;
		end
	end
	
	attacks[ attacks.n + 1 ] = {
		id = attackId,
		OnStart = fOnStart,					-- when the animation starts
		OnFinish = fOnFinish,				-- when the animation finishes
		OnAttack = fOnAttack,				-- when the attack hitbox appears
		OnEndAttack = fOnEndAttack,			-- when the attack hitbox goes away
		OnLockRotation = fOnLockRotation	-- when the objects rotation is set to very small value
	};
	attacks.n = attacks.n + 1;
	
end

local function ListenerCaller( tbl, ai, goal, func )
	if ( func ~= nil ) then
		func( tbl, ai, goal );
	end
end

function AttackManager:InjectInterrupt( ai, tbl )
	
	local aiTbl = ais[ ai:GetNpcThinkParamID() ]
	-- if already did it don't
	if ( aiTbl.injected == true ) then
		return;
	end
	
	aiTbl.injected = true;
	-- save the old interrupt function so we can call it
	local oldFunc = tbl.Interrupt_EventRequest or _InterruptTableGoal_TypeCall_Dummy;
	
	-- set up an interrupt
	tbl.Interrupt_EventRequest = function( tbl, ai, goal )
		-- get event
		local eventNo = ai:GetEventRequest( AttackManager.eventSlot );
		-- log( ai, "logAM", oldFunc );
		
		-- find out if we should call one
		for i = 1, attacks.n do
			-- log( ai, "logAM", attacks, " ", attacks.n, " ", table.getn(attacks), " ", attacks[i] );
			-- when the animation starts
			if ( attacks[i].id == eventNo - eventStartOffset ) then
				ListenerCaller( tbl, ai, goal, attacks[i].OnStart );
			-- when the objects rotation is set to very small value
			elseif ( attacks[i].id == eventNo - eventLockRotationOffset ) then
				ListenerCaller( tbl, ai, goal, attacks[i].OnLockRotation );
			-- when the attack hitbox appears
			elseif ( attacks[i].id == eventNo - eventAttackOffset ) then
				ListenerCaller( tbl, ai, goal, attacks[i].OnAttack );
			-- when the attack hitbox goes away
			elseif ( attacks[i].id == eventNo - eventEndAttackOffset ) then
				ListenerCaller( tbl, ai, goal, attacks[i].OnEndAttack );
			-- when the animation finishes
			elseif ( attacks[i].id == eventNo - eventFinishOffset ) then
				ListenerCaller( tbl, ai, goal, attacks[i].OnFinish );
			end
		end
		
		return oldFunc( tbl, ai, goal );
		
	end
	
end
