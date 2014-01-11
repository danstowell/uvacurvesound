	~scenetypes["unbal_clustpot"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var sub, leds;
		var clusts, sons;

		clusts = 4.collect{
			4.collect{
				var freq = TIRand.kr(45, 65, Dust.kr(0.03)).midicps;
				SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
			}.mean
		};
		sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
		sons = sons.stutter(3) * 0.05;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["unbal_clustpot_hi"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var sub, leds;
		var clusts, sons;

		clusts = 4.collect{
			4.collect{
				var freq = TIRand.kr(75, 95, Dust.kr(0.03)).midicps;
				SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
			}.mean
		};
		sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
		sons = sons.stutter(3) * 0.0003;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["unbal_diffle"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var sons, sub, leds;
		// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, and they settle back slowly
		sons = 12.collect{|val|
			var son;
			var addmidi = 7; //MouseX.kr(-20, 20).round.poll(1);
			son = (([58, 65] + addmidi).midicps.collect{|freq, inwhich|
				var trig = Dust2.kr(1);
				var lev  = Latch.kr(trig, trig.abs).abs.neg;
				SinOsc.ar(freq * LFNoise1.kr(0.1).exprange(0.975, 1.025) + EnvGen.ar(Env.perc(0.1, 1.9), trig.abs, 20 * lev))
			} * [1.85, 0.07]).sum * 0.07;
		};
		sons = sons.collect{|son|
			var nu = FreeVerb.ar(son * HPF.ar(WhiteNoise.ar, 10000), 1) * 0.1;
			XFade2.ar(son, nu, LFSaw.kr(-0.1, Rand(pi)));
		};


		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
