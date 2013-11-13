(
~fromport = 7400;
//~recvaddr = NetAddr.new("127.0.0.1", ~fromport);    // create the NetAddr
~recvaddr = NetAddr.new(nil, ~fromport);    // create the NetAddr
thisProcess.openUDPPort(~fromport); // attempt to open 1121
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
~d3func = { arg msg, time, addr, recvPort; if(recvPort==~fromport and: {msg[0].asString[0..8]=="/d3/sound"}){
	//msg.postln;
	msg[0].asString[10..].switch(
		"v", {
			//"it's v".postln;
		},
		"p", {
			//"it's p".postln;
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
		{"it's other: %".format(msg).postln;}
	);
};};
thisProcess.addOSCRecvFunc(~d3func);
)
/*
thisProcess.removeOSCRecvFunc(~d3func);