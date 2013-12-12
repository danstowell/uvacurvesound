(
~fromport = 7400;
//~recvaddr = NetAddr.new("127.0.0.1", ~fromport);    // create the NetAddr
~recvaddr = NetAddr.new(nil, ~fromport);    // create the NetAddr
thisProcess.openUDPPort(~fromport); // attempt to open

~ledsendaddr = NetAddr("10.0.0.123", 1234); // TODO ------------------------- get proper settings from Tiemen
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

(
// this ordering must match the ordering in the OSC messages from d3, and must list ALL the per-pendulum data
~perPendulumKeys = #[\normPosx, \normPosy, \normPosz, \normVelx, \normVely, \normVelz, \approxPeriod];

~d3func = { arg msg, time, addr, recvPort; if(recvPort==~fromport and: {msg[0].asString[0..8]=="/d3/sound"}){
	//msg.postln;
	msg[0].asString[10..].switch(
		"pendulum", {
			"Received OSC /d3/sound/pendulum with % args".format(msg.size - 1).postln;
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

			// TODO DO STUFF WITH THIS DATA ***********************



		},
		"v", {
			//"it's v".postln;     // <----------- no longer needed, old api
		},
		"p", {
			//"it's p".postln;     // <----------- no longer needed, old api
			var npend = msg[1];
			var offset;
			var pendinfo = npend.collect{|n|
				offset = 4 + (n * 8);
				[msg[offset+2..offset+4], msg[offset+5..offset+7]]
			};
			//msg.postln;
			pendinfo = pendinfo[..11];
			//pendinfo.postln;
			if(~pendbus.notNil){
				~pendbus.setn(pendinfo.collect{|aninfo| aninfo[0][[0,2]]}.flat)
			};
		},
		{"it's other: %".format(msg[0]).postln;}
	);
};};
thisProcess.addOSCRecvFunc(~d3func);

//////////////////////////////////////////////////////////////////////
// receive led data from server and bounce it over to d3
~ledtod3func = { arg msg, time, addr, recvPort;
	var vals;
	if(addr.port==s.addr.port and: {msg[0].asString=="/d3/lights/set"}){
		vals = msg[3..];
		"==> Received OSC LED data from server with % values".format(vals.size).postln;
		// boing the values over to d3
		~ledsendaddr.sendMsg(["/d3/lights/set"] ++ vals);
	};
};
thisProcess.addOSCRecvFunc(~ledtod3func);
)
/*
thisProcess.removeOSCRecvFunc(~d3func);
thisProcess.removeOSCRecvFunc(~ledtod3func);