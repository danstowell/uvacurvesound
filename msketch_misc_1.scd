s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.1)}.play(s, addAction:\addToTail); //~ssh.free; x.free;
~twelve.scope;

~dobuf = Buffer.alloc(s, 65536, 1);
~dobuf = Buffer.alloc(s, 65536, 2);
~dobuf.write("~/git/uvacurve/recordings/recorded.wav".standardizePath, "wav", "int24", 0, 0, true);
// then record, then
x.free;
~dobuf.close;
~dobuf.free; ~dobuf = nil;


(
x = { // short scanbip
	var son, env, penv;

	env = EnvGen.ar(Env([0, 0.1, 0.1, 0.3, 0.3, 2.5, 2, 2, 0, 0], [ 0.04, 0.8, 0.02, 0.5, 0.002, 0.02, 0.06, 0.002, 0.6 ]), doneAction: 2);
	son = SinOsc.ar(1300 * 3.midiratio * [1,6,10,11], 0.5pi, mul: [1.1, 1, 1, 1]).mean.clip2;
	son = son * env * 0.4;

	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Out.ar(~twelve, son);
	son.dup
}.play
)
x.free;


(
x = { // short blipff
	var son, env, penv, freq, verb;

	freq = 1300 * 5.midiratio * EnvGen.kr(Env([0.5, 0.5, 2, 2], [0.02, 0.001, 20]));
	son = SinOsc.ar(freq);
	env = EnvGen.ar(Env.perc(0.0, 0.25));
	//	son = son + CombN.ar(son, 0.01, 0.05, 0.5);
	//	verb = FreeVerb.ar(son * BrownNoise.ar, 1, mul: 20).tanh;
	verb = (LPF.ar(son * BrownNoise.ar, 150) * 8) + (son * 0.005);
	verb = verb * EnvGen.ar(Env(
		[0,   0,   1,   0,    1,   0,    1,   0,   0],
		[    0.4, 0.55, 0.15, 0.01, 0.08, 0.01, 0.1, 0.9] * 1.5, curve:'step'), doneAction: 2).lag(0.001);
	son = son * env * 0.1;
	son = son + (verb * 0.9);

	son = HPF.ar(son, 120);

	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	Out.ar(~twelve, son);
	son.dup
}.play
)
x.free;


(
x = { // short tracerbeep

	var son;
	var pos, trig, rawson, scaler, env, panenv;
	//var reltempo = ~normalperiod * In.kr(~tempobus);
	trig = 1; //Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2 * reltempo);

	rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
	env = EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(trig, dur: 0.1));
	rawson = rawson * 0.4 * env;

	// Now we delay-and-splay it so as to zap across speakers
	son = 12.collect{|which|
		var amp     = 1; // ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
		var distort = 0.7; // ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
		var del = which * 0.06;
		DelayC.ar((rawson * distort.linexp(0, 1, 1, 10)).atan, del, del) * amp;
	};

	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(son))};
	Out.ar(~twelve, son);
	Splay.ar(son)
}.play
)
x.free;

