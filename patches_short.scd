~scenetypes["tracer"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var son, sub;
	var pos, trig, rawson, scaler, panenv, thruspeed, env;
	var bangs = ~npendulums.collect{|index| ("bang%".format(index)).asSymbol.tr(0) };
	//scaler = MouseX.kr(0.5, 5, 1); //.poll(1, "mousex");
	scaler    = ~pendvalto3val_exp.value(pendspos[0][1], threevals[0]).linexp(0,1, 0.5, 5); // NOTE READING FROM ZEROTH PEND ONLY
	thruspeed = ~pendvalto3val_exp.value(pendspos[0][0], threevals[1]); // NOTE READING FROM ZEROTH PEND ONLY
	/*
	trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2 * (~normalperiod * In.kr(~tempobus)));
	rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, MouseY.kr(100, 10000).poll(0.05, "mousey topfreq")), phase: 0.5pi);
	env = EnvGen.ar(Env.perc(0, 0.1), trig, timeScale: scaler);
	rawson = rawson * env;
	rawson = HPF.ar(rawson, 5000) * 0.25;
	*/
	// Now we delay-and-splay it so as to zap across speakers
	son = ~npendulums.collect{|which|
		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), bangs[which], timeScale: scaler).exprange(0.15, MouseY.kr(100, 10000)), phase: 0.5pi);
		env = EnvGen.ar(Env.perc(0, 0.1), bangs[which], timeScale: scaler);
		rawson = rawson * env;
		rawson = HPF.ar(rawson, 5000) * 0.25;
		/*
		var del = (~npendulums - which) * 0.06;
		DelayC.ar(rawson, del * 4, del * thruspeed.reciprocal);
		*/
	};
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	/*
	son.do{|oneson, which|
	var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
	sub[reindex] = sub[reindex] + LPF.ar(FreeVerb.ar(LPF.ar(oneson, 1000, 2) * BrownNoise.ar * 50, 0.5, 0.5, 0.99999), 100);
	};
	*/
	~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize, pendspos:pendspos) // no width
}, [["zappiness", 0], ["thruspeed", 1]]];
~scenetypes["tracerbeep"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var son, sub;
	var pos, trig, rawson, scaler, env, panenv;
	var reltempo = ~normalperiod * In.kr(~tempobus);
	var bangs = ~npendulums.collect{|index| ("bang%".format(index)).asSymbol.tr(0) };
	// TEMPORARY
	bangs = ~npendulums.collect{|index| Dust.kr(0.1) };
	/*
	trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2 * reltempo);

	//rawson = (SinOsc.ar(1300 * [1,3,5,7]).mean * MouseY.kr(2,4)).clip2;
	rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
	env = EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(trig, dur: 0.1));
	rawson = rawson * 0.4 * env;
	*/
	// Now we delay-and-splay it so as to zap across speakers
	son = ~npendulums.collect{|which|
		var amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
		var distort = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);

		rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
		env = EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(bangs[which], dur: 0.1));
		rawson = rawson * 0.4 * env * amp;
	};
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	son.do{|oneson, which|
		var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
		sub[reindex] = sub[reindex] + LPF.ar(FreeVerb.ar(LPF.ar(oneson, 100) * BrownNoise.ar * 50, 0.5, 0.5, 0.999), 100);
	};
	~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize, pendspos:pendspos) // no width
}, [["amp", 1], ["distort 0--1", [0, 0.4, 0]]]];

~scenetypes["scanbip"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var son, sub;
	var pos, trig, rawson, scaler, panenv, thruspeed, env;
	var bangs = ~npendulums.collect{|index| ("bang%".format(index)).asSymbol.tr(0) };

	bangs = bangs.sum; // unify, bang one bang all
	env = EnvGen.ar(Env([0, 0.1, 0.1, 0.3, 0.3, 2.5, 2, 2, 0, 0], [ 0.04, 0.8, 0.02, 0.5, 0.002, 0.02, 0.06, 0.002, 0.6 ]), bangs);
	son = SinOsc.ar(1300 * 3.midiratio * [1,6,10,11], 0.5pi, mul: [1.1, 1, 1, 1]).mean.clip2;
	son = son * env * 0.4;
	son = (son * 0.1).dup(~npendulums);

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize, pendspos:pendspos) // no width
}, []];

~scenetypes["blipff"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var son, sub;
	var pos, trig, rawson, scaler, panenv, thruspeed, env;
	var bangs = ~npendulums.collect{|index| ("bang%".format(index)).asSymbol.tr(0) };
	var penv, freq, verb;

	bangs = bangs.sum; // unify, bang one bang all
	freq = 1300 * 5.midiratio * EnvGen.kr(Env([0.5, 0.5, 2, 2, 0.5], [0.02, 0.001, 2, 0]), bangs);
	son = SinOsc.ar(freq);
	env = EnvGen.ar(Env.perc(0.0, 0.25), bangs);
	verb = (LPF.ar(son * BrownNoise.ar, 150) * 8) + (son * 0.005);
	verb = verb * EnvGen.ar(Env(
		[0,   0,   1,   0,    1,   0,    1,   0,   0],
		[    0.4, 0.55, 0.15, 0.01, 0.08, 0.01, 0.1, 0.9] * 1.5, curve:'step'), bangs).lag(0.001);
	son = son * env * 0.1;
	son = son + (verb * 0.9);

	son = HPF.ar(son, 120);
	son = MidEQ.ar(son, 600, 2,   -24); // notch out for betterness
	son = MidEQ.ar(son, 300, 2,   -24); // notch out for betterness

	son = (son * 0.2).dup(~npendulums);

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize, pendspos:pendspos) // no width
}, []];


