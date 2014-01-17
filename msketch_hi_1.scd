s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.05)}.play(s, addAction:\addToTail); //~ssh.free
~twelve.scope;

~dobuf = Buffer.alloc(s, 65536, 1);
~dobuf = Buffer.alloc(s, 65536, 2);
~dobuf.write("~/git/uvacurve/recordings/recorded.wav".standardizePath, "wav", "int24", 0, 0, true);
// then record, then
x.free;
~dobuf.close;
~dobuf.free; ~dobuf = nil;

(
x = {
	// hi wander hiss
	var sons;
	sons = 12.collect{|val|
		var locut, son;
		locut = LFDNoise1.kr(10).exprange(10000, 15000);
		son = HPF.ar(PinkNoise.ar, locut) * locut.linlin(3000, 15000, 0.1, 0.5);
		son = son + Resonz.ar(son, (val + 5) * 1000) * 1;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)


(
x = {
	// hi ring speckle
	var sons;
	sons = 12.collect{
		var son, env;
		env = HPF.ar(EnvGen.ar(Env.perc(0.1, 1), Dust.ar(1)), 10000).linlin(0,1, 0.8, 1);
		son = LPF.ar(HPF.ar(WhiteNoise.ar * env, 5000) * LPF.ar(WhiteNoise.ar()>LFPar.kr(0.1, 2.rand).range(0.5,1), 5000), 1000);
		son = (LPF.ar(HPF.ar(son.round(0.5), 3000), 5000) * 5) + (Ringz.ar(son, 6.collect{exprand(1000, 10000)} * 3).mean * 0.15);
		son = BPF.ar(son, 800) * 30;
		//Amplitude.ar(son).poll;
		son
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play
)


(
x = {
	// hi ring ding
	var sons;
	sons = 12.collect{
		var son, env;
		env = HPF.ar(EnvGen.ar(Env.perc(0.001, 0.1), Dust.ar(100)), 10000);
		son = LeakDC.ar(Ringz.ar(env, 16.collect{exprand(800, 12000)} * 3).mean * 1.5);
		//son = BPF.ar(son, 800) * 8;
		son = HPZ1.ar(son) * 4;
		son = LPF.ar(son, 10000);
		Amplitude.ar(son).poll;
		son
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play
)


(
x = {
	// hi slippytick
	var sons, rate, ourdevrate;
	rate = LFDNoise1.kr(0.1).range(10, 20) * XLine.kr(0.1, 1, 1);
	ourdevrate = LFDNoise1.kr(0.05).range(0.05, 0.1);
	sons = 12.collect{
		var son;
		var dev = (LFTri.kr(ourdevrate) + LFDNoise1.kr(0.1, 0.3)).max(0) * 0.1;

		son = Impulse.ar(rate /* 25 */ /* * ExpRand(20, 30) */ ) * WhiteNoise.ar;

		son = son + 3.collect{
			DelayN.ar(son, 0.1, dev * Rand(0, 1))
		}.sum
	};
	sons = LPF.ar(HPF.ar(sons, 5000), 10000);
	//Amplitude.ar(sons, 0.0001, 1).mean.poll;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[0].dup
}.play
)



(
x = {
	// hi thiffle - MEHHHHHHHHHHH

	var sons;
	sons = 12.collect{|val|
		var son;
		var addmidi = 57; //47;//MouseX.kr(0, 40).round.poll(1);
		son = ((3.collect{(55..70).choose} + addmidi).midicps.collect{|freq, inwhich|
			SinOsc.ar(freq)
		} * [1, 0.7, 0.25]).sum * 0.03;
	};
	sons = sons.collect{|son|
		son = son * LFSaw.kr(0.3 + (ExpRand(0.001, 0.2) * LFPar.kr(0.07).range(0,1)), Rand(pi)).neg.exprange(0.1, 1);
		son = son + (Amplitude.kr(son).poll * (son * HPF.ar(WhiteNoise.ar, 10000))) * 3;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;




(
x = {
	// hi fabrickle
	var sons;
	sons = 12.collect{
		var son, env, trig;
		trig = Dust.ar(LFPulse.kr(ExpRand(0.05, 0.1), Rand(0, 2)).range(30, 100));
		son = EnvGen.ar(Env.perc(0.002, 0.01), trig, timeScale:TExpRand.kr(0.5, 2, trig));
		son = HPF.ar(son, 10000);
		son = Klank.ar(`[24.collect{exprand(14000, 18000)}, nil, 24.collect{0.1}], son);
		son = son * 3;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play
)


(
x = {
	// hi clickwerk
	var son, trig;

	trig = Impulse.ar( Duty.kr(0.5, 0, Dxrand([5, 10, 15].stutter(3) ++ [20, 40], inf))  );
	trig = trig * LFPulse.ar(1/16);
	son = Decay2.ar(trig, 0.008, 0.02) * LPF.ar(HPF.ar(WhiteNoise.ar, 10000), 12000);

	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)};
	son.dup;
}.play
)


FreqScope()
