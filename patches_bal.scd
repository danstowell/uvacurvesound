~scenetypes["bal_purity1"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var freq = \freq.kr(60.midicps);
	var son, sub;
	var moddepth = \modrate.kr(0).max(0); // these patches abuse "modrate" to indicate the depth of the swing ampmod
	son = ~npendulums.collect{|which|
		var son, swingpos;
		swingpos = (pendspos[which][0] + pendspos[which][1]);
		son = SinOsc.ar(Array.series(4, 1, 1) * freq * LFDNoise0.ar(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.5)).sum * 0.2;
		son = son * (swingpos * moddepth).linexp(0, 1, 1, 1e-4);
	};

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["bal_purity1lower"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var freq = \freq.kr((60-12).midicps);
	var son, sub;
	var moddepth = \modrate.kr(0).max(0); // these patches abuse "modrate" to indicate the depth of the swing ampmod
	son = ~npendulums.collect{|which|
		var son, swingpos;
		swingpos = (pendspos[which][0] + pendspos[which][1]);
		son = SinOsc.ar(Array.series(4, 1, 1) * freq * LFDNoise0.ar(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.5)).sum * 0.2;
		son = son * (swingpos * moddepth).linexp(0, 1, 1, 1e-4);
	};

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["bal_purity2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var freq = \freq.kr(51.midicps);
	var son, sub;
	var moddepth = \modrate.kr(0).max(0); // these patches abuse "modrate" to indicate the depth of the swing ampmod
	son = ~npendulums.collect{|which|
		var ason, swingpos;
		swingpos = (pendspos[which][0] + pendspos[which][1]);
		ason = ([1,16].collect{|val|
			SinOsc.ar(val * Array.series(8, 1, 1) * freq * LFDNoise0.kr(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(8, 0.5, 0.125)).sum * 0.1;
		} * [1, 0.002]).sum * 3;
		ason = ason * (swingpos * moddepth).linexp(0, 1, 1, 1e-4);
	};
	son = [son, BRF.ar(son, 160, 0.5, mul: 1)].mean; // notch out a buzz on the cone
	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];
~scenetypes["bal_riffle"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var freq = \freq.kr(51.midicps);
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	var sons, sub;
	// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, but not far and they settle back quickly
	sons = ~npendulums.collect{|val|
		var son;
		son = ((freq * [1, 1.5, 2]).collect{|freq, inwhich|
			var trig = Dust2.kr(reltempo);
			var lev  = Latch.kr(trig, trig.abs);
			SinOsc.ar(freq + EnvGen.ar(Env.perc(0.01, 0.1), trig.abs, 15 * lev))
		} * [1.5, 0.7, 0.25]).sum * 0.1;
		son = MidEQ.ar(son, 160, 0.25, -6); // notch out a buzz on the cone
		son = HPF.ar(son, 300);
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
~scenetypes["bal_riffle_note2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|
	var freq = \freq.kr(54.midicps);
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	var sons, sub;
	// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, but not far and they settle back quickly
	sons = ~npendulums.collect{|val|
		var son;
		son = ((freq * [1, 1.5, 2]).collect{|freq, inwhich|
			var trig = Dust2.kr(reltempo);
			var lev  = Latch.kr(trig, trig.abs);
			SinOsc.ar(freq + EnvGen.ar(Env.perc(0.01, 0.1), trig.abs, 15 * lev))
		} * [1.5, 0.7, 0.25]).sum * 0.1;
		son = MidEQ.ar(son, 160, 0.25, -6); // notch out a buzz on the cone
		son = HPF.ar(son, 300);
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


~scenetypes["bal_roundfeather"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var freq = \freq.kr(51.midicps);
	var son, sub;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	son = ~npendulums.collect{|val|
		var son, mod;
		mod = LFSaw.kr(reltempo * ExpRand(0.05, 0.2), Rand(pi)).range(0,1);
		son = SinOsc.ar(freq * SinOsc.ar(mod.linexp(0, 1, 0.1, 1), mul: mod.squared).linexp(-1, 1, 0.99, 1.01)).tanh * 0.2;
	};

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["bal_fleet"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, patchtempo=1|

	var freq = \freq.kr(67.midicps);
	var sub;
	var sons, son2;
	var reltempo = ~normalperiod * In.kr(~tempobus) * patchtempo;
	son2 = Formant.ar(freq, 715, 400) * 0.015; // 715
	sons = ~npendulums.collect{|val|
		var son;
		son = SinOsc.ar(freq * LFDNoise0.ar(2 * reltempo).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.35)).sum * 0.1;
	};
	sons = sons + PanAz.ar(~npendulums, son2, LFSaw.ar(0.1 * reltempo).range(0, 2), width: 2);

	sub = ~nsubs.collect{|which|
		DC.ar(0);
	};
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

