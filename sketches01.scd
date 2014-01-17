s.boot

s.options.numOutputBusChannels_(16)

s.quit

s.meter

FreqScope.new

TestSound.bong(4, 0.1)



// 3.4 seconds is the period of the pendulum

	// a moment where it could grow, grow into warm bath fm

// warm sines, with non-zappy non-scifi tracers (500-0.15 quick)



n = NodeProxy.audio(s, 4)

n.fadeTime_(3)
(
n.play;
n.source = {
	var freqs, son, harmstack, amps, harmamps, basefreqs, freqsel, fm, fmdepth;
	basefreqs = [120, 240, 480];
	harmstack = [1, 1.5, 2];
	harmstack = [1, 1.5, 2];
	harmamps = [1.5, 0.5, 0.3];
	//freqs = Array.series(4, 200, 0.1);
	//freqs = Array.geom(4, 200, 1.01);
	//freqs = Array.geom(4, 200, 2);
	freqs = basefreqs.collect{|freq| Array.series(4, freq, 0)};
	//freqs = Array.geom(4, 120, 2);
	//freqs = Array.series(4, 200, 0);

	fmdepth = MouseX.kr(0.000001, 0.5);
	fm = LFNoise0.ar(400).exprange(1 - fmdepth, 1 + fmdepth);
	// a moment where it could grow, grow into warm bath fm

	son = harmstack.mean{|val, index| SinOsc.ar(freqs * val * (fm * index), 0.5, 0.05 * harmamps[index])};
//	son = harmstack.mean{|val, index| PinkNoise.ar(0.15 * harmamps[index])};
//	son = HPF.ar(son, 10000) * 2;

	freqsel = basefreqs.collect{|val, index| SinOsc.kr(1/60, index * -2pi / basefreqs.size).linexp(-1, 1, 1e-3, 1).pow(0.5)   };
	//freqsel.poll;
	son.postln;
	son = (son * freqsel).sum;
	son.postln;

	amps = 4.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.5)   };
	amps = 4.collect{|val| SinOsc.ar(0.125, (4-val) * -2pi / 4).linexp(-1, 1, 1e-6, 1).pow(0.25)   }; // pow 0.25 makes move smoothly

	son = son * amps;

	son = son * 0.5
}
)
