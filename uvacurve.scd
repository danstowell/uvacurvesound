// s.boot
(
// Settings:
~defaultscenes = ["tonestack01sin", "silent", "silent", "silent"]; // these are the ones that run on first invoke
~stereoonly = false;
~hw_midbus = 0;
~hw_subbus = 4;
~athome = false;
~hardmul = if(~athome){10}{2};
"localsettings.scd".loadRelative;
////////////////////////
s.latency = 0.75;
s.options.numAudioBusChannels_(256);
s.options.numOutputBusChannels_(12);
s.options.numWireBufs = 128;
s.options.memSize = 8192 * 4;
s.waitForBoot{
	~npendulums = 12;
	~npendulums_true = 12; // only this many ACTUAL outputs sent, and the subs are sent to the next lot
	~nscenes    = 4;
	~nsubs      = 2;
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
	~sceneenveloper = {|audio, sub, position, width=0, movewith=true, circlesize=1, pendspos=nil|
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
		};
		audio = distances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~npendulums).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			distmul = distmul.squared;  /////// TEST IF HARDER ISOLATION IS GOOD
			audio[which] * distmul;
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
	~scenetypes["driftysines"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son = ~npendulums.collect{|which| SinOsc.ar(rrand(220, 660) * freqscale)} * 0.1;
		var sub = {SinOsc.ar(rrand(20, 60))}.dup(~nsubs) * 0.4;
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, []];
	*/
	~scenetypes["frag_pwm"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var phases, son, onewidth, amps, sub, freq, reltempo;
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
		son.do{|oneson, which|
			var reindex = (which * ((~nsubs-1)/(~npendulums-1))).floor;
			sub[reindex] = sub[reindex] + LPF.ar(oneson, 100);
		};
		~sceneenveloper.value(son, sub, onescenepos, 1, circlesize:circlesize, pendspos:pendspos)
	}, [["misalign (0--1)", 0], ["histuff (0--1)", [1,0,1]]]];
	/*
	~scenetypes["puresine01"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var freq   = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			var detune = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			(SinOsc.ar(freq + ([detune, 0-detune])).mean) * 0.05;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, [["freq", 880], ["detune", 2.5]]];
	*/
	~scenetypes["puresine03"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreq = In.kr(~basefreqbus);
		var reltempo = ~normalperiod * In.kr(~tempobus);
		//"threevals is: %".format(threevals).postln;
		son = ~npendulums.collect{|which|
			var amp, modrate;
			amp     = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
			modrate = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
			modrate = modrate * reltempo;
			(
				(SinOsc.ar([basefreq * 0.5] * freqscale)) * 0.1 * SinOsc.ar(0.25 * modrate).range(0.5, 1)
				+
				(SinOsc.ar([basefreq * 2.0] * freqscale)) * 0.1 * SinOsc.ar(1 * modrate).range(0.5, 1)
			) * amp
		};
		son = HPF.ar(son, 100); // from review, saw unwanted low component
		son = HPF.ar(son, 100); // from review, saw unwanted low component
		son = HPF.ar(son, 100); // from review, saw unwanted low component
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
		[son, sub]
	}, [["amp", [1,0,1]], ["modrate", [8,2,8]]]];
	~scenetypes["passingzero_frompend"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var tester = (pendspos[which][1]).sign;
			var env = EnvGen.ar(Env.perc(0.01, 0.1), HPZ1.kr(tester));
			SinOsc.ar((83 + which).midicps, 0, env) * 0.2;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
		[son, sub]
	}, []];
	~scenetypes["passingzero_frompend_conc"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			var radialpos = (pendspos[which][1].squared + pendspos[which][0].squared).sqrt;
			var envs = [0, 0.1, 0.2, 0.3, 0.4].collect{|radius, whichrad|
				var tester = (radius - radialpos).sign;
				EnvGen.ar(Env.perc(0.01, 0.1), HPZ1.kr(tester))
			};
			envs.collect{|env, whichrad|
				SinOsc.ar((83 + which + (whichrad * 4)).midicps, 0, env) * 0.2;
			}.sum;
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		//~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
		[son, sub]
	}, []];
	[["sin", SinOsc] /* , ["saw", LFSaw] */ ].do{|adata|
		~scenetypes["tonestack01" ++ adata[0]] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
			var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps, fmlfo;

			var freq = \freq.kr(120);

			basefreqs = freq * [0.5, 0.75, 1, 2, 4].scramble * 0.5 * freqscale;
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

			son = HPF.ar(son, 100); // from review, saw unwanted low component
			son = HPF.ar(son, 100); // from review, saw unwanted low component

			son = ~npendulums.collect{|which|
				son[which] * SinOsc.ar(0.125, (4-which) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)
			}; // pow 0.25 makes move smoothly across speakers; higher, atomised.

			son = son * 15;

			//freqscale.poll;

			sub = ~nsubs.collect{|which|
				SinOsc.ar((basefreqs * 0.25 * [1, LFPar.kr(0.1).range(1, 0.75)]).flat, mul: freqsel).sum * 0.1;
			};
			~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
		}, [["fmdepth 0--1", 0], ["freqscale", 1]]];
	}; // end adata iter
	~scenetypes["drift_sine"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, freqsel, amps;
		var reltempo = ~normalperiod * In.kr(~tempobus);

		//basefreqs = [120, 180, 240, 360, 480].scramble;
		basefreqs = [120, 130] * 3 * freqscale;
		basefreqs = basefreqs * -8.midiratio; // from review, preferred this
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.4, 0.1];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		son = harmstack.mean{|val, harmindex|
			freqs.collect{|afreq, which|
				var freqscale2 = ~pendvalto3val_lin.value(pendspos[which][0], threevals[1]);
				SinOsc.ar(afreq * val * freqscale2 * harmindex, mul: 0.05 * harmamps[harmindex])
			};
		};

		freqsel = basefreqs.collect{|val, index| SinOsc.kr(reltempo * 1/20, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
		//freqsel.poll;
		son = (son * freqsel).sum;

		son = son * 0.5; // Deliberately making it MORE subtle than the main bed

		amps = ~npendulums.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly across speakers; higher, atomised.

		son = son * amps * 15;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, [["UNUSED", 1], ["freqscale", 1]]];

	~scenetypes["tonestack01tri02"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub, basefreqs, harmstack, harmamps, freqs, freqsel, amps;

		var freq = \freq.kr(120);
		basefreqs = freq * [1, 1.5, 2, 3, 4].scramble * freqscale;
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
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, [["harmonic stretch 0--1", 0], ["freqscale", 1]]];

	"patches_utility.scd".loadRelative;
	"patches_bal.scd".loadRelative;
	"patches_elastic.scd".loadRelative;
	"patches_unbal.scd".loadRelative;
	"patches_hi.scd".loadRelative;
	"patches_short.scd".loadRelative;

	/*
	~scenetypes[""] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var son, sub, val1, val2;
	son = ~npendulums.collect{|which|
	val1 = ~pendvalto3val_exp.value(pendspos[which][1], threevals[0]);
	val2 = ~pendvalto3val_exp.value(pendspos[which][0], threevals[1]);
	DC.ar(0);
	};
	sub = ~nsubs.collect{|which|
	DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
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
		var arglistdict = arglist.asArray.as(Dictionary);
		scenename = scenename.asString;
		if(~scenetypes[scenename].isNil){
			"ERROR: ~pushascene..('%'): Scene name  not found".format(scenename).postln;
		}{
			var swoppo;
			"~pushascene.('%', %)".format(scenename, whichnp).postln;
			"Will initialise with width %".format(arglistdict[\width]).postln;
			// First we swap the double-buffering round, so that no-one else can address the old one
			swoppo = ~sceneplayers[whichnp];
			~sceneplayers[whichnp] = ~sceneplayers_offstage[whichnp];
			~sceneplayers_offstage[whichnp] = swoppo;
			//NodeProxy;
			// Now set the desired crossfade on both of them
			//"fade time %".format(xfade).postln;
			~sceneplayers[         whichnp].fadeTime_(xfade);
			~sceneplayers_offstage[whichnp].fadeTime_(xfade);
			~sceneplayers[         whichnp].set(\xfade, xfade);
			~sceneplayers_offstage[whichnp].set(\xfade, xfade);
			s.bind{
				// Fade out the old one
				~sceneplayers_offstage[whichnp].source = {
					Out.ar(~finalaudiobus, DC.ar(0).dup(~npendulums + ~nsubs));
				};
				// NOW we're at the point of constructing our new one
				//"pushing tweakyvals".postln;
				// This pushes the default tweaky vals to the appropriate bus
				~scenevalpointsbus[whichnp].setn(2.collect{|whichone| 3.collect{|whichsubboxer|
					(~scenetypes[scenename][1][whichone] ? [\nil, 1])[1].asArray.wrapAt(whichsubboxer)
				}}.flat);
				//"pushed tweakyvals".postln;
				// And this actually pushes the patch
				~sceneplayers[whichnp].source = {|circlesize=1, gate=1|
					var amp       = \amp.kr(      arglistdict[\amp]       ? 0.7, 0.05, true);
					var width     = \width.kr(    arglistdict[\width]     ? 0.5, 0.05, true);
					var freqscale = \freqscale.kr(arglistdict[\freqscale] ? 1, 0.05, true);
					var fadein = 1; // XLine.ar(0.0001, 1, xfade);
					var fadeenv = EnvGen.ar(Env.asr(1, 1, 1), gate, timeScale:\xfade.kr(xfade, 0, true), doneAction: 2);
					var onescenepos = In.kr(~sceneposbus.index + whichnp, 1);
					var pendspos = In.kr(~pendbus, ~npendulums * 2).clump(2);
					var threevals = In.kr(~scenevalpointsbus[whichnp], 6).clump(3);
					var mids, subs;
					# mids, subs = ~scenetypes[scenename][0].value(pendspos, onescenepos, width, freqscale, threevals, circlesize);
					Out.ar(~finalaudiobus, mids * amp * fadein * fadeenv);
					Out.ar(~subbus, subs * amp * fadein * fadeenv);
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
