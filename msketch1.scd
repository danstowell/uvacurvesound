s.boot;

x.free;

(
x={
	// Elastic boinger - NB CombC and CombN give very different results - CombN tinnier
	var sons, son;
	sons = 12.collect{|chan|
		[48, 55, 60].collect{|val|
			son = SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.1));
			son = CombN.ar(son, 0.2, LFDNoise1.kr(0.03).exprange(0.01, 0.1), 20);
		}.mean;
	};
	Splay.ar(sons);
	sons * 0.02;
}.play
)

(
{
	// Elastic harder - NB CombC and CombN give very different results - CombN tinnier
	var sons, son;
	sons = 12.collect{|chan|
		[48, 55, 60].collect{|val|
			var wib = LFDNoise1.kr(0.2).range(0, 0.1);
			son = BPF.ar(GrayNoise.ar, val.midicps * 2) * EnvGen.ar(Env.perc(0.02, 0.05), Dust.kr(0.1));
			son = CombC.ar(son, 0.2, (LFDNoise1.kr(0.1) + LFPar.kr(10, 0, wib)).linexp(-1, 1, 0.01, 0.1), 20);
		}.mean;
	};
	Splay.ar(sons);
	sons * 0.05;
}.play
)

(
{
	// Elastic hiss
	var sons, son;
	sons = 12.collect{
		[48, 55, 60].collect{|val|
			son = BPF.ar(WhiteNoise.ar(0.1), LFDNoise1.kr(1).exprange(500, 10000), 0.2);
			son = CombC.ar(son, 0.2, LFDNoise1.kr(0.3).exprange(0.005, 0.2), 3);
		}.mean;
	};
	Splay.ar(sons);
	sons.clip2(1) * 0.05;
}.play
)


// do elastic but with a HPFing delay - NOT WORKING
(
{
	var sons;
	sons = LocalIn.ar(3);
	sons = [48, 55, 60].collect{|val, which|
		var orig, son;
		son = sons[which] + SinOsc.ar(val.midicps * 2) * EnvGen.ar(Env.perc(0.001, 0.05), Dust.kr(1));
		son
	};
	LocalOut.ar(sons.collect{|son| DelayC.ar(son * 0.9999, 0.2, LFDNoise1.kr(0.3).exprange(0.01, 0.1) )});
	Splay.ar(sons);
}.play
)


(
~stickslip = { |force|
	var inMotion, slipEvents, forceBuildup, evtAmp, evtDecayTime, evts;
	force = force.lag(0.1); // smoothing to get rid of volatile control changes
	inMotion = force > 0.1; // static friction: nothing at all below a certain force
	slipEvents = inMotion * Impulse.ar(force.linlin(0.1, 1, 1, 1/0.003) * LFDNoise1.ar(50).squared.linexp(-1,1, 0.5, 2));
	forceBuildup = Phasor.ar(slipEvents, 10 * SampleDur.ir, 0, inf).min(1);
	evtAmp = Latch.ar(Delay1.ar(forceBuildup.sqrt), slipEvents);
	evtDecayTime = evtAmp.sqrt;
	evts = EnvGen.ar(Env.perc(0.001, 1), slipEvents, evtAmp, 0, evtDecayTime * 0.01 * TExpRand.kr(0.5, 2, slipEvents)) * LPF.ar(BrownNoise.ar, 80);
};
~squarepanel = { |inputs|
	var times, filt;
	// times in milliseconds, converted to seconds:
	times = [4.52, 5.06, 6.27, 8, 5.48, 7.14, 10.12, 16] * 0.001;
	filt = inputs.asArray.collect{|input| DelayC.ar(input, times, times).mean };
	filt = HPF.ar(filt, 125);
	filt * 4
};
~woodfilter = { |inputs|
	var freqs, rqs, output;
	freqs = [62.5, 125, 250, 395, 560, 790];
	rqs   = 1 / [1, 1, 2, 2, 3, 3];
	output = inputs.asArray.collect{|input| BPF.ar(input, freqs, rqs).sum + (input*0.2)};

};

{~squarepanel.value(~woodfilter.value(0.05 * 12.collect{~stickslip.value(LFPar.kr(ExpRand(0.01, 0.04), pi.rand).range(0.0, 0.2))}))}.play

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
	GrainSin.ar(6, Dust.ar(300), 0.01, Select.kr(LFPulse.kr(10) * 3, LFPar.kr(0.2, [0, 0.5, 1, 1.5]).exprange(880, 440)), LFNoise0.kr(10).range(0,2)) * 0.01
}.play
)

