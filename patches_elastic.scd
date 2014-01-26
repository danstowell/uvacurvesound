
	~scenetypes["elastic_boinger2d"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var sons, sub, leds;
		sons = 12.collect{|chan|
			var son;
			[48, 55, 60].collect{|val|
				son = SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.01));
				son = CombN.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.01, 0.1), 40)
				+ CombC.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.01, 0.1), 40);
			}.mean;
		};
		sons = sons * XLine.ar(0.001, 1, 0.2) * 0.25;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["elastic_stickslip01"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var sons, sub, leds;

		var stickslip = { |force|
			var inMotion, slipEvents, forceBuildup, evtAmp, evtDecayTime, evts;
			force = force.lag(0.1); // smoothing to get rid of volatile control changes
			inMotion = force > 0.1; // static friction: nothing at all below a certain force
			slipEvents = inMotion * Impulse.ar(force.linlin(0.1, 1, 1, 1/0.003) * LFDNoise1.ar(50).squared.linexp(-1,1, 0.5, 2));
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

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, []];
