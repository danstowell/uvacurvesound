	~scenetypes["oneper_to_orch_thrum"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var thrummul = 0.8 * ~normalperiod * In.kr(~tempobus); //MouseY.kr(0.5, 2, 1);
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1) * freqscale;
			LPF.ar(
				5.collect{
					BPF.ar(
						Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03)),
						(basefreq * IRand(1, 32)).min(15000),
						5 /* MouseX.kr(1, 10, 1) */
					) * LFSaw.ar(thrummul * ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared
				}.mean
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.95])}.dup(~npendulums).flat;
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["oneper_to_orch_thrum_varsaw"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var thrummul = 0.8 * ~normalperiod * In.kr(~tempobus); //MouseY.kr(0.5, 2, 1);
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1) * freqscale;
			LPF.ar(
				5.collect{
					BPF.ar(
						VarSaw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03), 0, LFSaw.ar(thrummul * ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared),
						(basefreq * IRand(1, 32)).min(15000),
						5 /* MouseX.kr(1, 10, 1) */
					)
				}.mean
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
		} * 0.2;
		var sub = {SinOsc.ar(basefreq) * LFTri.ar(ExpRand(5, 10)).range(0.25, 0.05)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.95])}.dup(~npendulums).flat;
		son.do{|oneson, which|
			var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
			sub[reindex] = sub[reindex] + (LPF.ar(oneson, 100));
		};
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["oneper_to_orch_thrum_varsaw_fizzin"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var inxfade = XLine.kr(1e-12, 1, 30);
		var indensity = XLine.kr(0.1, 1000, 30);
		var thrummul = 0.8 * ~normalperiod * In.kr(~tempobus); // MouseY.kr(0.1, 1, 1);
		var envs = ~npendulums.collect{|which|
			EnvGen.ar(Env.perc(0.02, 0.02), Dust.kr(indensity));
		};
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1) * freqscale;
			var asig = LPF.ar(
				5.collect{
					BPF.ar(
						VarSaw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03), 0, LFSaw.ar(thrummul * ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared),
						(basefreq * IRand(1, 32)).min(15000),
						5 /* MouseX.kr(1, 10, 1) */
					)
				}.mean
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
			XFade2.ar(asig * envs[which], asig, inxfade * 2 - 1);
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = ~npendulums.collect{|which| DC.kr([0, 0.95]) * A2K.kr(envs[which])}.flat;
		son.do{|oneson, which|
			var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
			sub[reindex] = sub[reindex] + (LPF.ar(oneson, 100) * LFTri.ar(ExpRand(5, 10)).range(0.5, 0.1));
		};
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["oneper_to_orch_thrum_both"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var thrummul = 0.5 * ~normalperiod * In.kr(~tempobus); //MouseY.kr(0.1, 1, 1).poll;
		var son = ~npendulums.collect{|which|
			var mybasefreq;
			//which = (which * 2).fold(0, ~npendulums - 0.5); // folds the ramp down again
			which = which.fold(0, ~npendulums/2); // folds the ramp down again
			mybasefreq = basefreq * (which+1) * freqscale;
			LPF.ar(
				XFade2.ar(
					5.collect{
						BPF.ar(
							Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03)),
							(basefreq * IRand(1, 32)).min(15000),
							5 /* MouseX.kr(1, 10, 1) */
						) * LFSaw.ar(thrummul * ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared
					}.mean,
					5.collect{
						BPF.ar(
							VarSaw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03), 0, LFSaw.ar(ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared),
							(basefreq * IRand(1, 32)).min(15000),
							5 /* MouseX.kr(1, 10, 1) */
						)
					}.mean,
					LFDNoise1.kr(0.24).range(-1,1)) // end xfade2
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.95])}.dup(~npendulums).flat;
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["oneper_to_orch_g"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1) * freqscale;
			LPF.ar(
				5.collect{
					BPF.ar(
						Gendy1.ar(minfreq: mybasefreq, maxfreq: mybasefreq),
						//					Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.95, 1.05)),
						(basefreq * IRand(1, 32)).min(15000),
						MouseX.kr(1, 10, 1)
					)
				}.mean
				, (MouseY.kr(1, 100, 1) * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.95])}.dup(~npendulums).flat;
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["low_orch_thrum_varsaw"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var thrummul = 0.8; // MouseY.kr(0.5, 2, 1).poll;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * freqscale; // * (which+1);
			LPF.ar(
				5.collect{
					BPF.ar(
						VarSaw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03), 0, LFSaw.ar(thrummul * ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared),
						(basefreq * IRand(1, 32)).min(15000),
						5 /* MouseX.kr(1, 10, 1) */
					)
				}.mean
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.3])}.dup(~npendulums).flat;
		son.do{|oneson, which|
			var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
			sub[reindex] = sub[reindex] + (LPF.ar(oneson, 100) * LFTri.ar(ExpRand(5, 10)).range(0.5, 0.1));
		};
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["orch_saw1"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			5.collect{
				BPF.ar(
					Saw.ar(basefreq * IRand(1, 4) * BrownNoise.ar.range(0.95, 1.05)),
					basefreq * IRand(1, 12),
					MouseX.kr(1, 10, 1)
				)
			}.mean;
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.95])}.dup(~npendulums).flat;
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];
	~scenetypes["orch_saw2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			5.collect{
				BPF.ar(
					Saw.ar(basefreq * IRand(1, 12) * BrownNoise.ar.range(0.95, 1.05)),
					(basefreq * IRand(1, 32)).min(15000),
					MouseX.kr(1, 10, 1)
				)
			}.mean;
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr([0, 0.95])}.dup(~npendulums).flat;
		~sceneenveloper.value(son, sub, leds, onescenepos, width, false, circlesize:circlesize, pendspos:pendspos)
	}, []];