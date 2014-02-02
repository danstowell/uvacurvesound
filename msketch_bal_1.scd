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
x = {
	// bal purity1
	var sons;
	sons = 12.collect{|val|
		var son;
		son = SinOsc.ar(Array.series(4, 1, 1) * 60.midicps * LFDNoise0.ar(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.35)).sum * 0.1;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;

(
x = {
	// bal purity1down12
	var sons;
	sons = 12.collect{|val|
		var son;
		son = SinOsc.ar(Array.series(4, 1, 1) * (60-12).midicps * LFDNoise0.ar(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(4, 0.5, 0.35)).sum * 0.1;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;

(
x = {
	// bal purity2
	var sons;
	sons = 12.collect{|val|
		var son;
		son = ([1,16].collect{|val| SinOsc.ar(val * Array.series(8, 1, 1) * 51.midicps * LFDNoise0.kr(20).exprange(0.99, 1.01), phase: Rand(0,2pi), mul: Array.geom(8, 0.5, 0.125)).sum * 0.1;
		} * [1, 0.002]).sum * 4.5;
		son = [son, BRF.ar(son, 160, 0.5, mul: 1)].mean; // notch out a buzz on the cone
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;


y = {|sons| BRF.ar(sons, 160, 1, mul: 1.5)}.scopeResponse
y.free

(
x = {
	// bal riffle

	// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, but not far and they settle back quickly
	var sons;
	sons = 12.collect{|val|
		var son;
		var addmidi = -7;//MouseX.kr(0, 40).round.poll(1);
		son = (([58, 65, 70] + addmidi).midicps.collect{|freq, inwhich|
			var trig = Dust2.kr(1);
			var lev  = Latch.kr(trig, trig.abs);
			SinOsc.ar(freq + EnvGen.ar(Env.perc(0.01, 0.1), trig.abs, 15 * lev))
		} * [1.5, 0.7, 0.25]).sum * 0.3;
		son = BRF.ar(son, 160, 0.125); // notch out a buzz on the cone
		son = HPF.ar(son, 300);
	};
	sons = sons.collect{|son|
		var nu = FreeVerb.ar(son * HPF.ar(WhiteNoise.ar, 10000), 1) * 0.1;
		XFade2.ar(son, nu, LFSaw.kr(-0.05, Rand(pi)));
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;


(
x = {
	// bal riffle note2

	// 3 sines per speaker, all are harmonically related, and all have these occasional impulses pushing them a tiny bit away from their perfect freq, but not far and they settle back quickly
	var sons;
	sons = 12.collect{|val|
		var son;
		var addmidi = -4;//MouseX.kr(0, 40).round.poll(1);
		son = (([58, 65, 70] + addmidi).midicps.collect{|freq, inwhich|
			var trig = Dust2.kr(1);
			var lev  = Latch.kr(trig, trig.abs);
			SinOsc.ar(freq + EnvGen.ar(Env.perc(0.01, 0.1), trig.abs, 15 * lev))
		} * [1.5, 0.7, 0.25]).sum * 0.3;
		son = BRF.ar(son, 160, 0.125); // notch out a buzz on the cone
		son = HPF.ar(son, 300);
	};
	sons = sons.collect{|son|
		var nu = FreeVerb.ar(son * HPF.ar(WhiteNoise.ar, 10000), 1) * 0.1;
		XFade2.ar(son, nu, LFSaw.kr(-0.05, Rand(pi)));
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;


(
x = {
	// bal roundfeather
	var sons;
	sons = 12.collect{|val|
		var son, freq, mod;
		mod = LFSaw.kr(ExpRand(0.05, 0.2), Rand(pi)).range(0,1);
		freq = (63-5-7).midicps;
		son = SinOsc.ar(freq * SinOsc.ar(mod.linexp(0, 1, 0.1, 1), mul: mod.squared).linexp(-1, 1, 0.99, 1.01)).tanh * 0.3;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;

