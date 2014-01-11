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
	Splay.ar(son.dup * 0.7);
}.play;
)

(
x = {|gate=1|
	// sub intersimple2
	var son;
	son = SinOsc.ar([34, 33.5].midicps, mul:[1, LFPar.kr(0.1).range(0, 1)]).mean;
	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Splay.ar(son.dup * 0.7);
}.play;
)

(
x = {|gate=1|
	// sub intersimple_golo
	var son;
	son = SinOsc.ar([30, Line.kr(30.15, 30, 150)].midicps, mul:[1, LFPar.kr(0.1).range(0, 1)]).mean;
	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Splay.ar(son.dup * 0.7);
}.play;
)

(
x = {|gate=1|
	// sub interpulse
	var son;
	son = 2.collect{|which|
		var trig = Impulse.kr(0.2, which * 0.5);
		var env = EnvGen.ar(Env.linen(0.1, 6, 4), trig);
		var note = TIRand.kr(28, 33, trig);
		son = SinOsc.ar(note.midicps, mul:env);
	}.mean;

	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Splay.ar(son.dup * 0.7);
}.play;
)


(
x = {|gate=1|
	// sub riffle verb - MEH - it's beautiful but it's not for this gig
	var son, nu;
	var addmidi = 0;//MouseX.kr(0, 40).round.poll(1);
	son = (([34] + addmidi).midicps.collect{|freq, inwhich|
		var trig = Dust2.kr(1);
		var lev  = Latch.kr(trig, trig.abs);
		SinOsc.ar(freq + EnvGen.ar(Env.perc(0.01, 0.1), trig.abs, 15 * lev))
	} * [1]).sum * 0.9;
	nu = FreeVerb.ar(son * LPF.ar(WhiteNoise.ar, 100), 1) * 10;
	son = XFade2.ar(son, nu, LFSaw.kr(ExpRand(0.08, 0.12), Rand(pi)));
	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Out.ar(~twelve, son);
	Splay.ar(son.dup);
}.play;
)
x.free;

(
x = {|gate=1|
	// sub subriffle
	var son, nu;
	var addmidi = 0;//MouseX.kr(0, 40).round.poll(1);
	son = (([34, 46] + addmidi).midicps.collect{|freq, inwhich|
		var trig = Dust2.kr(0.8);
		var lev  = Latch.kr(trig, trig.abs) - 0.5;
		SinOsc.ar(freq + EnvGen.ar(Env.perc(0.4, 0.4), trig.abs, 5 * lev))
	} * [1, 0.1]).sum * 0.7;
	son = son * (1-EnvGen.ar(Env.perc(1.5, 1, 0.75), Dust.kr(0.1))); // occasional gentle release
	son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Out.ar(~twelve, son);
	Splay.ar(son.dup);
}.play;
)
x.free;
