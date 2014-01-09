s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.05)}.play(s, addAction:\addToTail); //~ssh.free
s.scope(1);

~dobuf = Buffer.alloc(s, 65536, 1);
~dobuf.write("~/git/uvacurve/recordings/sub_recorded.wav".standardizePath, "wav", "int24", 0, 0, true);
// then record, then
x.set(\gate, 0);
~dobuf.close;
~dobuf.free; ~dobuf = nil;

(
x = {|gate=1|
	// sub simplest
	var son;
	son = SinOsc.ar(32.midicps);
	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Splay.ar(son.dup * 0.3);
}.play;
)

(
x = {|gate=1|
	// sub intersimple
	var son;
	son = SinOsc.ar([32, 31].midicps, mul:[1, LFPar.kr(0.1).range(0, 1)]).mean;
	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Splay.ar(son.dup * 0.3);
}.play;
)

