/*
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
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, [["locut", [15000, 3000, 15000]], ["[unused]", 0]]];
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
		~sceneenveloper.value(son, sub, leds, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
	}, [["density", [2, 400, 2]], ["lowconv (0--1)", 1]]];
*/

