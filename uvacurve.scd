// s.boot
(
// Settings:
~defaultscenes = ["tonestack01sin", "silent", "silent"]; // these are the ones that run on first invoke
~stereoonly = false;
~hw_midbus = 0;
~hw_subbus = 4;
~athome = false;
~hardmul = if(~athome){10}{0.75};
"localsettings.scd".loadRelative;
////////////////////////
s.latency = 0.5;
s.options.numOutputBusChannels_(12);
s.options.numWireBufs = 128;
s.options.memSize = 8192 * 4;
s.waitForBoot{
	~npendulums = 12;
	~npendulums_true = 6; // only this many ACTUAL outputs sent, and the subs are sent to the next lot
	~nscenes    = 2;
	~nsubs      = 1;
	// busses
	~pendbus = Bus.control(s, ~npendulums * 2); // later we may want fixed indexing
	~sceneposbus = Bus.control(s, ~nscenes);
	~finalaudiobus = Bus.audio(s, ~npendulums);
	~subbus = Bus.audio(s, ~nsubs);
	~scenevalpointsbus = ~nscenes.collect{Bus.control(s,  2 * 3)}; // the bus for the 3val breakpoints setting the modulation ranges
	~scenevalpointsbus.do{|abus| abus.setAll(1)};
	~basefreqbus = Bus.control(s);
	{~basefreqbus.set(120)}.defer(0.1);
	// groups
	~ksettersgroup = Group.head(s.defaultGroup); // group for things that set control busses
	~scenesgroup = Group.after(~ksettersgroup);
	~postfxgroup = Group.after(~scenesgroup);
	~outputtersgroup = Group.after(~postfxgroup);

	~ledbus = Bus.control(s, 2 * ~npendulums); // LED brightnesses to be sent over to d3 [pixel0, ring0, pixel1, ring1, ...]
	/*{
	~ledbusreader = {
	SendReply.kr(Impulse.kr(30), "/d3/lights/set",  In.kr(~ledbus, 2 * ~npendulums));
	DC.ar(0);
	}.play(~outputtersgroup);
	}.defer(1); */

	// global tempo
	~normalperiod = 3.4;
	~tempo = 1/~normalperiod;
	~tempobus = Bus.control(s);
	{~tempobus.set(~tempo)}.defer(0.1);
	~settempo = {|val|
		~tempobus.set(val);
		~tempo = val;
		TempoClock.default.tempo_(max(1e-22, val * ~normalperiod)); // This multiplying may seem weird. We're using the default TempoClock for scene sequencing, where we want to think in seconds which get warped if we're slower than the standard period
	};

	// - SYNTH: pulsespos - a single synth that implements some kind of chaotic attractor or something, that ensures the scenes are dynamically moving around and mostly stay spatially separate from each other.
	~scenepossynths = ~nscenes.collect{|whichscene|
		{ |rapidity=5, circlesize=1|
			var pos;
			var movespeed = (rapidity/circlesize.max(1)) * (~normalperiod * In.kr(~tempobus));
			pos = LFSaw.kr(0.07 * rrand(0.9, 1.1) * movespeed, 2.0.rand).range(0, 1);
			Out.kr(~sceneposbus.index + whichscene, pos);
		}.play(~ksettersgroup);
	};
	~automoving = {|bool|
		~scenepossynths.do{|n| n.run(bool)};
	};
	~automoving.value(true);

	// ~sceneposbus.scope

	// - SYNTH: fakependulums - let's send SinOsc.kr(exprand(), 2pi.rand) to the busses for test.
	~fakependulums = {
		// NB ~normalperiod is the standard period of the pendulums
		var tempo = In.kr(~tempobus).max(1e-12);
		var pendpos = {SinOsc.kr(exprand(0.9, 1.1) * tempo, 2pi.rand)}.dup(~npendulums * 2);
		Out.kr(~pendbus, pendpos);
	}.play(~ksettersgroup);

	/*
	- NODEPROXY * N - each scene. it must do the following:
	- read its position from pulsespos
	- read the pendulumpos
	- synthesise its 16+4 channel sound   (mostly this will just use the pendulumpos vals)
	- envelope it all using a standard function I'll write
	The nodeproxy has a fairly long fadetime, so that when different scenes are sent it crosses sensibly.
	*/
	// standard enveloper reused by each scene type
	~sceneenveloper = {|audio, sub, leds, position, width=0, movewith=true, circlesize=1|
		var distances, subdistances;
		circlesize = max(1, circlesize); // circlesize is like adding virtual silent speakers to the end of the list
		distances    = ((position * ~npendulums * circlesize) - (0..~npendulums-1)).abs;   // so, +1 is 1 speaker away
		subdistances = ((position * ~nsubs      * circlesize) - (0..~nsubs-1)).abs;
		//position.poll(10, "...position is");
		//distances[11].poll(10, "...distance[11] is");
		distances = distances.collect{|val|  min(val, ~npendulums * circlesize - val).abs };
		//distances[11].poll(10, "...distance[11] is");
		subdistances = subdistances.collect{|val|  min(val, ~nsubs * circlesize - val).abs };
		// when width is 0, we are only on the nearest one (i.e. distances <= 0.5) - NEVER not on one!
		//   this means that any dist <=0.5 has to be treated the same.
		// when width is 1, we are equally over all of them, irrespective of dist.
		//distances.poll(1);
		//position.poll(1);
		//((distances[11]-0.5).max(0)/~npendulums).linexp(0, 1, 1, width.min(0.999).max(0.001)).poll(10, "...distmul[11] is");
		if(movewith){
			audio = audio        .sum{|anaudio, index| PanAz.ar(~npendulums, anaudio, (position + (index / ~npendulums)) * 2) };
			leds  = leds.clump(2).sum{|anled  , index| PanAz.kr(~npendulums, anled  , (position + (index / ~npendulums)) * 2) }.flop.flat;
		};
		audio = distances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~npendulums).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			distmul = distmul.squared;  /////// TEST IF HARDER ISOLATION IS GOOD
			leds[which * 2    ] = leds[which * 2    ] * distmul;
			leds[which * 2 + 1] = leds[which * 2 + 1] * distmul;
			audio[which] * distmul;
		};
		sub = subdistances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~nsubs).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			sub[which] * distmul;
		};
		[audio, sub, leds] // return
	};

	// This function is used to map from a pendulum position in range [-1, +1] to three envelope points
	~pendvalto3val_lin = {|pendval, threepoints|
		Select.kr(pendval>0, [
			(0-pendval).linlin(0, 1, threepoints[1], threepoints[0]),
			pendval.linlin(    0, 1, threepoints[1], threepoints[2])
		])
	};
	~pendvalto3val_exp = {|pendval, threepoints|
		var val;
		//"threepoints is: %".format(threepoints).postln;
		threepoints = threepoints.max(1e-6);
		//pendval.poll(0.25, "pendval");
		//(pendval>0).poll(0.25, "pendval>0");
		val = Select.kr(pendval>0, [
			(0-pendval).linexp(0, 1, threepoints[1], threepoints[0]),
			pendval.linexp(    0, 1, threepoints[1], threepoints[2])
		]);
		//val.poll(0.25, "warped val");
		val
	};

	//////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////
	// First we define the available scene types. each takes pendpos and a scenepos as input and returns [audio * 16, sub * 4] or whatever
	~scenetypes = Dictionary(); // Each entry is a list of [func, tweakableparams] where the latter is [[\name, defaultval]...]


	~scenetypes["driftysines"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son = ~npendulums.collect{|which| SinOsc.ar(rrand(220, 660) * freqscale)} * 0.1;
		var sub = {SinOsc.ar(rrand(20, 60))}.dup(~nsubs) * 0.4;
		var leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["frag_pwm"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var phases, son, onewidth, amps, sub, freq, leds, reltempo;
		reltempo = ~normalperiod * In.kr(~tempobus);
		width = width.linlin(0,1,1,~npendulums); // nb we handle width ourselves, to get the pwm right
		phases = (0..~npendulums-1) * 0.5 / ~npendulums;
		onewidth = (0.5 / ~npendulums) / reltempo;
		amps = ~npendulums.collect{|index| width.linlin(index, index+1, 0, 1)};
		freq = In.kr(~basefreqbus) * 0.25 * freqscale * reltempo;
		son = ~npendulums.collect{|which|
			var misalign = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var histuff  = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			LFPulse.ar(freq, phases[which] + misalign, onewidth, amps[which])
			* XFade2.ar(DC.ar(1), LFTri.ar(freq * 16), histuff * 2 - 1)
		} * 0.1;
		son = son - DelayC.ar(LPF.ar(son, 120, 2), 0.01, 0.01);
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		son.do{|oneson, which|
			var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
			sub[reindex] = sub[reindex] + LPF.ar(oneson, 100);
			leds[which * 2 + 1] = A2K.kr(oneson).abs * 10;
		};
		~sceneenveloper.value(son, sub, leds, onescenepos, 1, circlesize:circlesize)
	}, [["misalign (0--1)", 0], ["histuff (0--1)", [1,0,1]]]];
	~scenetypes["tracer"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
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
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), bangs[which], timeScale: scaler).exprange(0.15, MouseY.kr(100, 10000)), phase: 0.5pi);
			env = EnvGen.ar(Env.perc(0, 0.1), bangs[which], timeScale: scaler);
			rawson = rawson * env;
			rawson = HPF.ar(rawson, 5000) * 0.25;
			/*
			var del = (~npendulums - which) * 0.06;
			leds[which * 2] = DelayC.kr(env, del * 4, del * thruspeed.reciprocal) > 0.25;
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
		~sceneenveloper.value(son, sub, leds, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["zappiness", 0], ["thruspeed", 1]]];
	~scenetypes["tracerbeep"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		var pos, trig, rawson, scaler, env, panenv;
		var reltempo = ~normalperiod * In.kr(~tempobus);
		trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2 * reltempo);
		leds = {DC.kr(0)}.dup(~npendulums * 2);

		//rawson = (SinOsc.ar(1300 * [1,3,5,7]).mean * MouseY.kr(2,4)).clip2;
		rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
		env = EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(trig, dur: 0.1));
		rawson = rawson * 0.4 * env;

		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var distort = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			var del = which * 0.06;
			leds[which * 2] = DelayC.kr(env, del, del) > 0.1;
			DelayC.ar((rawson * distort.linexp(0, 1, 1, 10)).atan, del, del) * amp;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		son.do{|oneson, which|
			var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
			sub[reindex] = sub[reindex] + LPF.ar(FreeVerb.ar(LPF.ar(oneson, 100) * BrownNoise.ar * 50, 0.5, 0.5, 0.999), 100);
		};
		~sceneenveloper.value(son, sub, leds, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["amp", 1], ["distort 0--1", [0, 0.4, 0]]]];
	~scenetypes["crickle_hi"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		son = ~npendulums.collect{|which|
			var sig, density, lowconv;
			density = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			lowconv = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			sig = Dust2.ar(density * (~normalperiod * In.kr(~tempobus)));
			sig = HPF.ar(sig, 15000 /* MouseX.kr(5000, 20000, 1) */, 0.7);
			//sig = BPF.ar(sig, MouseX.kr(1000, 5000, 1)) + BPF.ar(sig, MouseY.kr(100, 1000, 1).poll);
			sig = XFade2.ar(sig, FreeVerb.ar(sig) * BrownNoise.ar(2), lowconv * 2 - 1);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, [["density", [2, 400, 2]], ["lowconv (0--1)", 1]]];
	~scenetypes["puresine01"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		son = ~npendulums.collect{|which|
			var freq   = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var detune = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			(SinOsc.ar(freq + ([detune, 0-detune])).mean) * 0.1;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, [["freq", 880], ["detune", 2.5]]];
	~scenetypes["puresine03"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds, basefreq = In.kr(~basefreqbus);
		//"threevals is: %".format(threevals).postln;
		son = ~npendulums.collect{|which|
			var amp, modrate;
			amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			modrate = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			(
				(SinOsc.ar([basefreq * 0.5] * freqscale)) * 0.1 * SinOsc.ar(0.25 * modrate).range(0.5, 1)
				+
				(SinOsc.ar([basefreq * 2.0] * freqscale)) * 0.1 * SinOsc.ar(1 * modrate).range(0.5, 1)
			) * amp
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		[son, sub, leds]
	}, [["amp", [1,0,1]], ["modrate", [8,2,8]]]];
	~scenetypes["passingzero_frompend"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		son = ~npendulums.collect{|which|
			var tester = (pendspos[which][1]).sign;
			var env = EnvGen.ar(Env.perc(0.01, 0.1), HPZ1.kr(tester));
			leds[which * 2 .. which * 2 + 1] = A2K.kr(env);
			SinOsc.ar((83 + which).midicps, 0, env) * 0.2;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		[son, sub, leds]
	}, []];
	~scenetypes["passingzero_frompend_conc"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		son = ~npendulums.collect{|which|
			var radialpos = (pendspos[which][1].squared + pendspos[which][0].squared).sqrt;
			var envs = [0, 0.1, 0.2, 0.3, 0.4].collect{|radius, whichrad|
				var tester = (radius - radialpos).sign;
				EnvGen.ar(Env.perc(0.01, 0.1), HPZ1.kr(tester))
			};
			leds[which * 2 .. which * 2 + 1] = A2K.kr(envs.sum);
			envs.collect{|env, whichrad|
				SinOsc.ar((83 + which + (whichrad * 4)).midicps, 0, env) * 0.2;
			}.sum;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		[son, sub, leds]
	}, []];
	~scenetypes["hinoise"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		son = ~npendulums.collect{|which|
			var locut   = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var decimate= ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);

			HPF.ar(PinkNoise.ar, locut) * locut.linlin(3000, 15000, 0.1, 0.5); // 10000 default
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, [["locut", [15000, 3000, 15000]], ["[unused]", 0]]];
	[["sin", SinOsc] /* , ["saw", LFSaw] */ ].do{|adata|
		~scenetypes["tonestack01" ++ adata[0]] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
			var son, sub, leds, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps, fmlfo;

			basefreqs = [60, 90, 120, 240, 480].scramble * 0.5 * freqscale;
			harmstack = [1, 1.5, 2];
			harmamps = [1.5, 0.4, 0.1];

			freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

			fmlfo = LFNoise0.ar(400);

			son = harmstack.mean{|val, harmindex|
				freqs.collect{|afreq, which|
					var fmdepth = ~pendvalto3val_lin.value(pendspos[which][1], threevals[0]) * 0.5;
					var freqscale2 = ~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
					var fm = fmlfo.exprange(1 - fmdepth, 1 + fmdepth);
					adata[1].ar(afreq * val * freqscale2 * (fm * harmindex), mul: 0.05 * harmamps[harmindex])
				};
			};

			freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/30, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
			//freqsel.poll;
			son = (son * freqsel).sum;

			son = ~npendulums.collect{|which|
				son[which] * SinOsc.ar(0.125, (4-which) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)
			}; // pow 0.25 makes move smoothly across speakers; higher, atomised.

			son = son * 15;

			//freqscale.poll;

			sub = ~nsubs.collect{|which|
				SinOsc.ar((basefreqs * 0.25 * [1, LFPar.kr(0.1).range(1, 0.75)]).flat, mul: freqsel).sum * 0.1;
			};
			leds = {DC.kr(0)}.dup(~npendulums * 2);
			~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
		}, [["fmdepth 0--1", 0], ["freqscale", 1]]];
	}; // end adata iter
	~scenetypes["drift_sine"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds, basefreqs, harmstack, harmamps, freqs, freqsel, amps;

		//basefreqs = [120, 180, 240, 360, 480].scramble;
		basefreqs = [120, 130] * 3 * freqscale;
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.4, 0.1];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		son = harmstack.mean{|val, harmindex|
			freqs.collect{|afreq, which|
				var freqscale2 = ~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
				SinOsc.ar(afreq * val * freqscale2 * harmindex, mul: 0.05 * harmamps[harmindex])
			};
		};

		freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/20, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
		//freqsel.poll;
		son = (son * freqsel).sum;

		son = son * 0.5; // Deliberately making it MORE subtle than the main bed

		amps = ~npendulums.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly across speakers; higher, atomised.

		son = son * amps * 15;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, [["UNUSED", 1], ["freqscale", 1]]];

	~scenetypes["tonestack01tri02"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds, basefreqs, harmstack, harmamps, freqs, freqsel, amps;

		basefreqs = [120, 180, 240, 360, 480].scramble * freqscale;
		//basefreqs = [120, 130] * 3;
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.4, 0.1];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		son = harmstack.mean{|val, harmindex|
			freqs.collect{|afreq, which|
				var freqscale2 = ~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
				var harmstretch = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
				// "index" was a multiplier before
				LFTri.ar(afreq * freqscale2 * val.pow(harmstretch.linexp(0,1,1,2)), mul: 0.03 * harmamps[harmindex])
			};
		};

		freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/20, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
		//freqsel.poll;
		son = (son * freqsel).sum;

		amps = ~npendulums.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly across speakers; higher, atomised.

		son = son * amps * 15;

		sub = ~nsubs.collect{|which|
			SinOsc.ar((basefreqs * 0.125 * [1, LFPar.kr(0.1).range(1, 0.75)]).flat, mul: freqsel).sum * 0.2;
		};
		leds = {DC.kr([0, 0.7])}.dup(~npendulums).flat;
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, [["harmonic stretch 0--1", 0], ["freqscale", 1]]];
	~scenetypes["silent"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds;
		son = ~npendulums.collect{|which|
			DC.ar(0);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["speakerTEST"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var imps, bongs, sub, leds;

		imps = Impulse.ar(2 / ~npendulums,
			(1..~npendulums)/(~npendulums+1)).reverse // These fire on individual channels
		+
		Impulse.ar(2/~npendulums)  // This one fires on all channels
		;

		bongs = SinOsc.ar(
			{(10.rand + 50).midicps}.dup(~npendulums) + LFNoise2.kr(10, 40)
		);
		bongs = bongs + WhiteNoise.ar(0.25);
		bongs = bongs * EnvGen.ar(Env.perc(0.02, 0.05, curve: [2, 0]), imps);
		bongs = bongs * 0.5;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		[bongs, sub, leds]
	}, []];
	~scenetypes["movebop"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, leds, val1, val2;
		var freqs = (240 * ((0..~npendulums) * 3).midiratio).clump(3).flop.flat;
		var resolution = 1e-1;
		son = ~npendulums.collect{|which|
			var trig = HPZ1.kr(pendspos[which][0].round(resolution)).abs;
			SinOsc.ar(freqs[which]) * EnvGen.ar(Env.perc(0.001, 0.1), trig, timeScale: 1/(In.kr(~tempobus)*~normalperiod)) * 0.3;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
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
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["bal_purity2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|

		var son, sub, leds;
		son = ~npendulums.collect{|val|
			([1,16].collect{|val| SinOsc.ar(val * Array.series(8, 1, 1) * 51.midicps * LFDNoise0.kr(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(8, 0.5, 0.125)).sum * 0.1;
			} * [1, 0.002]).sum * 4;
		};

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
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
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize)
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
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
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
		sons = sons.stutter(3) * 0.02;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		leds = {DC.kr(0)}.dup(~npendulums * 2);
		~sceneenveloper.value(sons, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	/*
	~scenetypes[""] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub, leds, val1, val2;
	son = ~npendulums.collect{|which|
	val1 = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
	val2 = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
	DC.ar(0);
	};
	sub = ~nsubs.collect{|which|
	DC.ar(0);
	};
	leds = {DC.kr(0)}.dup(~npendulums * 2);
	~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize)
	}, []];
	*/
	// end scenetypes
	//////////////////////////////////////////////////////////////////////////////////////

	// now a nodeproxy for each scene instance, plus an "offstage" one for double-buffering
	~sceneplayers = ~nscenes.collect{|which|
		var np = NodeProxy.audio(s, ~npendulums + ~nsubs);
		var onegroup = Group.tail(~scenesgroup);
		np.group_(onegroup);
		np.fadeTime_(4);
		np.set(\width, 0);
		np
	};
	~sceneplayers_offstage = ~nscenes.collect{|which|
		var np = NodeProxy.audio(s, ~npendulums + ~nsubs);
		var onegroup = Group.tail(~scenesgroup);
		np.group_(onegroup);
		np.fadeTime_(4);
		np.set(\width, 0);
		np
	};

	// TODO - here I want to implement double-buffering to swap NPs around each time
	// TODO - once double-buffering is in place, make proper use of the xfade arg
	~pushascene = {|scenename, whichnp, xfade=4, arglist=nil|
		scenename = scenename.asString;
		if(~scenetypes[scenename].isNil){
			"ERROR: ~pushascene..('%'): Scene name  not found".format(scenename).postln;
		}{
			var swoppo;
			"~pushascene.('%', %)".format(scenename, whichnp).postln;
			/*
			// First we swap the double-buffering round, so that no-one else can address the old one
			swoppo = ~sceneplayers[whichnp];
			~sceneplayers[whichnp] = ~sceneplayers_offstage[whichnp];
			~sceneplayers_offstage[whichnp] = swoppo;
			*/
			//NodeProxy;
			// Now set the desired crossfade on both of them
			//"fade time %".format(xfade).postln;
			~sceneplayers[         whichnp].fadeTime_(xfade);
			~sceneplayers_offstage[whichnp].fadeTime_(xfade);
			~sceneplayers[         whichnp].set(\xfade, xfade);
			~sceneplayers_offstage[whichnp].set(\xfade, xfade);
			s.bind{
				/*
				// Fade out the old one
				~sceneplayers[whichnp].source = {
					Out.ar(~finalaudiobus, DC.ar(0).dup(~npendulums));
				};
				*/
				// NOW we're at the point of constructing our new one
				//"pushing tweakyvals".postln;
				// This pushes the default tweaky vals to the appropriate bus
				~scenevalpointsbus[whichnp].setn(2.collect{|whichone| 3.collect{|whichsubboxer|
					(~scenetypes[scenename][1][whichone] ? [\nil, 1])[1].asArray.wrapAt(whichsubboxer)
				}}.flat);
				//"pushed tweakyvals".postln;
				// And this actually pushes the patch
				~sceneplayers[whichnp].source = {|amp=0.7, width=0.5, freqscale=1, circlesize=1, gate=1|
					var fadein = 1; // XLine.ar(0.0001, 1, xfade);
					var fadeenv = EnvGen.ar(Env.asr(1, 1, 1), gate, timeScale:\xfade.kr(xfade, 0, true), doneAction: 2);
					var onescenepos = In.kr(~sceneposbus.index + whichnp, 1);
					var pendspos = In.kr(~pendbus, ~npendulums * 2).clump(2);
					var threevals = In.kr(~scenevalpointsbus[whichnp], 6).clump(3);
					var mids, subs, leds;
					# mids, subs, leds = ~scenetypes[scenename][0].value(pendspos, onescenepos, width, freqscale, threevals, circlesize);
					Out.ar(~finalaudiobus, mids * amp * fadein * fadeenv);
					Out.ar(~subbus, subs * amp * fadein * fadeenv);
					Out.kr(~ledbus, leds);
				};
				// Now if there are any args on the end, we will set them too
				if(arglist.size>0){
					"pushing argyvals".postln;
					~sceneplayers[whichnp].set(*arglist)
				};
			};
		};
	};

	// default scenes start playing
	~sceneplayers.do{|asp, which|
		~pushascene.value(~defaultscenes[which], which)
	};

	// - SYNTH: replaceout-based dopplerfaker. takes in the pendulumpos and uses a smoothed version of that.
	~radiusm = 1.5;
	~maxdoppler = 2 * ~radiusm / 330;
	~dopplerfaker = { |active=0|
		// For each pendulum, take in its y position, lag it, translate it into delay, take in its audio, replaceout
		var swingposses = In.kr(~pendbus, ~npendulums * 2)[1,3..];
		var audios = In.ar(~finalaudiobus, ~npendulums);
		audios = audios.collect{|anaudio, whichaudio|
			var delay = swingposses[whichaudio].lag(0.05).linlin(-1,1, 0, ~maxdoppler) * active;
			var reverbmix = swingposses[whichaudio].lag(0.05).abs.linexp(0,1, 0.001, 0.9) * active;
			var son;
			//delay.poll(1);
			//reverbmix.poll(1);
			son = DelayC.ar(anaudio, ~maxdoppler, delay);
			son = XFade2.ar(son, LPF.ar(son, 440), reverbmix * 2 - 1);
			son = FreeVerb.ar(son, reverbmix, 0.7, 0.99);
		};
		audios = audios.clip2(1);
		ReplaceOut.ar(~finalaudiobus, audios);
	}.play(~postfxgroup, addAction: \addToTail);
	/*
	~dopplerfaker.free
	*/

	~outputter = {|out=0, amp=0.7, midamp=0.7, subamp=0.7, midon=1, subon=0, reverbon=0|
		if(~stereoonly){
			// - SYNTH: stereo mixdown - takes gallery listening position from the mouse, adds distance-based attenuation and reverb, pans using the pendulumpos data. takes mainamp and subamp as simple controls.
			var listenpos = MouseX.kr(0, ~npendulums-1);
			var rawsound = In.ar(~finalaudiobus, ~npendulums).asArray;
			var rawsub   = In.ar(~subbus, ~nsubs).asArray;
			var distances = ((0..~npendulums-1) - listenpos).abs;
			var distances_sub = ((0..~nsubs-1) - (listenpos * (~nsubs/~npendulums))).abs;
			var swingposses = In.kr(~pendbus, ~npendulums * 2)[0,2..];

			var mid = rawsound.collect{|asound, which|
				var mixamt = (distances[which]+1).reciprocal;
				FreeVerb.ar(Pan2.ar(asound, swingposses[which]),
					mix:mixamt.linlin(0, 1, 0.9, 0.1) * reverbon, room:0.5, damp:0.5, mul:mixamt);
			}.sum * midamp * midon;
			var sub = rawsub.collect{|asound, which|
				var mixamt = (distances_sub[which]+1).reciprocal;
				Pan2.ar(asound, 0, mixamt)
			}.sum * subamp * subon;
			var son = mid + sub;
			son = son * amp * ~hardmul;
			Out.ar(out, son);
		}{
			// - SYNTH: multichannel outputter. takes mainamp and subamp as simple controls.
			var rawsound = In.ar(~finalaudiobus, ~npendulums_true);
			var rawsub   = In.ar(~subbus, ~nsubs);
			rawsound = FreeVerb.ar(rawsound, mix:0.3 * reverbon, room:0.5, damp:0.5, mul:1);
			Out.ar(~hw_midbus, rawsound * amp * midamp * midon * ~hardmul);
			Out.ar(~hw_subbus, rawsub   * amp * subamp * subon * ~hardmul);
		}
	}.play(~outputtersgroup);
}
)
