	~scenetypes["bal_purity1"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var son, sub, leds;
		son = ~npendulums.collect{|val|
			var son;
			son = SinOsc.ar(Array.series(4, 1, 1) * 60.midicps * LFDNoise0.ar(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.5)).sum * 0.2;
		};

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["bal_purity2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var son, sub, leds;
		son = ~npendulums.collect{|val|
			([1,16].collect{|val| SinOsc.ar(val * Array.series(8, 1, 1) * 51.midicps * LFDNoise0.kr(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(8, 0.5, 0.125)).sum * 0.1;
			} * [1, 0.002]).sum * 3;
		};

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, []];

	~scenetypes["bal_riffle"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var sons, sub, leds;
		// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, but not far and they settle back quickly
		sons = ~npendulums.collect{|val|
			var son;
			var addmidi = -7;//MouseX.kr(0, 40).round.poll(1);
			son = (([58, 65, 70] + addmidi).midicps.collect{|freq, inwhich|
				var trig = Dust2.kr(1);
				var lev  = Latch.kr(trig, trig.abs);
				SinOsc.ar(freq + EnvGen.ar(Env.perc(0.01, 0.1), trig.abs, 15 * lev))
			} * [1.5, 0.7, 0.25]).sum * 0.1;
		};
		sons = sons.collect{|son|
			var nu = FreeVerb.ar(son * HPF.ar(WhiteNoise.ar, 10000), 1) * 0.1;
			XFade2.ar(son, nu, LFSaw.kr(0-ExpRand(0.08, 0.12), Rand(pi)));
		};


		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, []];

