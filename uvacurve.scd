// s.boot
(
// Settings:
~defaultscenes = ["tonestack01sin", "silent", "silent"]; // these are the ones that run on first invoke
~stereoonly = false;
~hw_midbus = 0;
~hw_subbus = 4;
~athome = false;
~hardmul = if(~athome){10}{0.75};
////////////////////////
s.options.numWireBufs = 128;
s.waitForBoot{
	~npendulums = 12;
	~npendulums_true = 4; // only this many ACTUAL outputs sent, and the subs are sent to the next lot
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
	{~basefreqbus.set(120)}.defer(0.1);  // TODO ********  use   In.kr(~basefreqbus)
	// groups
	~ksettersgroup = Group.head(s.defaultGroup); // group for things that set control busses
	~scenesgroup = Group.after(~ksettersgroup);
	~postfxgroup = Group.after(~scenesgroup);
	~outputtersgroup = Group.after(~postfxgroup);

	// - SYNTH: pulsespos - a single synth that implements some kind of chaotic attractor or something, that ensures the scenes are dynamically moving around and mostly stay spatially separate from each other.
	~scenepossynths = ~nscenes.collect{|whichscene|
		{ |rapidity=5, circlesize=1|
			var pos;
			pos = LFSaw.kr(0.07 * rrand(0.9, 1.1) * (rapidity/circlesize.max(1)), 2.0.rand).range(0, 1);
			Out.kr(~sceneposbus.index + whichscene, pos);
		}.play(~ksettersgroup);
	};
	// ~sceneposbus.scope

	// - SYNTH: fakependulums - let's send SinOsc.kr(exprand(), 2pi.rand) to the busses for test.
	~fakependulums = {
		// NB 3.4 is the standard period of the pendulums
		var pendpos = {SinOsc.kr(exprand(0.9, 1.1) / 3.4, 2pi.rand)}.dup(~npendulums * 2);
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
	~sceneenveloper = {|audio, sub, position, width=0, movewith=true, circlesize=1|
		var distances, subdistances;
		circlesize = max(1, circlesize); // circlesize is like adding virtual silent speakers to the end of the list
		distances    = ((position * ~npendulums * circlesize) - (0..~npendulums-1));   // so, +1 is 1 speaker away
		subdistances = ((position * ~nsubs      * circlesize) - (0..~nsubs-1));
		distances = distances.collect{|val|  min(val, ~npendulums * circlesize - val).abs };
		subdistances = subdistances.collect{|val|  min(val, ~nsubs * circlesize - val).abs };
		// when width is 0, we are only on the nearest one (i.e. distances <= 0.5) - NEVER not on one!
		//   this means that any dist <=0.5 has to be treated the same.
		// when width is 1, we are equally over all of them, irrespective of dist.
		//distances.poll(1);
		//position.poll(1);
		//position.poll(10, "...position is");
		//distances[2].poll(10, "...distance[2] is");
		//((distances[2]-0.5).max(0)/~npendulums).linexp(0, 1, 1, width.min(0.999).max(0.001)).poll(10, "...distmul[2] is");
		if(movewith){
			audio = audio.sum{|anaudio, index| PanAz.ar(~npendulums, anaudio, (position + (index / ~npendulums)) * 2) };
		};
		audio = distances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~npendulums).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			audio[which] * distmul.squared;  /////// TEST IF HARDER ISOLATION IS GOOD
		};
		sub = subdistances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~nsubs).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			sub[which] * distmul;
		};
		[audio, sub] // return
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
	/*
	~scenetypes["testimpulse"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son = {CombN.ar(Dust2.ar(3), 0.025, 0.025, 0.5)}.dup(~npendulums);
		var sub = {256 * LPF.ar(Dust2.ar(1), 100)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["testimpulsepure"] = [{|pendspos, onescenepos, width, freqscale, threevals|
		var son = {Impulse.ar(1)}.dup(~npendulums);
		var sub = {DC.ar(0)}.dup(~nsubs);
		[son, sub];
	}, []];
	*/
	~scenetypes["one_harmonic_per"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var harmstretch = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			SinOsc.ar(basefreq * ([which, which*harmstretch]+1) * BrownNoise.ar.range(0.95, 1.05)).mean
		} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["harmstretch", 1]]];
	~scenetypes["one_harmonic_per+chord"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which| SinOsc.ar(basefreq * [1, 1.25, 1.5] * (which+1) * BrownNoise.ar.range(0.95, 1.05)).mean} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, []];
	~scenetypes["one_harmonic_per+chord+lfo"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var lforate = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			SinOsc.ar(basefreq * [1, 1.25, 1.5] * (which+1) * BrownNoise.ar.range(0.95, 1.05)).mean
			* LFCub.ar((8 - (which* 0.5)) * lforate, which * 0.1).squared.squared
		} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["lforate", 0.2]]];
	~scenetypes["one_harmonic_per+waveactiv"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;



		var trig = Dust.kr(LFPar.kr(0.1).range(0.1, 0.8).squared * 2) + Impulse.kr(0);

		var triggedamp = TExpRand.kr(0.01, 1.5, trig).poll(trig);

		var son = ~npendulums.collect{|which|
			var chordiness = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			[1, 1.25, 1.5].collect{|overtone, whichovertone|
				SinOsc.ar(basefreq * overtone * (which+1) * BrownNoise.ar.range(0.95, 1.05),
					mul:  if(whichovertone==0){3 - (2*chordiness)}{chordiness})
			}.mean
		} * 0.075;
		var sub = {DC.ar(0)}.dup(~nsubs);

		var sonforenv;
		var	rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
		var trigdur = LFPulse.kr(0.03).range(0.01, 0.1);
		rawson = rawson * 0.4 * EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(trig, dur: trigdur));

		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var distort = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			var del = which * 0.06;
			DelayC.ar((rawson * distort.linexp(0, 1, 1, 10)).atan * amp + (son[which] * triggedamp * 8), del, del)
		} * 0.1;

		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["chordiness (0--1)", [0.5, 1, 0.5]]]];
	~scenetypes["oneper_to_orch"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1);
			LPF.ar(
			5.collect{
				BPF.ar(
					Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.95, 1.05)),
					(basefreq * IRand(1, 32)).min(15000),
					MouseX.kr(1, 10, 1)
				)
			}.mean
				, (MouseY.kr(1, 100, 1) * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
	}, []];
	~scenetypes["oneper_to_orch_thrum"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1);
			LPF.ar(
			5.collect{
				BPF.ar(
					Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03)),
					(basefreq * IRand(1, 32)).min(15000),
					5 /* MouseX.kr(1, 10, 1) */
					) * LFSaw.ar(ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared
			}.mean
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
	}, []];
	~scenetypes["oneper_to_orch_thrum_varsaw"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1);
			LPF.ar(
			5.collect{
				BPF.ar(
					VarSaw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03), 0, LFSaw.ar(ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared),
					(basefreq * IRand(1, 32)).min(15000),
					5 /* MouseX.kr(1, 10, 1) */
					)
			}.mean
				, (/* MouseY.kr(1, 100, 1) */ 10 * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
	}, []];
	~scenetypes["oneper_to_orch_thrum_both"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq;
			//which = (which * 2).fold(0, ~npendulums - 0.5); // folds the ramp down again
			which = which.fold(0, ~npendulums/2); // folds the ramp down again
			mybasefreq = basefreq * (which+1);
			LPF.ar(
				XFade2.ar(
					5.collect{
						BPF.ar(
							Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.98, 1.03)),
							(basefreq * IRand(1, 32)).min(15000),
							5 /* MouseX.kr(1, 10, 1) */
						) * LFSaw.ar(ExpRand(10, 20) * LFNoise0.kr(2).range(0.9, 1.1)).range(1, 0.75).squared
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
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
	}, []];
	~scenetypes["oneper_to_orch_g"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1);
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
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
	}, []];
	~scenetypes["oneper_to_orch_g2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var basefreq = In.kr(~basefreqbus) * 0.5;
		var son = ~npendulums.collect{|which|
			var mybasefreq = basefreq * (which+1);
			LPF.ar(
			5.collect{
				BPF.ar(
					[Gendy1.ar(minfreq: mybasefreq * 2 * 0.98, maxfreq: mybasefreq * 2 * 1.02),
							Saw.ar(mybasefreq * IRand(1, 4) * BrownNoise.ar.range(0.95, 1.05))].mean,
					(basefreq * IRand(1, 32)).min(15000),
					MouseX.kr(1, 10, 1)
				)
			}.mean
				, (MouseY.kr(1, 100, 1) * mybasefreq).min(18000));
		} * 0.2;
		var sub = {DC.ar(0)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
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
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
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
		~sceneenveloper.value(son, sub, onescenepos, width, false, circlesize:circlesize)
	}, []];
	~scenetypes["driftysines"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son = ~npendulums.collect{|which| SinOsc.ar(rrand(220, 660) * freqscale)} * 0.1;
		var sub = {SinOsc.ar(rrand(20, 60))}.dup(~nsubs) * 0.4;
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["frag_pwm"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var phases, son, onewidth, amps, sub, freq;
		width = width.linlin(0,1,1,~npendulums); // nb we handle width ourselves, to get the pwm right
		phases = (0..~npendulums-1) * 0.5 / ~npendulums;
		onewidth = 0.5 / ~npendulums;
		amps = ~npendulums.collect{|index| width.linlin(index, index+1, 0, 1)};
		freq = In.kr(~basefreqbus) * 0.25 * freqscale;
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
		~sceneenveloper.value(son, sub, onescenepos, 1, circlesize:circlesize)
	}, [["misalign (0--1)", 0], ["histuff (0--1)", [1,0,1]]]];
	/*
	~scenetypes["frag_pwm2"] = [{|pendspos, onescenepos, width, freqscale, threevals|
	var phases, son, onewidth, amps, sub, freq;
	width = width.linlin(0,1,1,~npendulums); // nb we handle width ourselves, to get the pwm right
	phases = (0..~npendulums-1) * 0.5 / ~npendulums;
	onewidth = 0.5; //0.5 / ~npendulums;
	amps = ~npendulums.collect{|index| width.linlin(index, index+1, 0, 1)};
	freq = 0.5 * IRand(25, 35).midicps * freqscale;
	son = ~npendulums.collect{|which|
	LFPulse.ar(freq, phases[which], onewidth, amps[which]).lag(0.007) * 1.3;
	} * 0.1;
	sub = ~nsubs.collect{|which|
	DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, 1, circlesize:circlesize)
	}, []];
	*/
	~scenetypes["tracer"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		var pos, trig, rawson, scaler, panenv, thruspeed;
		//scaler = MouseX.kr(0.5, 5, 1); //.poll(1, "mousex");
		scaler    = ~pendvalto3val_exp.value(pendspos[0][1], threevals[0]).linexp(0,1, 0.5, 5); // NOTE READING FROM ZEROTH PEND ONLY
		thruspeed = ~pendvalto3val_exp.value(pendspos[0][0], threevals[1]); // NOTE READING FROM ZEROTH PEND ONLY
		trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2);
		//		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, 20000), phase: 0.5pi);
		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, MouseY.kr(100, 10000).poll(1, "mousey topfreq")), phase: 0.5pi);
		rawson = rawson * EnvGen.ar(Env.perc(0, 0.1), trig, timeScale: scaler);
		rawson = HPF.ar(rawson, 5000) * 0.25;
		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var del = which * 0.06;
			DelayC.ar(rawson, del * 4, del * thruspeed.reciprocal);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0); // TODO crossover filter
		};
		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["zappiness", 0], ["thruspeed", 1]]];
	~scenetypes["tracerbeep"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		var pos, trig, rawson, scaler, panenv;
		trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2);

		//rawson = (SinOsc.ar(1300 * [1,3,5,7]).mean * MouseY.kr(2,4)).clip2;
		rawson = SinOsc.ar(1300 * [1,12,13,14], 0.5pi).mean.clip2;
		rawson = rawson * 0.4 * EnvGen.ar(Env.adsr(0, 0.01, 0.25, 0.01), Trig1.kr(trig, dur: 0.1));

		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var distort = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			var del = which * 0.06;
			DelayC.ar((rawson * distort.linexp(0, 1, 1, 10)).atan, del, del) * amp;
		}.reverse;
		sub = ~nsubs.collect{|which|
			DC.ar(0); // TODO crossover filter
		};
		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["amp", 1], ["distort 0--1", [0, 0.4, 0]]]];
	/*
	~scenetypes["tracerburr"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		var pos, trig, rawson, scaler, panenv;
		trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2);

		rawson = (SinOsc.ar(1300 * [1,15,27,33]).mean * MouseY.kr(2,4)).clip2;
		rawson = rawson * 0.1 * EnvGen.ar(Env.adsr(0.01, 0.01, 0.5, 0.01), Trig1.kr(trig, dur: 0.3));

		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var distort = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			var del = which * 0.06;
			DelayC.ar((rawson * distort.linexp(0, 1, 1, 10)).atan, del, del) * amp;
		}.reverse;
		sub = ~nsubs.collect{|which|
			DC.ar(0); // TODO crossover filter
		};
		~sceneenveloper.value(son, sub, onescenepos, 1, false, circlesize:circlesize) // no width
	}, [["amp", 1], ["distort 0--1", [0, 0.4, 0]]]];
	*/
	~scenetypes["crickle_hi"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var sig, density, lowconv;
			density = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			lowconv = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			sig = Dust2.ar(density);
			sig = HPF.ar(sig, 15000 /* MouseX.kr(5000, 20000, 1) */, 0.7);
			//sig = BPF.ar(sig, MouseX.kr(1000, 5000, 1)) + BPF.ar(sig, MouseY.kr(100, 1000, 1).poll);
			sig = XFade2.ar(sig, FreeVerb.ar(sig) * BrownNoise.ar(2), lowconv * 2 - 1);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["density", [2, 400, 2]], ["lowconv (0--1)", 1]]];
	~scenetypes["puresine01"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var freq   = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var detune = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			(SinOsc.ar(freq + ([detune, 0-detune])).mean) * 0.1;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["freq", 880], ["detune", 2.5]]];
	/*
	~scenetypes["puresine03"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub;
	son = ~npendulums.collect{|which|
	(SinOsc.ar([50] * freqscale + [0, 0]).mean) * 0.1 * SinOsc.ar(1).range(0.5, 1)
	+
	(SinOsc.ar([200] * freqscale + [0, 0]).mean) * 0.1 * SinOsc.ar(4).range(0.5, 1)
	};
	sub = ~nsubs.collect{|which|
	DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, []];
	*/
	~scenetypes["puresine03"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreq = In.kr(~basefreqbus);
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
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		[son, sub]
	}, [["amp", [1,0,1]], ["modrate", [8,2,8]]]];
	/*
	~scenetypes["wubthr"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreq = In.kr(~basefreqbus);
		son = ~npendulums.collect{|which|
			var amp, modrate, atrig;
			amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			modrate = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			atrig = Impulse.kr(ExpRand(0.2, 2), Rand(0, pi));
			(
				SinOsc.ar(EnvGen.kr(Env.perc(0.4, 0.4), atrig).range(20, 120), 0, EnvGen.kr(Env.perc(0.4, 0.4), atrig))
				+
				HPF.ar(WhiteNoise.ar, 15000, 0.2 * EnvGen.ar(Env.perc(0.2, 0.4).delay(0.3), atrig))
			) * 0.1 * amp
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		[son, sub]
	}, [["amp", [1,1,1]], ["modrate", [8,2,8]]]];
	*/
	~scenetypes["passingzero_frompend"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var tester = (pendspos[which][1]).sign;
			SinOsc.ar((83 + which).midicps, 0, EnvGen.ar(Env.perc(0.01, 0.1), HPZ1.kr(tester))) * 0.2;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		[son, sub]
	}, []];
	~scenetypes["hinoise"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var locut   = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var decimate= ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);

			HPF.ar(PinkNoise.ar, locut) * locut.linlin(3000, 15000, 0.1, 0.5); // 10000 default
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["locut", [15000, 3000, 15000]], ["[unused]", 0]]];
	/*
	~scenetypes["lonoise"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var hicut   = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			LPF.ar(BrownNoise.ar, hicut) * 0.5;
		} * 0.3;
		sub = ~nsubs.collect{|which|
			LPF.ar(BrownNoise.ar, 100);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["locut", [5000, 20000, 5000]]]];
	*/
	[["sin", SinOsc] /* , ["saw", LFSaw] */ ].do{|adata|
		~scenetypes["tonestack01" ++ adata[0]] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
			var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps, fmlfo;

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
			~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
		}, [["fmdepth 0--1", 0], ["freqscale", 1]]];
	}; // end adata iter

	/*
	~scenetypes["numharm01"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, numharm, fm, freqsel, amps, fmlfo;

		basefreqs = [60, 90, 120, 240, 480].scramble * 0.5 * freqscale;
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.4, 0.1];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		fmlfo = LFNoise0.ar(400);

		son = harmstack.mean{|val, harmindex|
			freqs.collect{|afreq, which|
				var numharm = ~pendvalto3val_lin.value(pendspos[which][1], threevals[0]);
				var freqscale2 = ~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
				Blip.ar(afreq * val * freqscale2 * harmindex, numharm, mul: 0.05 * harmamps[harmindex])
			};
		};
		son = LeakDC.ar(son);

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
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["#harmonics 1-100", [10, 1, 10]], ["freqscale", 1]]];
	*/

	/*
	~scenetypes["numharm02"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, numharm, fm, freqsel, amps, fmlfo;

		basefreqs = [60, 90, 120, 240, 480].scramble * 0.5 * freqscale;
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.4, 0.1];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		fmlfo = LFNoise0.ar(400);

		son = harmstack.mean{|val, harmindex|
			freqs.collect{|afreq, which|
				var numharm = ~pendvalto3val_lin.value(pendspos[which][1], threevals[0]);
				var freqscale2 = ~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
				var myfreq = afreq * val * freqscale2 * harmindex;
				LPF.ar(LFSaw.ar(myfreq), (myfreq * numharm).clip(100, 22000))
				  * (0.05 * harmamps[harmindex]);
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
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["#harmonics 1-200", [10, 1, 10]], ["freqscale", 1]]];
	*/


	~scenetypes["drift_sine"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, freqsel, amps;

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
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["UNUSED", 1], ["freqscale", 1]]];
	~scenetypes["superhigh"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps;

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
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["distort", 0], ["amp", 1]]];
	~scenetypes["tonestack01tri02"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, freqsel, amps;

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
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, [["harmonic stretch 0--1", 0], ["freqscale", 1]]];
	~scenetypes["silent"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			DC.ar(0);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	}, []];
	~scenetypes["speakerTEST"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var imps, bongs, sub;

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
		[bongs, sub]
	}, []];
	/*
	~scenetypes[""] = {|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub, val1, val2;
	val1 = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
	val2 = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
	son = ~npendulums.collect{|which|
	DC.ar(0);
	};
	sub = ~nsubs.collect{|which|
	DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize)
	};
	*/
	// end scenetypes
	//////////////////////////////////////////////////////////////////////////////////////

	// now a nodeproxy for each scene instance
	~sceneplayers = ~nscenes.collect{|which|
		var np = NodeProxy.audio(s, ~npendulums + ~nsubs);
		var onegroup = Group.tail(~scenesgroup);
		np.group_(onegroup);
		np.fadeTime_(4);
		np.set(\width, 0);
		np
	};

	~pushascene = {|scenename, whichnp|
		s.bind{
			//"pushing tweakyvals".postln;
			// This pushes the default tweaky vals to the appropriate bus
			~scenevalpointsbus[whichnp].setn(2.collect{|whichone| 3.collect{|whichsubboxer|
				(~scenetypes[scenename][1][whichone] ? [\nil, 1])[1].asArray.wrapAt(whichsubboxer)
			}}.flat);
			//"pushed tweakyvals".postln;
			// And this actually pushes the patch
			~sceneplayers[whichnp].source = {|amp=0.7, width=0.5, freqscale=1, circlesize=1|
				var onescenepos = In.kr(~sceneposbus.index + whichnp, 1);
				var pendspos = In.kr(~pendbus, ~npendulums * 2).clump(2);
				var threevals = In.kr(~scenevalpointsbus[whichnp], 6).clump(3);
				var allson = ~scenetypes[scenename][0].value(pendspos, onescenepos, width, freqscale, threevals, circlesize) * amp;
				//(0..2).do{|outeri| pendspos[outeri].collect{|apend, apendi| apend.poll(0.25, "pendspos[%][%]".format(outeri, apendi))}};
				//threevals.do{|a1val, which1val| a1val.do{|a3val, which3val| a3val.poll(0.25, "threevals[%][%]".format(which1val, which3val))}};
				Out.ar(~finalaudiobus, allson[0]);
				Out.ar(~subbus, allson[1]);
			}
		}
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
