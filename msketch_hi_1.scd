s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.05)}.play(s, addAction:\addToTail); //~ssh.free
~twelve.scope;

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


