~scenetypes["hi_ring_ding"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub;
	son = ~npendulums.collect{|which|
		var son, env;
		env = HPF.ar(EnvGen.ar(Env.perc(0.001, 0.1), Dust.ar(100)), 10000);
		son = LeakDC.ar(Ringz.ar(env, 16.collect{exprand(800, 12000)} * 3).mean * 1.5);
		//son = BPF.ar(son, 800) * 8;
		son = HPZ1.ar(son) * 2;
		son = LPF.ar(son, 10000);
		son
	};
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos, movewith:false)
}, [["[unused]", 0], ["[unused]", 0]]];

~scenetypes["hi_slippytick"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub;
	var sons, rate, ourdevrate;
	rate = LFDNoise1.kr(0.1).range(10, 20) * XLine.kr(0.1, 1, 1);
	ourdevrate = LFDNoise1.kr(0.05).range(0.05, 0.1);
	sons = ~npendulums.collect{|which|
		var son;
		var dev = (LFTri.kr(ourdevrate) + LFDNoise1.kr(0.1, 0.3)).max(0) * 0.1;

		son = Impulse.ar(rate /* 25 */ /* * ExpRand(20, 30) */ ) * WhiteNoise.ar;

		son = son + 3.collect{
			DelayN.ar(son, 0.1, dev * Rand(0, 1))
		}.sum
	};
	sons = LPF.ar(HPF.ar(sons, 5000), 10000); // * 1.5;
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos, movewith:false)
}, [["[unused]", 0], ["[unused]", 0]]];

~scenetypes["hi_fabrickle"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|
		var son, env, trig;
		trig = Dust.ar(LFPulse.kr(ExpRand(0.05, 0.1), Rand(0, 2)).range(30, 100));
		son = EnvGen.ar(Env.perc(0.002, 0.01), trig, timeScale:TExpRand.kr(0.5, 2, trig));
		son = HPF.ar(son, 10000);
		son = Klank.ar(`[24.collect{exprand(14000, 18000)}, nil, 24.collect{0.1}], son);
		son = son * 3.3;
	};
	sons = LPF.ar(sons, 10000);
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos, movewith:false)
}, [["[unused]", 0], ["[unused]", 0]]];

~scenetypes["hi_clickwerk"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub;

	var trig;

	trig = Impulse.ar( Duty.kr(0.5, 0, Dxrand([5, 10, 15].stutter(3) ++ [20, 40], inf))  );
	trig = trig * LFPulse.ar(1/16);
	son = Decay2.ar(trig, 0.008, 0.02) * LPF.ar(HPF.ar(WhiteNoise.ar, 10000), 15000);
	son = son + HPF.ar(son, 1000); // following speaker review, push the top
	son = (son * 0.6).dup(~npendulums);
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos, movewith:false)
}, [["[unused]", 0], ["[unused]", 0]]];

~scenetypes["hi_tring"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sub;
	var sons, trig1, trig2;

	trig1 = Impulse.kr(3.1 / 16);
	trig1 = Trig1.kr(CombN.kr(trig1, 0.05, 0.05, 1) - 0.05, 0);
	trig2 = Impulse.kr(3.1 / 1);

	sons = 8.collect{|which|
		var son, env, penv, onetrig, freq;
		onetrig = CoinGate.kr(0.15, trig1) + CoinGate.kr(0.25, trig2);
		penv = EnvGen.ar(Env.perc(0.05, 0.1), onetrig);
		env  = EnvGen.ar(Env.perc(0.05, 1),   onetrig);
		freq = IRand(116, 130).midicps; // [116, 130].midicps
		son = Saw.ar(freq * penv.linlin(0, 1, 1, 0.99)) * (GrayNoise.ar(0.1)+1);
		son = son * freq.linlin(5000, 15000, 0.4, 1.2);
		son = son * 0.2 + LPF.ar(son, 8000);
		son * env.linlin(0, 1, 0.02, 1)
	};

	sons = sons * 0.3;

	// They move around on the speakers, not tied
	sons = sons.collect{|son| PanAz.ar(12, son, LFNoise1.kr(0.5).range(0,2)) }.sum;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, [["[unused]", 0], ["[unused]", 0]]];


~scenetypes["dut_ter"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sub;

	var son, env, trig, dly, rate;

	rate = 3.1 / 8;
	dly = 1 / (rate * 8);
	trig = Impulse.kr(rate);

	env = EnvGen.ar(Env.perc(0.01, 0.01, 0.3), trig) - EnvGen.ar(Env.perc(0.01, 0.01), DelayN.kr(trig, dly, dly));

	son = Klank.ar(`[[347, 753, 1500, 3523, 7710, 1610], nil, [0.1, 0.05, 0.05, 0.05, 0.05, 0.05]], env);

	son = (son * 0.1).dup(~npendulums);

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos, movewith:false)
}, [["[unused]", 0], ["[unused]", 0]]];

