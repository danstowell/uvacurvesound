s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.1)}.play(s, addAction:\addToTail); //~ssh.free; x.free;
~twelve.scope;

~dobuf = Buffer.alloc(s, 65536, 2);
~dobuf.write("~/git/uvacurve/recordings/recorded.wav".standardizePath, "wav", "int24", 0, 0, true);
// then record, then
x.free;
~dobuf.close;
~dobuf.free; ~dobuf = nil;


(
x = { // unbal clustpot
	var clusts, sons;
	clusts = 4.collect{
		4.collect{
			var freq = TIRand.kr(45, 65, Dust.kr(0.03)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
	sons = sons * 1.5;
	sons = MidEQ.ar(sons, 250, 1,   -12); // notch out a buzz on the cone
	sons = MidEQ.ar(sons, 120, 1,   -6); // notch out a buzz on the cone
	sons = sons.stutter(3) * 0.05;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play
)
x.free;


(
x = { // unbal clustpot hi
	var clusts, sons;
	clusts = 4.collect{
		4.collect{
			var freq = TIRand.kr(75, 95, Dust.kr(0.03)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
	sons = MidEQ.ar(sons, 1250, 1,   -6, mul: 1.4); // notch out a slightly piercing bit
	sons = sons.stutter(3) * 0.0005;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play
)
x.free;



// now need a clust that's more amorphous, clouds fading in/out


// unbal singrain_mover
(
x = {
	var sons, freqs = ([55, 56, 57] ++ ((48,51..52)+12).dup(7).flatten).scramble.midicps;
	var range = 6;
	var bigpos = LFPar.kr(0.05, pi.rand).range(freqs.size-1-range);
	sons = 3.collect{
		var pos = WhiteNoise.kr.range(0, range) + bigpos;
		GrainSin.ar(12, Dust.ar(30), 1.95,
		Index.kr(freqs.as(LocalBuf), pos),
		//Select.kr(LFPulse.kr(10) * 3, LFPar.kr(0.02, [0, 0.5, 1, 1.5]).exprange(880, 440)),
		LFNoise0.kr(10).range(0,2)) * 0.2;
	}.mean;
	sons = (sons * 0.33) +  (LPF.ar(sons, 500) * 0.66);
	sons = MidEQ.ar(sons, 250, 1,   -6); // notch out a buzz on the cone
	sons = MidEQ.ar(sons, 120, 1,   -6); // notch out a buzz on the cone
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;



(
x = {
	// unbal diffle

	// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, and they settle back slowly
	var sons;
	sons = 12.collect{|val|
		var son;
		var addmidi = 7; //MouseX.kr(-20, 20).round.poll(1);
		son = (([58, 65] + addmidi).midicps.collect{|freq, inwhich|
			var trig = Dust2.kr(1);
			var lev  = Latch.kr(trig, trig.abs).abs.neg;
			SinOsc.ar(freq * LFNoise1.kr(0.1).exprange(0.975, 1.025) + EnvGen.ar(Env.perc(0.1, 1.9), trig.abs, 20 * lev))
		} * [1.5, 0.07]).sum * 0.1;
		son = MidEQ.ar(son, 160, 0.5, -6); // notch out a buzz on the cone
		son = MidEQ.ar(son, 500, 1,   -6); // notch out a buzz on the cone
	};
	sons = sons.collect{|son|
		var nu = FreeVerb.ar(son * HPF.ar(WhiteNoise.ar, 10000), 1) * 0.1;
		XFade2.ar(son, nu, LFSaw.kr(-0.1, Rand(pi)));
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;

