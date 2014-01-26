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


(
x = { // misc passingzero
	var son, sub, leds;
	son = 12.collect{|which|
		var tester = (LFPar.kr(ExpRand(0.1, 0.2), Rand(pi))).sign;
		var env = EnvGen.ar(Env.perc(0.01, 0.1), HPZ1.kr(tester));
		SinOsc.ar((83 + which).midicps, 0, env) * 0.2;
	};
	son = son * 3;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(son))};
	Out.ar(~twelve, son);
	Splay.ar(son)
}.play
)
x.free;


(
x = { // misc puresine03
	var son, sub, leds, freqscale=1, basefreq=120;
	son = 12.collect{|which|
		var amp, modrate;
		amp     = 1;
		modrate = ExpRand(0.2, 0.25);
		(
			(SinOsc.ar([basefreq * 0.5] * freqscale)) * 0.1 * SinOsc.ar(0.25 * modrate).range(0.5, 1)
			+
			(SinOsc.ar([basefreq * 2.0] * freqscale)) * 0.1 * SinOsc.ar(1 * modrate).range(0.5, 1)
		).sum * amp
	};
	son = son * 0.4;
	son.postln;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(son))};
	Out.ar(~twelve, son);
	Splay.ar(son)
}.play
)
x.free;


(
x = { // misc tonestack01sin
	var son, sub, leds, freqscale=1, basefreq=120;
	var freqsel;

	var basefreqs = [60, 90, 120, 240, 480].scramble * 0.5 * freqscale;
	var harmstack = [1, 1.5, 2];
	var harmamps = [1.5, 0.4, 0.1];

	var freqs = basefreqs.collect{|bfreq| Array.series(12, bfreq, 0)};

	var fmlfo = LFNoise0.ar(400);

	son = harmstack.mean{|val, harmindex|
		freqs.collect{|afreq, which|
			var fmdepth = 0; //  ~pendvalto3val_lin.value(pendspos[which][1], threevals[0]) * 0.5;
			var freqscale2 = 1; //~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
			var fm = fmlfo.exprange(1 - fmdepth, 1 + fmdepth);
			SinOsc.ar(afreq * val * freqscale2 * (fm * harmindex), mul: 0.05 * harmamps[harmindex])
		};
	};

	freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/30, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
	//freqsel.poll;
	son = (son * freqsel).sum;

	son = 12.collect{|which|
		son[which] * SinOsc.ar(0.125, (4-which) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)
	}; // pow 0.25 makes move smoothly across speakers; higher, atomised.

	son = son * 20;

	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(son))};
	Out.ar(~twelve, son);
	Splay.ar(son)
}.play
)
x.free;



(
x = { // misc drift_sine
	var son, sub, leds, freqscale=1, basefreqs;
	var amps, harmstack, harmamps, freqs, freqsel;

	//basefreqs = [120, 180, 240, 360, 480].scramble;
	basefreqs = [120, 130] * 3 * freqscale;
	harmstack = [1, 1.5, 2];
	harmamps = [1.5, 0.4, 0.1];

	freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

	son = harmstack.mean{|val, harmindex|
		freqs.collect{|afreq, which|
			var freqscale2 = 1;
			SinOsc.ar(afreq * val * freqscale2 * harmindex, mul: 0.05 * harmamps[harmindex])
		};
	};

	freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/20, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
	//freqsel.poll;
	son = (son * freqsel).sum;

	son = son * 0.5; // Deliberately making it MORE subtle than the main bed

	amps = ~npendulums.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly across speakers; higher, atomised.

	son = son * amps * 15;


	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(son))};
	Out.ar(~twelve, son);
	Splay.ar(son)
}.play
)
x.free;

