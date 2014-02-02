~scenetypes["unbal_clustpot"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

	var sub;
	var clusts, sons;

	clusts = 4.collect{
		4.collect{
			var freq = TIRand.kr(45, 65, Dust.kr(0.03)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
	sons = sons * 1.5;
	sons = MidEQ.ar(sons, 250, 1,   -12); // notch out a buzz on the cone
	sons = MidEQ.ar(sons, 120, 1,   -6); // notch out a buzz on the cone
	sons = sons.stutter(3) * 0.03;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["unbal_clustpot_hi"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

	var sub;
	var clusts, sons;

	clusts = 4.collect{
		4.collect{
			var freq = TIRand.kr(75, 95, Dust.kr(0.03)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
	sons = MidEQ.ar(sons, 1250, 1,   -6, mul: 1.4); // notch out a slightly piercing bit
	sons = sons.stutter(3) * 0.0003;

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["unbal_singrain_mover"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sub;

	var sons, freqs = ([55, 56, 57] ++ ((48,51..52)+12).dup(7).flatten).scramble.midicps;
	var range = 6;
	var bigpos = LFPar.kr(0.05, pi.rand).range(freqs.size-1-range);
	sons = 3.collect{
		var pos = WhiteNoise.kr.range(0, range) + bigpos;
		GrainSin.ar(12, Dust.ar(30), 1.95, Index.kr(freqs.as(LocalBuf), pos), LFNoise0.kr(10).range(0,2)) * 0.3;
	}.mean;
	sons = (sons * 0.33) +  (LPF.ar(sons, 500) * 0.1);
	sons = MidEQ.ar(sons, 250, 1,   -6); // notch out a buzz on the cone
	sons = MidEQ.ar(sons, 120, 1,   -6); // notch out a buzz on the cone
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["unbal_diffle"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var freq = \freq.kr(65.midicps);

	var sons, sub;
	// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, and they settle back slowly
	sons = 12.collect{|val|
		var son;
		var addmidi = 7; //MouseX.kr(-20, 20).round.poll(1);
		son = ((freq * [1, 1.5]).collect{|freq, inwhich|
			var trig = Dust2.kr(1);
			var lev  = Latch.kr(trig, trig.abs).abs.neg;
			SinOsc.ar(freq * LFNoise1.kr(0.1).exprange(0.975, 1.025) + EnvGen.ar(Env.perc(0.1, 1.9), trig.abs, 20 * lev))
		} * [1.5, 0.07]).sum * 0.07;
		son = MidEQ.ar(son, 160, 0.5, -6); // notch out a buzz on the cone
		son = MidEQ.ar(son, 500, 1,   -6); // notch out a buzz on the cone
	};
	sons = sons.collect{|son|
		var nu = FreeVerb.ar(son * HPF.ar(WhiteNoise.ar, 10000), 1) * 0.1;
		XFade2.ar(son, nu, LFSaw.kr(0-ExpRand(0.08, 0.12), Rand(pi)));
	};


	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];
