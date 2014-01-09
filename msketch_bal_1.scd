s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.05)}.play(s, addAction:\addToTail); //~ssh.free
~twelve.scope;

~dobuf = Buffer.alloc(s, 65536, 2);
~dobuf.write("~/git/uvacurve/recordings/recorded.wav".standardizePath, "wav", "int24", 0, 0, true);
// then record, then
x.free;
~dobuf.close;
~dobuf.free; ~dobuf = nil;

(
x = {
	// bal purity1
	var sons;
	sons = 12.collect{|val|
		var son;
		son = SinOsc.ar(Array.series(4, 1, 1) * 60.midicps * LFDNoise0.ar(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.5)).sum * 0.1;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)

(
x = {
	// bal purity2
	var sons;
	sons = 12.collect{|val|
		var son;
		son = ([1,16].collect{|val| SinOsc.ar(val * Array.series(8, 1, 1) * 51.midicps * LFDNoise0.kr(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(8, 0.5, 0.125)).sum * 0.1;
	} * [1, 0.002]).sum;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)

