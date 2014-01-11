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
x={
	// Elastic boinger - NB CombC and CombN give very different results - CombN tinnier
	var sons, son;
	sons = 12.collect{|chan|
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.01));
			son = CombN.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.01, 0.1), 40);
		}.mean;
	};
	sons = sons * XLine.ar(0.001, 1, 0.2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)

(
x={
	// Elastic harder - NB CombC and CombN give very different results - CombN tinnier
	var sons, son;
	sons = 12.collect{|chan|
		[48, 55, 60].collect{|val|
			var wib = LFDNoise1.kr(0.2).range(0, 0.05);
			son = BPF.ar(GrayNoise.ar, val.midicps * 2) * EnvGen.ar(Env.perc(0.03, 0.05), Dust.kr(0.01));
			son = CombC.ar(son, 0.2, (LFDNoise1.kr(0.1) + LFPar.kr(10, 0, wib)).linexp(-1, 1, 0.01, 0.1), 20);
		}.mean;
	};
	sons = sons * XLine.ar(0.001, 1, 0.2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)

(
x={
	// Elastic boinger 2d
	var sons, son;
	sons = 12.collect{|chan|
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.01));
			son = CombN.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.01, 0.1), 40)
			    + CombC.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.01, 0.1), 40);
		}.mean;
	};
	sons = sons * XLine.ar(0.001, 1, 0.2);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)

(
x={
	// Elastic hiss
	var sons, son;
	sons = 12.collect{
		[48, 55, 60].collect{|val|
			son = BPF.ar(WhiteNoise.ar(0.1), LFDNoise1.kr(1).exprange(500, 10000), 0.2);
			son = CombC.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.005, 0.2), 3);
		}.mean;
	};
	sons = sons * XLine.ar(0.001, 1, 0.2);
	Out.ar(~twelve, sons);
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Splay.ar(sons);
	//sons[..1]
}.play
)


(
// stickslip01
var stickslip = { |force|
	var inMotion, slipEvents, forceBuildup, evtAmp, evtDecayTime, evts;
	force = force.lag(0.1); // smoothing to get rid of volatile control changes
	inMotion = force > 0.1; // static friction: nothing at all below a certain force
	slipEvents = inMotion * Impulse.ar(force.linlin(0.1, 1, 1, 1/0.003) * LFDNoise1.ar(50).squared.linexp(-1,1, 0.5, 2));
	forceBuildup = Phasor.ar(slipEvents, 10 * SampleDur.ir, 0, inf).min(1);
	evtAmp = Latch.ar(Delay1.ar(forceBuildup.sqrt), slipEvents);
	evtDecayTime = evtAmp.sqrt;
	evts = EnvGen.ar(Env.perc(0.001, 1), slipEvents, evtAmp, 0, evtDecayTime * 0.01 * TExpRand.kr(0.5, 2, slipEvents)) * LPF.ar(BrownNoise.ar, 80);
};
var squarepanel = { |inputs|
	var times, filt;
	// times in milliseconds, converted to seconds:
	times = [4.52, 5.06, 6.27, 8, 5.48, 7.14, 10.12, 16] * 0.001;
	filt = inputs.asArray.collect{|input| DelayC.ar(input, times, times).mean };
	filt = HPF.ar(filt, 125);
	filt * 4
};
var woodfilter = { |inputs|
	var freqs, rqs, output;
	freqs = [62.5, 125, 250, 395, 560, 790];
	rqs   = 1 / [1, 1, 2, 2, 3, 3];
	output = inputs.asArray.collect{|input| BPF.ar(input, freqs, rqs).sum + (input*0.2)};

};

x={
	var sons = squarepanel.value(woodfilter.value(3.collect{
		var chanphase = pi.rand;
		2.collect{|phase|
			var force; //= MouseX.kr; //LFPar.kr(ExpRand(0.01, 0.04), pi.rand).range(0.0, 0.9);
			force = LFSaw.kr(ExpRand(-0.03, -0.02), phase + chanphase).linexp(-1, 1, 0.1, 1.2) + Line.kr(2, 0, 3);
			stickslip.value(force) * XLine.ar(0.001, 1, 3)
			// * BPF.ar(WhiteNoise.ar, 200, mul: 3)
			* (1-force)
		}.sum
	}));
	//sons = [sons, sons[1..] ++ sons[0]].mean;
	sons = sons.collect{|son, which| PanAz.ar(12, son, which * (2/3) + LFSaw.kr(0.1), width: 4)}.sum * 2;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play

)

// Formlet meh


// Maybe GrainFM can be used to make a granular twisting elastic warp sound - or maybe it's too discordant and GrainSin wins
// try GrainSin starting from 440
(
{ // This sounds like the wind!
	GrainSin.ar(6, Dust.ar(100), 0.01, LFNoise0.kr(10), LFNoise0.kr(10).range(0,2)) * 0.5
}.play
)


(
{
	var source, local;
	source = Decay.ar(Impulse.ar(0.3), 0.1) * WhiteNoise.ar(0.2);
	source = Dust2.ar(50);
	local = LocalIn.ar(1) + source; // read feedback, add to source
	local = LPF.ar(DelayN.ar(local.round(0.01) * 1.2, 0.2, 0.2), 3000); // delay sound
	local = [local, HPF.ar(LPF.ar(local, 100), 100)].sum.tanh * 0.8;
	LocalOut.ar(local * 0.8);
	Out.ar(0, local);
}.play;
)






(
{
	var source, local;
	source = Decay.ar(Impulse.ar(0.3), 0.1) * WhiteNoise.ar(0.2);
	//source = Dust2.ar(50);
	local = LocalIn.ar(1) + source; // read feedback, add to source
	local = DelayN.ar(local.round(0.01) * 1.2, 0.2, 0.2);
	local = HPF.ar(PitchShift.ar(local, 0.2, 0.9) * 1.9, 100).softclip;
	local = local * (local.abs > 0.01);
	LocalOut.ar(local * 0.8);
	Out.ar(0, local);
}.play;
)


