
~scenetypes["elastic_boinger2d"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var sons, sub;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	sons = 12.collect{|chan|
		var son;
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.01));
			son = CombN.ar(son, 0.2, LFDNoise1.kr(0.03 * reltempo).exprange(0.01, 0.1) / reltempo.max(0.001), 40)
			+ CombC.ar(son, 0.2, LFDNoise1.kr(0.03 * reltempo).exprange(0.01, 0.1) / reltempo.min(0.001), 40);
		}.mean;
	};
	sons = sons + HPF.ar(sons, 1000, 0.25); // following review, push the top a bit
	sons = MidEQ.ar(sons, 300, 2, -6); // following review, pull to fix buzzing a little
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.25;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];


~scenetypes["elastic_boinger2d2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var sons, sub, noise=WhiteNoise.ar.range(0.9, 1);
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	sons = 12.collect{|chan|
		var son;
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * noise * EnvGen.ar(Env.perc(0.01, 0.02), Dust.kr(0.01));
			son = BPF.ar(son, 500);
			son = 2.collect{
				var wib = LFDNoise1.kr(0.08 * reltempo).exprange(0.03, 0.2) / reltempo.max(0.001);
				CombN.ar(son, 0.2, wib, 60) * ((HPZ1.kr(wib) > 0) + 0.3).lag(0.5)
			}.sum;
		}.mean;
	};
	sons = sons + HPF.ar(sons, 1000, 0.25); // following review, push the top a bit
	sons = MidEQ.ar(sons, 300, 2, -6); // following review, pull to fix buzzing a little
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.25;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_stickslip01"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var sons, sub;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;

	var stickslip = { |force|
		var inMotion, slipEvents, forceBuildup, evtAmp, evtDecayTime, evts;
		force = force.lag(0.1); // smoothing to get rid of volatile control changes
		inMotion = force > 0.1; // static friction: nothing at all below a certain force
		slipEvents = inMotion * Impulse.ar(reltempo * force.linlin(0.1, 1, 1, 1/0.003) * LFDNoise1.ar(50).squared.linexp(-1,1, 0.5, 2));
		forceBuildup = Phasor.ar(slipEvents, 10 * SampleDur.ir, 0, inf).min(1);
		evtAmp = Latch.ar(Delay1.ar(forceBuildup.sqrt), slipEvents);
		evtDecayTime = evtAmp.sqrt;
		evts = EnvGen.ar(Env.perc(0.001, 1), slipEvents, evtAmp, 0, evtDecayTime * 0.01 * TExpRand.kr(0.5, 2, slipEvents)) * LPF.ar(BrownNoise.ar, 80);
	};
	var squarepanel = { |inputs|
		var times, filt;
		// times in milliseconds, converted to seconds:
		times = [4.52, 5.06, 6.27, 8, 5.48, 7.14, 10.12, 16] * 0.001;
		filt = inputs.asArray.collect{|input| DelayC.ar(input, times, times).mean };
		filt = HPF.ar(filt, 125);
		filt * 4
	};
	var woodfilter = { |inputs|
		var freqs, rqs, output;
		freqs = [62.5, 125, 250, 395, 560, 790];
		rqs   = 1 / [1, 1, 2, 2, 3, 3];
		output = inputs.asArray.collect{|input| BPF.ar(input, freqs, rqs).sum + (input*0.2)};

	};

	sons = squarepanel.value(woodfilter.value(3.collect{
		var chanphase = pi.rand;
		2.collect{|phase|
			var force; //= MouseX.kr; //LFPar.kr(ExpRand(0.01, 0.04), pi.rand).range(0.0, 0.9);
			force = LFSaw.kr(ExpRand(-0.03, -0.02), phase + chanphase).linexp(-1, 1, 0.1, 1.2) + Line.kr(2, 0, 3);
			stickslip.value(force) * XLine.ar(0.001, 1, 3)
			// * BPF.ar(WhiteNoise.ar, 200, mul: 3)
			* (1-force)
		}.sum
	}));
	//sons = [sons, sons[1..] ++ sons[0]].mean;
	sons = sons.collect{|son, which| PanAz.ar(~npendulums, son, which * (2/3) + LFSaw.kr(0.1), width: 4)}.sum;// * 2;
	sons = sons + HPF.ar(sons, 1000, 0.25); // following review, push the top a bit

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_boinger"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var sons, sub;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	sons = 12.collect{|chan|
		var son;
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.01));
			son = CombN.ar(son, 0.2, LFDNoise1.kr(0.03 * reltempo).exprange(0.01, 0.1) / reltempo.max(0.0001), 40);
		}.mean;
	};
	sons = sons + HPF.ar(sons, 1000, 0.25); // following review, push the top a bit
	sons = MidEQ.ar(sons, 300, 2, -6); // following review, pull to fix buzzing a little
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.25;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];


~scenetypes["elastic_harder"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var sons, sub;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	sons = 12.collect{|chan|
		var son;
		[48, 55, 60].collect{|val|
			var wib = LFDNoise1.kr(0.2).range(0, 0.05);
			son = BPF.ar(GrayNoise.ar, val.midicps * 2) * EnvGen.ar(Env.perc(0.03, 0.05), Dust.kr(0.025));
			son = CombC.ar(son, 0.4, (LFDNoise1.kr(0.05 * reltempo) + LFPar.kr(5 * reltempo, 0, wib)).linexp(-1, 1, 0.1, 0.4) / reltempo.max(0.0001), 20);
		}.mean;
	};
	sons = sons + HPF.ar(sons, 1000, 0.25); // following review, push the top a bit
	sons = MidEQ.ar(sons, 300, 2, -6); // following review, pull to fix buzzing a little
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.25;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_rip1plus1"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var son, sub;

	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	var stage, stagelag, evt, res;
	stage = LFSaw.kr(0.03, 0.7).range(-5, 1).max(0);
	stagelag = stage.lag(0.2, 0.2);
	evt = Dust2.ar(stagelag.pow(3) * 400);
	res = DynKlank.ar(`[10.collect{exprand(100, 400)}.postln, nil, 10.collect{0.1}], evt, stagelag.linexp(0, 1, 1, 10));
	son = (evt) + (res * 0.6 * BPF.ar(WhiteNoise.ar, stagelag.linexp(0, 1, 10000, 2000), 2));
	son = LPF.ar(son, stagelag.linexp(0, 1, 500, 10000));
	son = /* son + */ CombC.ar(LPF.ar(son, 5000) * BrownNoise.ar * 0.5 * stage.squared, 0.3, LFPar.ar(4).range(0.08, 0.09) / reltempo.max(0.0001), stagelag.linexp(0, 1, 75, 0.1));
	son = Normalizer.ar(son, dur: 1);
	son = son * 0.1;
	son = son + HPF.ar(son, 1000); // following speaker review, push the top
	son = son.dup(~npendulums);
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_stretch_balloon"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var son, sub;

	var stim;
	stim = EnvGen.ar(Env.perc(0.001, 0.001), Dust.ar(XLine.kr(100, 4, 2))) * XLine.ar(0.01, 1, 2);
	stim = stim * EnvGen.ar(Env.linen(0, 2.5, 0), 1);
	son = Klank.ar(`[20.collect{exprand(100, 500)}, nil, 20.collect{0.1}], stim).clip2(1) * 0.5;
	son = son + HPF.ar(son, 1000); // following speaker review, push the top
	son = son * 0.1;
	son = son.dup(~npendulums);
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_stretch_regular"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var son, sub;

	var stim;
	stim = EnvGen.ar(Env.perc(0.001, 0.001), Impulse.ar(XLine.kr(50, 3, 3))) * XLine.ar(0.01, 1, 3);
	stim = stim * EnvGen.ar(Env.linen(0, 3, 0), 1);
	son = Klank.ar(`[20.collect{exprand(100, 500)}, nil, 20.collect{0.1}], stim).clip2(1) * 0.5;
	son = son + HPF.ar(son, 1000); // following speaker review, push the top
	son = son * 0.1;
	son = son.dup(~npendulums);
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_stretch_stepped"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var son, sub;

	var stim;
	stim = EnvGen.ar(Env.perc(0.001, 0.001), Impulse.ar(XLine.kr(100, 3, 3).round(10))) * XLine.ar(0.01, 1, 3);
	stim = stim * EnvGen.ar(Env.linen(0, 3, 0), 1);
	son = Klank.ar(`[20.collect{exprand(100, 500)}, nil, 20.collect{0.1}], stim).clip2(1) * 0.5;
	son = son + HPF.ar(son, 1000); // following speaker review, push the top
	son = son * 0.1;
	son = son.dup(~npendulums);
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["elastic_arrow"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var son, sub;

	var sons, penv, aenv, panenv, trig=Trig1.kr(1);

	penv   = EnvGen.ar(Env([200, 200, 100, 20, 1], [0, 0.15, 0.15, 2]), trig) * LFPar.ar(10).exprange(0.9, 1.1);
	aenv   = EnvGen.ar(Env([1, 1, 0.22, 0.22], [1, 3, 5]), trig);
	panenv = EnvGen.ar(Env([1.8, 1.8, 0.2, 0.2], [0, 0.05, 20]), trig);

	son = LeakDC.ar(Pluck.ar(HPF.ar(WhiteNoise.ar, 10000), trig, 1, min(1, 1/penv), 15));
	son = LPF.ar(son, 1500);
	son = son * 40 * aenv;
	son = Normalizer.ar(son, dur: 1) * 10;
	son = son + HPF.ar(son, 1000); // following speaker review, push the top

	DetectSilence.ar(son, time: 0.5, doneAction: 2);

	sons = PanAz.ar(12, son, pos: panenv);

	sons = sons * 0.1;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];


~scenetypes["elastic_groanik"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var woodfilter = { |inputs|
		var freqs, rqs, output;
		freqs = [62.5, 125, 250, 395, 560, 790];
		rqs   = 1 / [1, 1, 2, 2, 3, 3];
		output = inputs.asArray.collect{|input| BPF.ar(input, freqs, rqs).sum + (input*0.2)};
		output = output.collect{|son| Klank.ar(`[freqs * 0.8, nil, 0.015.dup(freqs.size)], son) * 0.2};

		output = MidEQ.ar(output, 400, 0.5, -12); // following speaker review, brutal remove around 200--1000
		output = MidEQ.ar(output, 800, 0.5, -12); // following speaker review, brutal remove around 200--1000
	};

	var son, sub;

	var trigs, envlens, envs, reso, num=4, genrate;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;

	genrate = LFPar.kr(0.1).exprange(0.5, 2) * Line.kr(0.001, 1, 1) * reltempo;
	trigs   = num.collect{ Impulse.ar(genrate * LFNoise1.kr(1).exprange(4, 50))};
	envlens = num.collect{ LFNoise1.kr(1).exprange(0.1, 10) };

	envs = num.collect{|which|
		EnvGen.ar(Env.perc(0.000, 0.0001), trigs[which], timeScale: envlens[which]);
	};

	son = woodfilter.value(envs) * 0.15;
	son = son.wrapAt((0..~npendulums-1));
	son = son + HPF.ar(son, 1000); // following speaker review, push the top

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

