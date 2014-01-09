(
~fromport = 7400;
//~recvaddr = NetAddr.new("127.0.0.1", ~fromport);    // create the NetAddr
~recvaddr = NetAddr.new(nil, ~fromport);    // create the NetAddr
thisProcess.openUDPPort(~fromport); // attempt to open

~ledsendaddr = nil;
//~ledsendaddr = NetAddr("10.0.0.123", 1234); // TODO ------------------------- get proper settings from Tiemen
);

/*
OSCFunc.trace(true)
OSCFunc.trace(false)
*/

/////////////////////////////////
// Test
//OSCdef.newMatching(\vol, { arg msg, time, addr, recvPort; "Received volume %".format(msg[1]).postln; }, "/d3/sound/v" recvPort: ~fromport);
//OSCdef(\vol).enable
//OSCFunc.newMatching({|msg, time, addr, recvPort| \matching.postln}, '/d3', ~recvaddr); // path matching
//o.free;    // remove the OSCFunc when you are done.
/* To send self data:
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound", 1, 1, 9.809, 1,1,1, 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound", 1, 1, 0.809, 1,1,1, 0)
*/

(
// this ordering must match the ordering in the OSC messages from d3, and must list ALL the per-pendulum data
~perPendulumKeys = #[\normPosx, \normPosy, \normPosz, \normVelx, \normVely, \normVelz, \approxPeriod];

if(~d3func.notNil){thisProcess.removeOSCRecvFunc(~d3func)};
~d3func = { arg msg, time, addr, recvPort; if(recvPort==~fromport and: {msg[0].asString[0..8]=="/d3/sound"}){
	//msg.postln;
	//"Received OSC /d3/sound with % args".format(msg.size - 1).postln;
	var volume, timeIncrement, gravityMag, gravityDir, numPendulums, penddata, offset;

	volume        = msg[1].asFloat;
	timeIncrement = msg[2].asFloat;
	gravityMag    = msg[3].asFloat;
	gravityDir    = msg[4..6].asFloat;
	numPendulums  = msg[7].asInt;

	penddata = numPendulums.collect{|whichpend|
		offset = 8 + (~perPendulumKeys.size * whichpend);
		~perPendulumKeys.collectAs({|key, whichkey| key -> msg[offset + whichkey].asFloat}, IdentityDictionary);
	};

	// TODO UPDATE GLOBAL TEMPO IF CHANGED (use gravityMag? timeIncrement? mean of \approxPeriod?)
	// ~settempo.(newtempo)
	"Received /d3/sound - gravityMag %, timeIncrement %".format(gravityMag, timeIncrement).postln;
	~settempo.value((1/~normalperiod) * timeIncrement * sqrt(gravityMag / 9.81));

	// TODO DO STUFF WITH THIS DATA ***********************
};};
thisProcess.addOSCRecvFunc(~d3func);

//////////////////////////////////////////////////////////////////////
// receive led data from server and bounce it over to d3
if(~ledtod3func.notNil){thisProcess.removeOSCRecvFunc(~ledtod3func)};
~ledtod3func = { arg msg, time, addr, recvPort;
	var vals;
	if(addr.port==s.addr.port and: {msg[0].asString=="/d3/lights/set"}){
		vals = msg[3..];
		//"==> Received OSC LED data from server with % values".format(vals.size).postln;
		//vals.round(0.01).postln;
		// boing the values over to d3

		if(~ledsendaddr.notNil){~ledsendaddr.sendMsg(["/d3/lights/set"] ++ vals)};
	};
};
thisProcess.addOSCRecvFunc(~ledtod3func);
)
/*
thisProcess.removeOSCRecvFunc(~d3func);
thisProcess.removeOSCRecvFunc(~ledtod3func);