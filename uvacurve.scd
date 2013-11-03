// s.boot
(
// Settings:
~stereoonly = true; //false;
~hw_midbus = 0;
~hw_subbus = 0;
~hardmul = if(~stereoonly){1}{0.05};
////////////////////////
s.waitForBoot{
	~npendulums = 4;
	~nscenes    = 2;
	~nsubs      = 2;
	// busses
	~pendbus = Bus.control(s, ~npendulums * 2); // later we may want fixed indexing
	~sceneposbus = Bus.control(s, ~nscenes);
	~finalaudiobus = Bus.audio(s, ~npendulums);
	~subbus = Bus.audio(s, ~nsubs);
	// groups
	~ksettersgroup = Group.head(s.defaultGroup); // group for things that set control busses
	~scenesgroup = Group.after(~ksettersgroup);
	~postfxgroup = Group.after(~scenesgroup);
	~outputtersgroup = Group.after(~postfxgroup);

	// - SYNTH: pulsespos - a single synth that implements some kind of chaotic attractor or something, that ensures the scenes are dynamically moving around and mostly stay spatially separate from each other.
	~scenepossynth = {
		var posses = {LFPar.kr(LFPar.kr(exprand(0.1, 10)).exprange(exprand(0.05, 0.1), exprand(0.1, 0.4))).range(0,1)}.dup(~nscenes);
		Out.kr(~sceneposbus, posses);
	}.play(~ksettersgroup);
	// ~sceneposbus.scope

	// - SYNTH: fakependulums - let's send SinOsc.kr(exprand(0.08, 0.13), 2pi.rand) to the busses for test.
	~fakependulums = {
		var pendpos = {SinOsc.kr(exprand(0.08, 0.13), 2pi.rand)}.dup(~npendulums * 2);
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
	~sceneenveloper = {|audio, sub, position, width|
		var distances = ((0..~npendulums-1) - (position * ~npendulums)).abs;
		var subdistances = ((0..~nsubs-1) - (position * ~nsubs)).abs;
		// when width is 0, we are only on the nearest one (i.e. distances <= 0.5) - NEVER not on one!
		//   this means that any dist <=0.5 has to be treated the same.
		// when width is 1, we are equally over all of them, irrespective of dist.
		//distances.poll(1);
		audio = distances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~npendulums).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			audio[which] * distmul;
		};
		sub = subdistances.collect{|adist, which|
			var distmul = ((adist-0.5).max(0)/~nsubs).linexp(0, 1, 1, width.min(0.999).max(0.001));
			//distmul.poll(1);
			sub[which] * distmul;
		};
		[audio, sub] // return
	};

	//////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////
	// First we define the available scene types. each takes pendpos and a scenepos as input and returns [audio * 16, sub * 4] or whatever
	~scenetypes = Dictionary();
	~scenetypes["testimpulse"] = {|pendspos, onescenepos, width|
		var son = {CombN.ar(Dust2.ar(3), 0.025, 0.025, 0.5)}.dup(~npendulums);
		var sub = {256 * LPF.ar(Dust2.ar(1), 100)}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	~scenetypes["testsine"] = {|pendspos, onescenepos, width|
		var son = ~npendulums.collect{|which| SinOsc.ar(rrand(220, 660))};
		var sub = {SinOsc.ar(rrand(20, 60))}.dup(~nsubs);
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	~scenetypes["frag_pwm"] = {|pendspos, onescenepos, width|
		var phases, son, onewidth, amps, sub, freq;
		width = width.linlin(0,1,1,~npendulums); // nb we handle width ourselves, to get the pwm right
		phases = (0..~npendulums-1) * 0.5 / ~npendulums;
		onewidth = 0.5 / ~npendulums;
		amps = ~npendulums.collect{|index| width.linlin(index, index+1, 0, 1)};
		freq = 43.midicps;
		freq = 30.midicps;
		son = ~npendulums.collect{|which|
			LFPulse.ar(freq, phases[which], onewidth, amps[which]);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, 1)
	};
	~scenetypes["tracer"] = {|pendspos, onescenepos, width|
		var son, sub;
		var pos, trig, rawson, scaler, panenv;
		scaler = MouseX.kr(0.5, 5, 1).poll(1, "mousex");
		trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2);
		//		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, 20000), phase: 0.5pi);
		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, MouseY.kr(100, 10000).poll(1, "mousey topfreq")), phase: 0.5pi);
		rawson = rawson * EnvGen.ar(Env.perc(0, 0.1), trig, timeScale: scaler);
		rawson = HPF.ar(rawson, 5000) * 4;
		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var del = which * 0.06;
			DelayC.ar(rawson, del, del);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0); // TODO crossover filter
		};
		~sceneenveloper.value(son, sub, onescenepos, 1) // no width
	};
	~scenetypes["tracer02"] = {|pendspos, onescenepos, width|
		var son, sub;
		var pos, trig, rawson, scaler, panenv;
		scaler = MouseX.kr(0.5, 5, 1).poll(1, "mousex");
		trig = Dust.kr(LFPar.kr(0.1).range(0, 1).squared * 2);
		//		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, 20000), phase: 0.5pi);
		rawson = SinOsc.ar(EnvGen.ar(Env.perc(0.0, 0.01 * 0.75), trig, timeScale: scaler).exprange(0.15, MouseY.kr(100, 10000).poll(1, "mousey topfreq")), phase: 0.5pi);
		rawson = rawson * EnvGen.ar(Env.perc(0, 0.1), trig, timeScale: scaler);
		rawson = HPF.ar(rawson, 5000) * 4;
		// Now we delay-and-splay it so as to zap across speakers
		son = ~npendulums.collect{|which|
			var del = which * 0.06;
			DelayC.ar(rawson, del, del);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0); // TODO crossover filter
		};
		~sceneenveloper.value(son, sub, onescenepos, 1) // no width
	};
	~scenetypes["hinoise"] = {|pendspos, onescenepos, width|
		var son, sub;
		son = ~npendulums.collect{|which|
			HPF.ar(PinkNoise.ar, MouseX.kr(5000, 20000, 1)) * MouseX.kr(1, 5, 1); // 10000 default
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	~scenetypes["lonoise"] = {|pendspos, onescenepos, width|
		var son, sub;
		son = ~npendulums.collect{|which|
			LPF.ar(BrownNoise.ar, MouseX.kr(5000, 20000, 1)) * 0.5;
		};
		sub = ~nsubs.collect{|which|
			LPF.ar(BrownNoise.ar, 100);
		};
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	[["sin", SinOsc], ["saw", LFSaw]].do{|adata|
		~scenetypes["tonestack01" ++ adata[0]] = {|pendspos, onescenepos, width|
			var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps;

			basefreqs = [120, 240, 480].scramble;
			harmstack = [1, 1.5, 2];
			harmamps = [1.5, 0.5, 0.3];

			freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

			fmdepth = MouseX.kr(-0.5, 0.5).max(0);
			fm = LFNoise0.ar(400).exprange(1 - fmdepth, 1 + fmdepth);

			son = harmstack.mean{|val, index| adata[1].ar(freqs * val * (fm * index), mul: 0.05 * harmamps[index])};

			freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/60, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
			//freqsel.poll;
			son = (son * freqsel).sum;

			amps = ~npendulums.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly across speakers; higher, atomised.

			son = son * amps * 15;

			sub = ~nsubs.collect{|which|
				DC.ar(0);
			};
			~sceneenveloper.value(son, sub, onescenepos, width)
		};
	}; // end adata iter
	~scenetypes["tonestack01sin02"] = {|pendspos, onescenepos, width|
		var son, sub, basefreqs, harmstack, harmamps, freqs, fmdepth, fm, freqsel, amps;

		//basefreqs = [120, 180, 240, 360, 480].scramble;
		basefreqs = [120, 130] * 3;
		harmstack = [1, 1.5, 2];
		harmamps = [1.5, 0.5, 0.3];

		freqs = basefreqs.collect{|bfreq| Array.series(~npendulums, bfreq, 0)};

		//fmdepth = MouseX.kr(0.000001, 0.5);
		fm = Gate.kr(MouseY.kr(0.5, 1, 1), Impulse.kr(0) + MouseButton.kr);

		son = harmstack.mean{|val, index| SinOsc.ar(freqs * val * (fm * index), mul: 0.05 * harmamps[index])};

		freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/20, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
		freqsel.poll;
		son = (son * freqsel).sum;

		amps = ~npendulums.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly across speakers; higher, atomised.

		son = son * amps * 15;

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	~scenetypes["silent"] = {|pendspos, onescenepos, width|
		var son, sub;
		son = ~npendulums.collect{|which|
			DC.ar(0);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	~scenetypes["speakerTEST"] = {|pendspos, onescenepos, width|
		var imps, bongs, sub;

		imps = Impulse.ar(2 / ~npendulums,
			(1..~npendulums)/(~npendulums+1)) // These fire on individual channels
		+
		Impulse.ar(2/~npendulums)  // This one fires on all channels
		;

		bongs = SinOsc.ar(
			{(10.rand + 50).midicps}.dup(~npendulums).postln + LFNoise2.kr(10, 40)
		);
		bongs = bongs + WhiteNoise.ar(0.25);
		bongs = bongs * EnvGen.ar(Env.perc(0.02, 0.05, curve: [2, 0]), imps);

		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		[bongs, sub]
	};
	/*
	~scenetypes["fizzlein"] = {|pendspos, onescenepos, width|
	var son, sub, freq;
	freq = 110;
	son = ~npendulums.collect{|which|
	WaveLoss.ar(Pulse.ar(freq * [1,2,4, 16]).mean, (pendspos[which][0] * 40).abs, mode:2);
	};
	sub = ~nsubs.collect{|which|
	SinOsc.ar(freq * 0.25);
	};
	~sceneenveloper.value(son, sub, onescenepos, width)
	};
	*/
	~scenetypes["antiphase"] = {|pendspos, onescenepos, width|
		var son, sub, phase, basefreq=180;
		son = ~npendulums.collect{|which|
			phase = (which % 2) * pi;
			//SinOsc.ar(basefreq * [1, 2, 4, 8], phase, [1, 0.9, 0.8, 0.7]).mean
			SinOsc.ar(basefreq * [1], phase, [1, 0.9, 0.8, 0.7]).mean
		};
		sub = ~nsubs.collect{|which|
			phase = (which % 2) * pi;
			SinOsc.ar(basefreq * 0.5, phase)
		};
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	~scenetypes["linharm"] = {|pendspos, onescenepos, width|
		var son, sub, basefreq = 110;
		//var harms = [1,2,4,8,16]
		var harms = [1,2,3,4,5,6,7];
		var reamp = harms.sum{|val| 1/val.squared}.reciprocal;
		son = ~npendulums.collect{|which|
			harms.collect{|val|
				SinOsc.ar(basefreq * val, 0, 1/val.squared)
			}.sum * reamp;
		};
		sub = ~nsubs.collect{|which|
			SinOsc.ar(basefreq * 0.25, 0, 0.5)
		};
		~sceneenveloper.value(son, sub, onescenepos, width)
	};
	/*
	~scenetypes[""] = {|pendspos, onescenepos, width|
	var son, sub;
	son = ~npendulums.collect{|which|
	DC.ar(0);
	};
	sub = ~nsubs.collect{|which|
	DC.ar(0);
	};
	~sceneenveloper.value(son, sub, onescenepos, width)
	};
	*/
	// end scenetypes
	//////////////////////////////////////////////////////////////////////////////////////
	~defaultscenes = ["silent", "silent"]; // these are the ones that run on first invoke

	// now a nodeproxy for each scene instance
	~sceneplayers = ~nscenes.collect{|which|
		var np = NodeProxy.audio(s, ~npendulums + ~nsubs);
		np.group_(~scenesgroup);
		np.fadeTime_(4);
		np
	};

	~pushascene = {|scenename, whichnp|
		~sceneplayers[whichnp].source = {|amp=0.7, width=0.5|
			var onescenepos = In.kr(~sceneposbus.index + whichnp, 1);
			var pendspos = In.kr(~pendbus, ~npendulums * 2).clump(2);
			var allson = ~scenetypes[scenename].value(pendspos, onescenepos, width) * amp;
			Out.ar(~finalaudiobus, allson[0]);
			Out.ar(~subbus, allson[1]);
		}
	};

	// default scenes start playing
	~sceneplayers.do{|asp, which|
		~pushascene.value(~defaultscenes[which], which)
	};

	// - SYNTH: replaceout-based dopplerfaker. takes in the pendulumpos and uses a smoothed version of that.
	~radiusm = 1.5;
	~maxdoppler = 2 * ~radiusm / 330;
	~dopplerfaker = { |active=1|
		// For each pendulum, take in its y position, lag it, translate it into delay, take in its audio, replaceout
		var swingposses = In.kr(~pendbus, ~npendulums * 2)[1,3..];
		var audios = In.ar(~finalaudiobus, ~npendulums);
		audios = audios.collect{|anaudio, whichaudio|
			var delay = swingposses[whichaudio].lag(0.05).linlin(-1,1, 0, ~maxdoppler) * active;
			//delay.poll(1);
			DelayC.ar(anaudio, ~maxdoppler, delay);
		};
		ReplaceOut.ar(~finalaudiobus, audios);
	}.play(~postfxgroup, addAction: \addToTail);


	~outputter = {|out=0, amp=0.7, midamp=0.7, subamp=0.7, midon=1, subon=0, reverbon=1|
		if(~stereoonly){
			// - SYNTH: stereo mixdown - takes gallery listening position from the mouse, adds distance-based attenuation and reverb, pans using the pendulumpos data. takes mainamp and subamp as simple controls.
			var listenpos = MouseX.kr(0, ~npendulums-1);
			var rawsound = In.ar(~finalaudiobus, ~npendulums);
			var rawsub   = In.ar(~subbus, ~nsubs);
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
			var rawsound = In.ar(~finalaudiobus, ~npendulums);
			var rawsub   = In.ar(~subbus, ~nsubs);
			rawsound = FreeVerb.ar(rawsound, mix:0.3 * reverbon, room:0.5, damp:0.5, mul:1);
			Out.ar(~hw_midbus, rawsound * amp * midamp * midon * ~hardmul);
			Out.ar(~hw_subbus, rawsub   * amp * subamp * subon * ~hardmul);
		}
	}.play(~outputtersgroup);
}
)