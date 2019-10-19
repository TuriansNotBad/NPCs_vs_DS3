
-- this is only for 2 characters max
Birdteam = {};

-- add a player to the team
function Birdteam:Add( ai )
	if self[ ai:GetNpcThinkParamID() ] == nil then
		self[ ai:GetNpcThinkParamID() ] = {};
	end
end

function Birdteam:SetState( ai, state )
	self[ ai:GetNpcThinkParamID() ].state = state;
end

function Birdteam:GetState( thinkId )
	return self[ thinkId ].state;
end

-- save move target for a player on the team
function Birdteam:SetMoveTarget( ai, moveTarget, idx )

	self[ ai:GetNpcThinkParamID() ].moveTarget = moveTarget;
	self[ ai:GetNpcThinkParamID() ].moveIdx = idx;
	
	ai:SetStringIndexedNumber( "moveTarget", idx );	
	ai:SetEventMoveTarget( moveTarget );
	
end

-- sets my target to friend's if my lagging
function Birdteam:SyncMoveTargets( ai )

	local myIdx = self[ ai:GetNpcThinkParamID() ].moveIdx;
	local friIdx = self[ self:GetFriendThinkId( ai ) ].moveIdx;
	
	if ( myIdx < friIdx ) then
		self:SetMoveTarget( ai, self[ self:GetFriendThinkId( ai ) ].moveTarget, friIdx );
	end
	
end

-- get think id of the the other person
function Birdteam:GetFriendThinkId( ai )
	if ( ai:GetNpcThinkParamID() == 27481 ) then
		return 27480;
	end
	return 27481;
end

-- determines which one of us is behind
function Birdteam:ShouldIWait( ai )

	local myIdx = self[ ai:GetNpcThinkParamID() ].moveIdx;
	local friIdx = self[ self:GetFriendThinkId( ai ) ].moveIdx;
	
	if ( myIdx ~= friIdx ) then
		return myIdx > friIdx;
	end
	
	return ai:GetDist( POINT_EVENT ) <= ai:GetDistAtoB( POINT_EVENT, TARGET_FRI_0 );
	
end

-- get move target of the other person
function Birdteam:GetFriendMoveTarget( ai )
	return self[ self:GetFriendThinkId( ai ) ].moveTarget;
end

-- get move target index of the other person
function Birdteam:GetFriendMoveTargetIdx( ai )
	return self[ self:GetFriendThinkId( ai ) ].moveIdx;
end

function ClearTableOdds(actOddsTbl)
	for i = 1, 99 do
		actOddsTbl[i] = 0;
	end
end

-- same as REGIST_FUNC but allows to also pass the goal's table.
function REGIST_TFUNC(t, ai, goal, f, paramTbl)
	return function()
		return f(t, ai, goal, paramTbl);
	end
end

function InsideRangeEx( ai, target, angleBase, angleRange, distMin, distMax )

	local targetDist = ai:GetDist(target); -- distance to target
	
	-- check if target within specified distance range bounds
	if distMin <= targetDist and targetDist <= distMax then
	
		local targetAngle = ai:GetToTargetAngle(target); -- angle to target
		
		local sign = 0;
		if angleBase < 0 then
			sign = -1;
		else
			sign = 1;
		end
		-- check if current angle is within angle range from base angle
		if (angleBase + angleRange / -2 <= targetAngle and targetAngle <= angleBase + angleRange / 2)
			-- allows you to also use angleBase values such that 180 <= angleBase <= 360
			or (angleBase + angleRange / -2 <= targetAngle + 360 * sign and targetAngle + 360 * sign <= angleBase + angleRange / 2)
		then
			return true;
		else
			return false;
		end
		
	else
		return false;
	end
	
end

log = {};
log.on = true;
log.showTime = true;
log.sep = "";
log.ends = "\n";
log.mode = "a+";
log.thinkId = nil;
log.logs = {}

local logOff = function( name )
	return log.logs[name] == true or log.on == false;
end

function log:setState( name, bState )
	self.logs[ name ] = not bState;
end

-- when set will only allow log entries from ais with this thinkId
function log:setThinkId( thinkId )
	if ( self.thinkId == nil ) then
		self.thinkId = thinkId;
	end
end

-- clear a log file
function log:clear( fname )
	if logOff( fname ) then return; end
	io.open(fname .. ".log", "w"):close();
end

-- allows to check for thinkId before erasing
function log:clearEx( ai, fname )
	if ( self.thinkId ~= nil and ai:GetNpcThinkParamID() ~= self.thinkId ) then return; end
	self:clear( fname );
end

function log:section( ai, logname )
	if logOff( logname ) then return; end
	if ( self.thinkId ~= nil and ai:GetNpcThinkParamID() ~= self.thinkId ) then return; end
	local f = io.open( logname .. ".log", self.mode );
	f:write "------------------------------------------------------\n";
	f:close();
end

setmetatable( log, {
	__call = function ( self, ai, logname, ... )
	
		if logOff( logname ) then return; end
		if ( self.thinkId ~= nil and ai:GetNpcThinkParamID() ~= self.thinkId ) then return; end
		
		if logname == nil then logname = "log_" .. ai:GetNpcThinkParamID(); end
		
		local f = io.open( logname .. ".log", self.mode );
		
		if self.showTime then
			local date = os.date("*t");
			f:write( string.format("[%02d:%02d:%02d]", date.hour, date.min, date.sec), " " );
		end
		f:write( ai:GetNpcThinkParamID(), ": " );
		
		for i = 1, arg.n do
			f:write( tostring(arg[i]), self.sep );
		end
		f:write( self.ends );
		f:close();
		
	end
} );

-- plunge attack goal
-- param 1: target with which to measure height
-- param 2: height at which we'll perform R1
GOAL_WalkAndPlunge = 27499;
REGISTER_GOAL(GOAL_WalkAndPlunge, "WalkAndPlunge");
REGISTER_GOAL_UPDATE_TIME(GOAL_WalkAndPlunge, 0, 0);
REGISTER_GOAL_NO_INTERUPT(GOAL_WalkAndPlunge, true);

function	WalkAndPlunge_Activate(ai, goal)
	-- walk off
	ai:SetAttackRequest( NPC_ATK_Up );
end

function	WalkAndPlunge_Update(ai, goal)

	local target = goal:GetParam(0);
	local margin = goal:GetParam(1);
	-- log( ai, "bt", ai:GetDistYSigned(target));
	-- if we below height for plunge - do it
	if ( margin <= ai:GetDistYSigned(target) ) then
		ai:SetAttackRequest( NPC_ATK_R1 );
		-- if we hit an enemy or too low - end goal
		if ( ai:GetDistY(target) <= 1 ) then
			return GOAL_RESULT_Success;
		end
	else
		-- walk off
		ai:SetAttackRequest( NPC_ATK_Up );
	end
	
	return GOAL_RESULT_Continue;
	
end

function	WalkAndPlunge_Terminate(ai, goal)	end
function	WalkAndPlunge_Interupt(ai, goal)	return false;	end

