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
