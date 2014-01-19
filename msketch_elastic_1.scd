s.boot;                               // IF IN UVA REMEMBER - THE VOLUME MUST GO LOW
~twelve = Bus.audio(s, 12);
~ssh = {ReplaceOut.ar(0, In.ar(~twelve, 12) * 0.1)}.play(s, addAction:\addToTail); //~ssh.free; x.free;
~twelve.scope;

~dobuf = Buffer.alloc(s, 65536, 2);
~dobuf = Buffer.alloc(s, 65536, 1);
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
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;

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
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;

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
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;

(
x={
	// Elastic boinger 2d 2
	var sons, son, noise=WhiteNoise.ar.range(0.9, 1);
	sons = 12.collect{|chan|
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * noise * EnvGen.ar(Env.perc(0.01, 0.02), Dust.kr(0.01));
			son = BPF.ar(son, 500);
			son = 2.collect{
				var wib = LFDNoise1.kr(0.08).exprange(0.03, 0.2);
				CombN.ar(son, 0.2, wib, 60) * ((HPZ1.kr(wib) > 0) + 0.3).lag(0.5)
			}.sum;
		}.mean;
	};
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;

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
x.free;


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
	sons = sons.collect{|son, which| PanAz.ar(12, son, which * (2/3) + LFSaw.kr(0.1), width: 4)}.sum * 1.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play

)
x.free;

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



(
// tearing paper 1 - currently sounds quite a lot like velcro - I think it lacks some of the stiff resonances of paper
x = {
	var stage, stagelag, evt, res, son;
	stage = LFSaw.kr(0.1).max(0);
	stagelag = stage.lag(0.2, 0.2);
	evt = Dust2.ar(stagelag.pow(3) * 400);
	res = DynKlank.ar(`[10.collect{exprand(100, 400)}.postln, nil, 10.collect{0.1}], evt, stagelag.linexp(0, 1, 1, 10));
	son = (evt) + (res * 0.6 * BPF.ar(WhiteNoise.ar, stagelag.linexp(0, 1, 10000, 2000), 2));
	son = LPF.ar(son, stagelag.linexp(0, 1, 500, 10000));
	son = CombC.ar(son, 0.15, 0.15, 0.4);
	Out.ar(~twelve, son.dup(12) * 0.4);
	son.dup * 0.5 * 0.1;

}.play
)
x.free;


(
// rip 1 plus 1
x = {
	var stage, stagelag, evt, res, son;
	stage = LFSaw.kr(0.03, 0.7).range(-5, 1).max(0);
	stagelag = stage.lag(0.2, 0.2);
	evt = Dust2.ar(stagelag.pow(3) * 400);
	res = DynKlank.ar(`[10.collect{exprand(100, 400)}.postln, nil, 10.collect{0.1}], evt, stagelag.linexp(0, 1, 1, 10));
	son = (evt) + (res * 0.6 * BPF.ar(WhiteNoise.ar, stagelag.linexp(0, 1, 10000, 2000), 2));
	son = LPF.ar(son, stagelag.linexp(0, 1, 500, 10000));
	son = son + CombC.ar(LPF.ar(son, 5000) * BrownNoise.ar * 0.5 * stage.squared, 0.09, LFPar.ar(4).range(0.08, 0.09), stagelag.linexp(0, 1, 75, 0.1));

	if(~dobuf.notNil){DiskOut.ar(~dobuf, son.dup)}; // TODO 12chan
	Out.ar(~twelve, son.dup(12) * 0.4);
	son.dup;

}.play
)
x.free;

(
// stretchballoon01
x = {
	var son, stim;
	stim = EnvGen.ar(Env.perc(0.001, 0.001), Dust.ar(XLine.kr(100, 4, 2))) * XLine.ar(0.01, 1, 2);
	stim = stim * EnvGen.ar(Env.linen(0, 2.5, 0), 1);
	son = Klank.ar(`[20.collect{exprand(100, 500)}, nil, 20.collect{0.1}], stim).clip2(1) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)}; // TODO 12chan
	Out.ar(~twelve, son.dup(12) * 0.4);
	son.dup;

}.play
)
x.free;

(
// stretchregular02
x = {
	var son, stim;
	stim = EnvGen.ar(Env.perc(0.001, 0.001), Impulse.ar(XLine.kr(50, 3, 3))) * XLine.ar(0.01, 1, 3);
	stim = stim * EnvGen.ar(Env.linen(0, 3, 0), 1);
	son = Klank.ar(`[20.collect{exprand(100, 500)}, nil, 20.collect{0.1}], stim).clip2(1) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)}; // TODO 12chan
	Out.ar(~twelve, son.dup(12) * 0.4);
	son.dup;

}.play
)
x.free;

(
// stretchstepped
x = {
	var son, stim;
	stim = EnvGen.ar(Env.perc(0.001, 0.001), Impulse.ar(XLine.kr(100, 3, 3).round(10))) * XLine.ar(0.01, 1, 3);
	stim = stim * EnvGen.ar(Env.linen(0, 3, 0), 1);
	son = Klank.ar(`[20.collect{exprand(100, 500)}, nil, 20.collect{0.1}], stim).clip2(1) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, son)}; // TODO 12chan
	Out.ar(~twelve, son.dup(12) * 0.4);
	son.dup;

}.play
)
x.free;



(
x = {
	// elastic feather - NO, MEH
	var sons;
	sons = 12.collect{|val|
		var son, freq, mod;
		mod = LFSaw.kr(ExpRand(0.03, 0.1), Rand(pi)).range(0,1);
		freq = (63-5).midicps;
		son = SinOsc.ar(freq * SinOsc.ar(mod.linexp(0, 1, 0.1, 20), mul: mod.squared).linexp(-1, 1, 0.666, 1.5)).softclip * 0.3;
	};
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
}.play;
)
x.free;


(
x={
	// elastic spiraldown - NOT RIGHT, not yet at least
	var sons, son, dlyrate=0.1;
	var fb = LocalIn.ar(12);
	sons = 12.collect{|chan|
		var son, sonin, echo1, echo2, xfade, dly1, dly2;
		son = SinOsc.ar(440 * 8, mul: 0.1) * EnvGen.ar(Env.perc(0.01, 0.01), Impulse.kr(0) + Dust.kr(0.05));
		sonin = son + (fb[chan] * 0.08);
		dly1 = LFSaw.kr(dlyrate, 0);
		dly2 = LFSaw.kr(dlyrate, 1);
		xfade = LFPar.kr(dlyrate);
		echo1 = DelayN.ar(sonin, 0.5, dly1.linexp(-1,  1, 0.1, 0.5) * LFNoise2.kr(10).range(0.99, 1), 40);
		echo2 = DelayN.ar(sonin, 0.5, dly2.linexp( 1, -1, 0.1, 0.5) * LFNoise1.kr(10).range(0.99, 1), 40);
		XFade2.ar(echo1, echo2, 0-xfade);
	};
	sons = LPF.ar(LeakDC.ar(sons), 5000);
	//LocalOut.ar(Limiter.ar(HPF.ar(LPF.ar(sons.round(0.2), 10000), 100)));
	LocalOut.ar(Limiter.ar(sons));
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.1;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;




(
x={
	// Elastic laser meh
	var sons, son, noise=WhiteNoise.ar.range(0.9, 1);
	sons = 12.collect{|chan|
		var trig = Trig1.ar(Dust.ar(0.1), 0);
		var dcy  = Decay2.ar(trig, 0.2, 5);
		Pluck.ar(HPF.ar(Impulse.ar(20000), 1000), trig, 0.2, dcy.linlin(0,1, 0.2, 0.002), 10)
	};
	sons = sons * XLine.ar(0.001, 1, 0.2) * 0.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play
)
x.free;



(
// stickslip02 - MEH so far
var stickslip = { |force, grainstretch=1|
	var inMotion, slipEvents, forceBuildup, evtAmp, evtDecayTime, evts;
	force = force.lag(0.1); // smoothing to get rid of volatile control changes
	inMotion = force > 0.1; // static friction: nothing at all below a certain force
	slipEvents = inMotion * Impulse.ar(force.linlin(0.1, 1, 1, 1/0.003) * LFDNoise1.ar(50).squared.linexp(-1,1, 0.5, 2));
	forceBuildup = Phasor.ar(slipEvents, 10 * SampleDur.ir, 0, inf).min(1);
	evtAmp = Latch.ar(Delay1.ar(forceBuildup.sqrt), slipEvents);
	evtDecayTime = evtAmp.sqrt;
	evts = EnvGen.ar(Env.perc(0.001, 1), slipEvents, evtAmp, 0, grainstretch * evtDecayTime * 0.01 * TExpRand.kr(0.5, 2, slipEvents)) * LPF.ar(BrownNoise.ar, 80);
};
var squarepanel = { |inputs|
	var times, filt;
	// times in milliseconds, converted to seconds:
	times = [4.52, 5.06, 6.27, 8, 5.48, 7.14, 10.12, 16] * 0.0006;
	filt = inputs.asArray.collect{|input| DelayC.ar(input, times, times).mean };
	filt = HPF.ar(filt, 125);
	filt * 4
};
var woodfilter = { |inputs|
	var freqs, rqs, output;
	freqs = [62.5, 125, 250, 395, 560, 790] * 1.5;
	rqs   = 1 / [1, 1, 2, 2, 3, 3];
	output = inputs.asArray.collect{|input| BPF.ar(input, freqs, rqs).sum + (input*0.2)};

};

x={
	var sons = squarepanel.value(woodfilter.value(
		EnvGen.ar(Env.perc(0.002, 0.002), Impulse.ar(LFPar.kr(0.1).exprange(10, 50))) * XLine.ar(0.01, 1, 3) * 0.2;
	));
	//sons = [sons, sons[1..] ++ sons[0]].mean;
	sons = sons.collect{|son, which| PanAz.ar(12, son, which * (2/3) + LFSaw.kr(0.1), width: 4)}.sum * 1.5;
	if(~dobuf.notNil){DiskOut.ar(~dobuf, Splay.ar(sons))};
	Out.ar(~twelve, sons);
	Splay.ar(sons);
	//sons[..1]
}.play

)
x.free;

