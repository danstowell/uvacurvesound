~scenetypes["sub_simplest"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, gate=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|   DC.ar(0) };
	sub = ~nsubs.collect{|which|
		var son;
		son = SinOsc.ar(32.midicps);
		son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	};
	[sons, sub]
}, []];

~scenetypes["sub_intersimple"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, gate=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|   DC.ar(0) };
	sub = ~nsubs.collect{|which|
		var son;
		son = SinOsc.ar([32, 31].midicps, mul:[1, LFPar.kr(0.1).range(0, 1)]).mean;
		son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	};
	[sons, sub]
}, []];

~scenetypes["sub_intersimple2"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, gate=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|   DC.ar(0) };
	sub = ~nsubs.collect{|which|
		var son;
		son = SinOsc.ar([34, 33.5].midicps, mul:[1, LFPar.kr(0.1).range(0, 1)]).mean;
		son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	};
	[sons, sub]
}, []];

~scenetypes["sub_intersimple_golo"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, gate=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|   DC.ar(0) };
	sub = ~nsubs.collect{|which|
		var son;
		son = SinOsc.ar([30, Line.kr(30.15, 30, 150)].midicps, mul:[1, LFPar.kr(0.1).range(0, 1)]).mean;
		son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	};
	[sons, sub]
}, []];

~scenetypes["sub_interpulse"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, gate=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|   DC.ar(0) };
	sub = ~nsubs.collect{|which|
		var son;
		son = 2.collect{|which|
			var trig = Impulse.kr(0.2, which * 0.5);
			var env = EnvGen.ar(Env.linen(0.1, 6, 4), trig);
			var note = TIRand.kr(28, 33, trig);
			son = SinOsc.ar(note.midicps, mul:env);
		}.mean;
	};
	[sons, sub]
}, []];

~scenetypes["sub_subriffle"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1, gate=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|   DC.ar(0) };
	sub = ~nsubs.collect{|which|
		var son, nu;
		var addmidi = 0;//MouseX.kr(0, 40).round.poll(1);
		son = (([34, 46] + addmidi).midicps.collect{|freq, inwhich|
			var trig = Dust2.kr(0.8);
			var lev  = Latch.kr(trig, trig.abs) - 0.5;
			SinOsc.ar(freq + EnvGen.ar(Env.perc(0.4, 0.4), trig.abs, 5 * lev))
		} * [1, 0.1]).sum * 0.7;
		son = son * (1-EnvGen.ar(Env.perc(1.5, 1, 0.75), Dust.kr(0.1))); // occasional gentle release
		son = son * EnvGen.ar(Env.asr(0.1), gate, doneAction: 2);
	};
	[sons, sub]
}, []];

