s.boot;


(
{ // unbal clust pot
	var clusts, sons;
	clusts = 2.collect{
		4.collect{
			var freq = TIRand.kr(45, 65, Dust.kr(0.1)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
	sons = sons.stutter(3) * 0.002;
}.play
)


(
{ // unbal clust pot hi
	var clusts, sons;
	clusts = 2.collect{
		4.collect{
			var freq = TIRand.kr(75, 95, Dust.kr(0.1)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};
	sons = sons.stutter(3) * 0.00005;
}.play
)



// now need a clust that's more amorphous, clouds fading in/out



(
{ // unbal clust pot grain - MEH
	var clusts, sons, buf;
	clusts = 2.collect{
		4.collect{
			var freq = TIRand.kr(45, 65, Dust.kr(0.3)).midicps;
			SinOsc.ar(freq * PinkNoise.kr(0.1).linexp(-0.5, 0.5, 0.9, 1.1))
		}.mean
	};
	sons = clusts.collect{|clust| DynKlank.ar(`[10.collect{exprand(1000, 10000)}, nil, 10.collect{exprand(0.1, 1)}], clust)};

	//buf = LocalBuf(s.sampleRate * 10);
	//buf.clear;
	//RecordBuf.ar(sons.mean, buf);
	sons = GrainIn.ar(12, Dust.ar(400), 0.03, sons.mean) * 0.03;
	//sons = GrainBuf.ar(12, Dust.ar(400), 0.02, buf) * 0.1;

		sons = sons.clip2(1).stutter(3) * 0.03;
}.play
)


///////////////TODO
(
{
	var sons, freqs;
	freqs = 10.collect{TIRand.kr(45, 65, Dust.kr(0.3)).midicps};

	sons = GrainSin.ar(12, Dust.ar(100), 0.01, Select.kr(LFSaw.kr.range(0, 10), freqs), LFNoise0.kr(100).range(0, 2));
	sons = sons.clip2(1) * 0.01;
}.play
)

