s.boot;

(
{
	// hi wander hiss
	var sons;
	sons = 3.collect{|val|
		var locut, son;
		locut = LFDNoise1.kr(1).exprange(3000, 15000);
		son = HPF.ar(PinkNoise.ar, locut) * locut.linlin(3000, 15000, 0.1, 0.5);
		son = son + Resonz.ar(son, (val + 5) * 1000);
	};
	Splay.ar(sons);
}.play;
)

(
{
	var envs = 5.collect{ EnvGen.ar(Env.perc, Dust.kr(0.5)) };
	var sons = envs.collect{|env| (env + 0.5) * HPF.ar(WhiteNoise.ar, 1500) };
//	sons = sons.collect{|son| Friction.ar(klank, friction: 1.75584e-5, mass: 2.69789)};
	// TODO need sc3-plugins on the machine, for Friction ********************************************************
	Splay.ar(sons);
}.play
)


