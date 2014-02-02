~scenetypes["click_wood"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|
		var son, trig;
		trig = Impulse.ar(1/3.7, 0.99);
		son = Klank.ar(`[[ 898.57360436391, 872.5298557576, 782.59036890516, 522.91466105288, 607.05406376995, 506.90960173234, 886.07016472432, 961.1559397461, 553.33696697469, 767.22393448859 ]
			, nil, {0.1}.dup(10)], trig);
	};
	sub = ~nsubs.collect{|which| DC.ar(0)};
	sons = sons.clip2(1) * 0.1;
	sons = sons + HPF.ar(sons, 1000);
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["click_metallic"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|
		var son, trig;
		trig = Impulse.ar(1/3.7, 0.99);
		son = Klank.ar(`[[ 1673.7309187879, 3530.0518140983, 1837.6414495397, 3762.8005580855, 3740.1288428511, 2974.533084582, 1966.6477137549, 2161.7169830521, 2451.2064295, 1708.2406493548 ]
			, nil, {0.1}.dup(10)], trig);
	};
	sub = ~nsubs.collect{|which| DC.ar(0)};
	sons = sons.clip2(1) * 0.1;
	sons = sons + HPF.ar(sons, 1000);
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["click_flint"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|
		var son, trig;
		trig = Impulse.ar(1/3.7, 0.99);
		son = Klank.ar(`[[ 9832.1833187756, 7733.5246778064, 9358.2628378095, 7756.069229784, 5058.8088845282, 9367.2957711644, 9739.0695928308, 7487.1737936217, 8103.4010087982, 8389.1871626481 ]
			, nil, {0.03}.dup(10)], trig);
	};
	sub = ~nsubs.collect{|which| DC.ar(0)};
	sons = sons.clip2(1) * 0.1;
	sons = sons + HPF.ar(sons, 1000);
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

~scenetypes["click_lighter"] = [{|pendspos, onescenepos, width, freqscale, threevals, circlesize=1|
	var sons, sub;
	sons = ~npendulums.collect{|which|
		var son, trig, env, noise, ress;
		noise = WhiteNoise.ar * LFPar.ar(100);
		trig = Impulse.ar(1/3.7, 0.99);
		env = EnvGen.ar(Env.perc(0.065, 0.02, curve:[4, -2]), trig);
		son = noise * env;
		son = son + EnvGen.ar(Env.perc(0.065, 0.02, 5, curve:[400, -200]), trig); // very narrow impulse added

		son = son.clip2(1) * 0.4;

		son = son + HPF.ar(son, 1000);
	};
	sub = ~nsubs.collect{|which| DC.ar(0)};
	sons = sons.clip2(1) * 0.1;
	sons = sons + HPF.ar(sons, 1000);
	~sceneenveloper.value(sons, sub, onescenepos, width, circlesize:circlesize, pendspos:pendspos)
}, []];

