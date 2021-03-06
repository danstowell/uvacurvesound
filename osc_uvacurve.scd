(
~fromport = 7400;
//~recvaddr = NetAddr.new("127.0.0.1", ~fromport);    // create the NetAddr
~recvaddr = NetAddr.new(nil, ~fromport);    // create the NetAddr
thisProcess.openUDPPort(~fromport); // attempt to open

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
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/1/bang", 9)
Task{12.do{|val| NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/bang", val); 0.05.wait }}.play
Task{12.do{|val| NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/1/bang", val); 0.05.wait }}.play
12.do{|val| NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/bang", val)}
Task{12.do{|val| NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/bang", val); 0.05.wait }}.play
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tracerbeep")
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01sin", 1, "freqscale", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01tri02", 1, "freqscale", 1.2)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01tri02", 12, "freqscale", 1.2)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "tonestack01sin", 0, "freqscale", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/1/changepatch", "dut_ter", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "freqscale", 0.5)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "freqscale", 2)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "width", 1)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "width", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "amp", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "amp", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "amp", 0.5)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/2/params", "amp", 0.5)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "position", 0)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "position", 4)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/params", "position", 5)
NetAddr("127.0.0.1", ~fromport).sendMsg("/d3/sound/0/changepatch", "silent")
s.dumpOSC(1);
s.dumpOSC(0);
*/

(
// this ordering must match the ordering in the OSC messages from d3, and must list ALL the per-pendulum data
~perPendulumKeys = #[\pendIndex, \normAlpha, \normBeta, \speed];
// locally remembering scenepos so we don't send too many messages
~sceneposcache = ~nscenes.collect{-1};
~widthcache = ~nscenes.collect{-1};
~ampcache = ~nscenes.collect{-1};
~changepatchtimecache = ~nscenes.collect{-1}; // last time the patch change was requested - refuse to do too many
~osc_count = 0;
~osc_counter = Task{loop{10.wait;"OSC messages / sec: %".format(~osc_count / 10.0).postln; ~osc_count=0}}.play(AppClock);
// ~osc_counter.stop
if(~d3func.notNil){thisProcess.removeOSCRecvFunc(~d3func); ~osc_counter.stop; };
~d3func = { arg msg, time, addr, recvPort;
	// "Received OSC % with % args".format(msg[0], msg.size - 1).postln;
	~osc_count = ~osc_count + 1;
	if(recvPort==~fromport and: {msg[0].asString[0..8]=="/d3/sound"}){
		var subaddr = msg[0].asString.split[3..];
		//msg.postln;
		//"Received OSC % with % args".format(msg[0], msg.size - 1).postln;
		//msg[1..].postln;

		subaddr[0].switch("state", {
			var volume, maxAngle, timeIncrement, naturalness, speedMul, penddata, offset, pendspos;

			var pendulumParamOffset = 6;

			var expectedmsgparts = pendulumParamOffset + (~npendulums * ~perPendulumKeys.size);
			if(msg.size != expectedmsgparts){ "OSC /state: Expected len %, got %".format(expectedmsgparts, msg.size).postln };

			// "global" params
			volume        = msg[1].asFloat;
			maxAngle      = msg[2].asFloat;
			timeIncrement = msg[3].asFloat;
			naturalness   = msg[4].asFloat;
			speedMul      = msg[5].asFloat.min(5).max(0);
			//if(maxAngle==0){msg.postln};
			// "per-pendulum" params
			penddata = ~npendulums.collect{|whichpend|
				offset = pendulumParamOffset + (~perPendulumKeys.size * whichpend);
				// normalpha // angle +-1 along the curve
				// normbeta // angle +-1 sideways
				~perPendulumKeys.collectAs({|key, whichkey| key -> msg[offset + whichkey].asFloat}, IdentityDictionary);
			};

			//"Received /d3/sound/state - timeIncrement %".format(timeIncrement).postln;
			~settempo.value((1/~normalperiod) * timeIncrement);

			// Here we simply send the xy data to the bus
			pendspos = penddata.collect{|pend| [pend[\normAlpha], pend[\normBeta], pend[\speed] * speedMul] }.flat;
			if(pendspos.any{|val| val.abs==inf}){
				"infinity warning in the alpha/beta received from d3".postln;
			}{
				~pendbus.setn(pendspos);
			};

			},
			// This one is for banging ALL at once
			"bang",        { // args [pendulumid, ...]
				var setterlist = msg[1..].collect{|onebob| [("bang%".format(onebob.asInt)).asSymbol, 1]}.flat;
				//"Received OSC % with % args".format(msg[0], msg.size - 1).postln;
				// NB setting the trig to the group not the np, for low-latency
				//*
				s.makeBundle(nil, {
					~nscenes.do{|targetslot|
						~sceneplayers[targetslot].group.set(*setterlist);
					};
				});
				//*/
			},
			{ // This is the default of the switch - we use this to drop into per-slot commands
				// not a "state" message
				var targetslot = subaddr[0].asInt;
				//"Will address slot #%".format(targetslot).postln;
				subaddr[1].switch(
					"bang",        { // args [pendulumid, ...]
						var setterlist = msg[1..].collect{|onebob| [("bang%".format(onebob.asInt)).asSymbol, 1]}.flat;
						//"Received OSC % with % args".format(msg[0], msg.size - 1).postln;
						// NB setting the trig to the group not the np, for low-latency
						s.makeBundle(nil, {
							~sceneplayers[targetslot].group.set(*setterlist);
						});
					},
					"params",    { // args are just key-value pairs
						//"(set)params: args %".format(msg[0], msg.size - 1).postln;
						var pushparams = [];
						//~sceneplayers[targetslot].set(*msg[1..]);
						// We have to handle "position" separately
						msg[1..].asArray.pairsDo{|k,v|
							k.asSymbol.switch(
								\width, {
									if(v != ~widthcache[targetslot]){
										~widthcache[targetslot] = v;
										//"Received /d3/sound/params/% with width %".format(targetslot, v).postln;
									};
									pushparams = pushparams ++ [\width, v.asFloat / (~npendulums-1)];
								},
								\position, {
									if(v != ~sceneposcache[targetslot]){
										~sceneposcache[targetslot] = v;
										//"Received /d3/sound/params/% with new position %".format(targetslot, v).postln;
										~sceneposbus.setAt(targetslot, v.asFloat / (~npendulums-1));
									};
									pushparams = pushparams ++ [k, v];
								},
								// default
								{
									if(k.asSymbol==\amp and:{v != ~ampcache[targetslot]}){
										~ampcache[targetslot] = v;
										//"Received /d3/sound/params/% with new amp %".format(targetslot, v).postln;
									};
									pushparams = pushparams ++ [k, v];
								}
							);
						};
						~sceneplayers[targetslot].set(*pushparams);
					},
					"changepatch", { // args [patchname, xfade] plus any number of key-value pairs
						// NB msg[2] is NEXTPATCH, currently unused
						var timenow = Main.elapsedTime;
						if((timenow - ~changepatchtimecache[targetslot]) < 1){
							"    [changepatch too quickly, ignoring]".postln;
						}{
							"Received OSC % with % args".format(msg[0], msg.size - 1).postln;
							~pushascene.value(msg[1] ? "silent", targetslot, (msg[3] ? 1).asFloat, msg[4..]);
						};
						~changepatchtimecache[targetslot] = timenow;
					},
				); // end of switch
		});
};};
thisProcess.addOSCRecvFunc(~d3func);

)
/*
thisProcess.removeOSCRecvFunc(~d3func);

~sceneposbus.get{|data| data.postln;};"";
