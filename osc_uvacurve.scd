(
~fromport = 7400;
//~recvaddr = NetAddr.new("127.0.0.1", ~fromport);    // create the NetAddr
~recvaddr = NetAddr.new(nil, ~fromport);    // create the NetAddr
thisProcess.openUDPPort(~fromport); // attempt to open

~ledsendaddr = nil;
//~ledsendaddr = NetAddr("10.0.0.123", 1234);
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
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/state", 1, 1, 9.809, 1,1,1, 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/state", 1, 1, 0.809, 1,1,1, 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tracer")
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/bang", 11)
12.do{|val| NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/bang", val) }
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tracerbeep")
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01sin", 1, "freqscale", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01tri02", 1, "freqscale", 1.2)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01tri02", 12, "freqscale", 1.2)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01sin", 0, "freqscale", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "freqscale", 0.5)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "freqscale", 2)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "width", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "width", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "amp", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "amp", 0.7)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "position", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "position", 4)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/setparam", "position", 5)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "silent")
s.dumpOSC(1);
s.dumpOSC(0);
*/

(
// this ordering must match the ordering in the OSC messages from d3, and must list ALL the per-pendulum data
~perPendulumKeys = #[\normPosx, \normPosy, \normPosz, \normVelx, \normVely, \normVelz, \approxPeriod];

if(~d3func.notNil){thisProcess.removeOSCRecvFunc(~d3func)};
~d3func = { arg msg, time, addr, recvPort;
	// "Received OSC % with % args".format(msg[0], msg.size - 1).postln;
	if(recvPort==~fromport and: {msg[0].asString[0..8]=="/d3/sound"}){
	var subaddr = msg[0].asString.split[3..];
	//msg.postln;
	//"Received OSC % with % args".format(msg[0], msg.size - 1).postln;
	msg[1..].postln;

	subaddr[0].switch("state", {
		var volume, timeIncrement, gravityMag, gravityDir, numPendulums, penddata, offset, pendspos;

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

		// Here we simply send the xy data to the bus
		pendspos = penddata.collect{|pend| [pend[\normPosx], pend[\normPosy]] }.flat;
		~pendbus.setn(pendspos);

		}, { // This is the default of the switch - we use this to drop into per-slot commands
			// not a "state" message
			var targetslot = subaddr[0].asInt;
			//"Will address slot #%".format(targetslot).postln;
			subaddr[1].switch(
				"bang",        { // args [pendulumid]
					// NB setting the trig to the group not the np, for low-latency
					~sceneplayers[targetslot].group.set(("bang%".format(msg[1].asInt)).asSymbol, 1);
				},
				"setparam",    { // args are just key-value pairs
					~sceneplayers[targetslot].set(*msg[1..]);
					// We have to handle "position" separately
					msg[1..].asArray.pairsDo{|k,v|
						if(k==\position){
							~sceneposbus.setAt(targetslot, v.asFloat / (~npendulums-1));
						};
					};
				},
				"changepatch", { // args [patchname, xfade] plus any number of key-value pairs
					~pushascene.value(msg[1] ? "silent", targetslot, (msg[2] ? 1).asFloat, msg[3..]);
				},
			); // end of switch
	});
};};
thisProcess.addOSCRecvFunc(~d3func);

)
/*
thisProcess.removeOSCRecvFunc(~d3func);

~sceneposbus.get{|data| data.postln;};"";