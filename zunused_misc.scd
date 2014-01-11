	~scenetypes["one_harmonic_per"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var harmstretch = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			SinOsc.ar(basefreq * ([which, which*harmstretch]+1) * BrownNoise.ar.range(0.95, 1.05)).mean
		} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["harmstretch", 1]]];
	~scenetypes["one_harmonic_per+chord"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which| SinOsc.ar(basefreq * [1, 1.25, 1.5] * (which+1) * BrownNoise.ar.range(0.95, 1.05)).mean} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, 1, false, circlesize:circlesize) // no width
	}, []];
	~scenetypes["one_harmonic_per+chord+lfo"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var lforate = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			SinOsc.ar(basefreq * [1, 1.25, 1.5] * (which+1) * BrownNoise.ar.range(0.95, 1.05)).mean
			* LFCub.ar((8 - (which* 0.5)) * lforate, which * 0.1).squared.squared
		} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["lforate", 0.2]]];

	~scenetypes["one_harmonic_per+waveactiv"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;



		var trig = Dust.kr(LFPar.kr(0.1).range(0.1, 0.8).squared * 2 * (~normalperiod * In.kr(~tempobus))) + Impulse.kr(0);

		var triggedamp = TExpRand.kr(0.01, 1.5, trig); //.poll(trig);

		var son = ~npendulums.collect{|which|
			var chordiness = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			[1, 1.25, 1.5].collect{|overtone, whichovertone|
				SinOsc.ar(basefreq * overtone * (which+1) * BrownNoise.ar.range(0.95, 1.05),
					mul:  if(whichovertone==0){3 - (2*chordiness)}{chordiness})
			}.mean
		} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		var leds = {DC.kr(0)}.dup(~npendulums * 2);

		var sonforenv;
		var	rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
		var trigdur = LFPulse.kr(0.03).range(0.01, 0.1);
		rawson = rawson * 0.4 * EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(trig, dur: trigdur));

		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var distort = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			var del = (~npendulums - which) * 0.06;
			DelayC.ar((rawson * distort.linexp(0, 1, 1, 10)).atan * amp + (son[which] * triggedamp * 8), del, del)
		} * 0.1;

		~sceneenveloper.value(son, sub, leds, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["chordiness (0--1)", [0.5, 1, 0.5]]]];	~scenetypes["superhigh"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps;

		//basefreqs = [120, 180, 240, 360, 480].scramble;
		basefreqs = [120, 130] * 60 * freqscale;
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.4, 0.1];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		//fmdepth = MouseX.kr(0.000001, 0.5);
		fm = 1; //Gate.kr(MouseY.kr(0.5, 1, 1), Impulse.kr(0) + MouseButton.kr);

		son = harmstack.mean{|val, index| SinOsc.ar(freqs * val * (fm * index), mul: 0.05 * harmamps[index])};

		freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/20, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
		//freqsel.poll;
		son = (son * freqsel).sum;

		son = son * 0.5; // Deliberately making it MORE subtle than the main bed

		son = ~npendulums.collect{|which|
			var distort = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var amp     = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			(son[which] * distort.linexp(0,1, 1, 10)).clip2 * amp * SinOsc.ar(0.125, (4-which) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)
		}; // pow 0.25 makes move smoothly across speakers; higher, atomised.
		son = son * 12;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, [["distort", 0], ["amp", 1]]];
