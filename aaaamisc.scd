s.boot
// 1/[0.08, 0.13]
// 3.4 towards 6

~scenepossynths[1].set(\rapidity, 1)
~scenepossynths[1].set(\rapidity, 3)


~ledbus.scope

s.scope(4)
s.scope(12)


s.dumpOSC(1);
s.dumpOSC(0);

FreqScope()


~buspoll = {  In.kr(~pendbus.index, 2).poll; DC.ar(0)  }.play(addAction: \addToTail);
~buspoll.free

~pendbus.setn((0..11));

~scenevalpointsbus[0].setAt(2, 1.111111111111)
~scenevalpointsbus[0].subBus(3).set(2.2222222222222)
~scenevalpointsbus[0].get{|data| data.postln}

OSCFunc

thisProcess.openUDPPort(7400); // attempt to open 1121
thisProcess.openPorts; // list all open ports


n = NetAddr.new("127.0.0.1", 7400);    // create the NetAddr
// create the OSCresponderNode
OSCFunc
o = OSCFunc({ arg msg, time, addr, recvPort; [msg, time, addr, recvPort].postln; }, nil, n);
o.free;    // remove the OSCFunc when you are done.
OSCFunc.trace(true)
OSCFunc.trace(false)


// num,   then x y z data
OSC Message Received:
	time: 1087.809581276
	address: a NetAddr(11.0.0.100, 7400)
	recvPort: 7400
	msg: [ /d3/sound/p, 16, 16, 1, 0, 0, -0.1642844825983, -3.3749113082886, -0.91268086433411, -1.2881854772568, -0.013946603052318, 0.28367027640343, 1, 0, -0.81597775220871, -3.3837862014771, -0.36629500985146, -1.0376437902451, 0.21326977014542, 0.34233912825584, 2, 0, -1.3075531721115, -3.2437949180603, 0.13452926278114, -0.66709589958191, 0.27774330973625, 0.21092183887959, 3, 0, -1.5990337133408, -3.076137304306, 0.48007446527481, -0.29058566689491, 0.16719406843185, 0.10316517204046, 4, 0, -1.7029126882553, ...etc...

// v is volume
OSC Message Received:
	time: 1087.829447409
	address: a NetAddr(11.0.0.100, 7400)
	recvPort: 7400
	msg: [ /d3/sound/v, 1 ]

	~sceneplayers[0].set(\circlesize, 4)
	~sceneplayers[0].set(\circlesize, 1)


	