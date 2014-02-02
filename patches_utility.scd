	~scenetypes["silent"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
		var son, sub;
		son = ~npendulums.collect{|which|
			DC.ar(0);
		};
		sub = ~nsubs.collect{|which|
			DC.ar(0);
		};
		~sceneenveloper.value(son, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
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
