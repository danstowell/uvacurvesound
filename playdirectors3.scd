// This is an example of some sequencing. (It assumes that other files have already been loaded.)
(
//s.dumpOSC(1);
//s.dumpOSC(0);

~begin_oneper = { // on 0
	"~begin_oneper".postln;
	~jumpcutamps.value([0,0]);
	0.1.wait;
	~preparesilent.value(0, "one_harmonic_per");
	0.3.wait;
	~crossfadeparams.value(0, 2, amp:[0.0, 0.7]);
	2.wait;
};
/*
~setparams.value(0, amp:0.7);
*/

~jumpcut = { |name, on, width=1, rapidity=5|
	var amps;
	"~jumpcut(%, %)".format(name, on).postln;
	~preparesilent.value(on, name, width: width, rapidity: rapidity);
	0.3.wait;
	amps = {0.0}.dup(2);
	amps[on] = 0.7;
	~jumpcutamps.value(amps);
	0.3.wait;
};

~oneper_orch_modulations = { // on 1
	"~oneper_orch_modulations; a".postln;
	~crossfadeparams.value(1, 20, amp:0.7, width:[1, 0.1], rapidity:5);
	20.wait;
	"~oneper_orch_modulations; b".postln;
	~crossfadeparams.value(1, 4, amp:0.7, width:0.1, rapidity:[5, 30]);
	5.wait;
	"~oneper_orch_modulations; c".postln;
	~crossfadeparams.value(1, 2, amp:0.7, width:[0.1, 0.0], rapidity:[30, 50]);
	~crossfadeparams.(0, 5, amp: [0.1, 0.0]); // de-emphasise bed entirely
	20.wait;
	"~oneper_orch_modulations; d".postln;
	~crossfadeparams.value(1, 5, amp:0.7, width:[0.0, 1.0], rapidity:[50, 100]);
	20.wait;
};

~bringin = { |name, on, dur=20, width=1, rapidity=5, amp=0.7, circlesize=1, freqscale=1|   // NB assumes always bringing in from silence
	"~bringin(%, %)".format(name, on).postln;
	~preparesilent.value(on, name, width: width, rapidity: rapidity, circlesize: circlesize, freqscale: freqscale);
	0.5.wait;
	~crossfadeparams.value(on, dur, amp:[0, amp], width: width, rapidity: rapidity, circlesize: circlesize, freqscale: freqscale);
	dur.wait;
};

~jumpadd_fragpwm = { // on 1
	"~jumpadd_fragpwm".postln;
	~preparesilent.value(1, "frag_pwm", width:0.0, rapidity: 2);
	0.3.wait;
	~jumpcutamps.value([0.7, 0.7]);
	5.wait;
	~crossfadeparams.value(1, 5, width:[0.0, 1.0], rapidity:[2,5]);
};

~brief_superhigh = { // on 0
	"~brief_superhigh".postln;
	~preparesilent.value(0, "superhigh", width:1, rapidity: 5);
	0.3.wait;
	~jumpcutamps.value([0.6, 0.7]);
	0.3.wait;
	5.wait;
	~jumpcutamps.value([0, 0.7]);
	0.3.wait;
};

~brief_hinoise = { |on=1|
	"~brief_hinoise".postln;
	~setparams.(on, amp:0);
	0.2.wait;
	~preparesilent.value(on, "hinoise", width:1, rapidity: 5);
	0.3.wait;
	~crossfadeparams.value(on, 2, amp:[0.0, 0.7]);
	2.wait;
	5.wait;
	~crossfadeparams.value(on, 2, amp:[0.7, 0.0]);
	2.wait;
};

~brief_fragpwm = { |on=1|
	"~brief_fragpwm".postln;
	~setparams.(on, amp:0);
	0.2.wait;
	~preparesilent.value(on, "frag_pwm", width:0, rapidity: -15);
	0.3.wait;
	~crossfadeparams.value(on, 2, amp:[0.0, 0.7]);
	2.wait;
	5.wait;
	~crossfadeparams.value(on, 2, amp:[0.7, 0.0]);
	2.wait;
};

~alternate_fragpwm = {
	"~alternate_fragpwm".postln;
	2.do{
		~setparams.(1, width:0.1, rapidity:30);
		10.wait;
		~setparams.(1, width:1, rapidity:30);
		1.5.wait;
	};
	~setparams.(1, width:0.1, rapidity:30);
	2.wait;
};


// let's go
~playertask = Task({
	~jumpcut.("tracerbeep", 1);
	loop{
		/////////////////////////////////////////////////// // sparse
		"position 0".postln;
		30.wait;
		~bringin.("tracer", 0, 0.5);
		20.wait;
		~jumpcutamps.value([0.7, 0.0]);
		15.wait;
		~bringin.("oneper_to_orch_thrum_varsaw", 1, 20, amp:0.5, width:0.1, freqscale:0.midiratio, circlesize:1, rapidity:-1);
		20.wait;
		/////////////////////////////////////////////////// // full
		"position 1".postln;
		~bringin.("low_orch_thrum_varsaw", 0, 10, amp:0.7);
		~crossfadeparams.(1, 0.5, amp: [0.7, 0]); // the high orch goes, suddenly
		20.wait;
		~brief_hinoise.(1);
		20.wait;
		~bringin.("oneper_to_orch_thrum_varsaw", 1, 10, amp:0.5, width:0.1, freqscale:1.midiratio, circlesize:2, rapidity:-5);
		// this position is quite moving - OR maybe better with freqscale 0.midiratio
		/*
		~sceneplayers[1].set(\amp, 0.5, \width, 0.1, \freqscale, 0.midiratio, \circlesize, 2);
		*/
		50.wait;
		~crossfadeparams.(1, 5, amp: [0.5, 0]);
		5.wait;
		~bringin.("frag_pwm", 1, 0.5, width:0.0, rapidity: 2);
		10.wait;
		/////////////////////////////////////////////////// // sparse
		"position 2".postln;
		// in two minds here: is pulling the orch away fine or is it "why did the orch just wander off?"
		~jumpcutamps.value([0.0, 0.7]);
		~alternate_fragpwm.();
		~bringin.("tracerbeep", 0, 0.5);
		10.wait;
		~crossfadeparams.(1, 10, amp: [0.7, 0], width: [0.1, 0], rapidity: 30); // frag goes
		20.wait;
		~bringin.("passingzero_frompend_conc", 0, 3);
		5.wait;
		~jumpcutamps.value([0.7, 0.0]);
		20.wait;
		~brief_fragpwm.(1);
		5.wait;
		/////////////////////////////////////////////////// // full
		"position 3".postln;
		~bringin.("tonestack01tri02", 1, 30, amp:0.3); // this fadein from bare to the lush stack, then hinoises, is gorgeous
		1.0.wait;
		~jumpcutamps.([0, 0.3]);
		20.wait;
		3.do{
			~brief_hinoise.(0);
			10.wait;
		};
		~brief_fragpwm.(0); // the frag singing in perfect harmony with the lush stack adds extra to the gorge
		10.wait;
		~brief_fragpwm.(0);
		20.wait;
		/////////////////////////////////////////////////// // sparse(ish)
		"position 4".postln; // Great transition here, with fragpwm continuity but a jump to bare
		~jumpcut.("tracerbeep", 0);
		5.wait;
		~jumpadd_fragpwm.();
		5.wait;
		~alternate_fragpwm.();
		~crossfadeparams.value(1, 5, width:[0.1, 0.0], rapidity:[30,0.1]);
		15.wait;
		~jumpcutamps.([0.7, 0.0]);
		20.wait;
		~bringin.("tonestack01tri02", 1, 10, amp:0.3, width: 0.2, rapidity: -1, circlesize: 2);
		4.wait;
		~crossfadeparams.value(1, 20, amp:0.3, width: [0.2, 1], rapidity: -1, circlesize: 2);
		20.wait;
		~jumpcutamps.([0.0, 0.3]);
		5.wait;
		~brief_hinoise.(0);
		10.wait;
		~brief_fragpwm.(0);
		20.wait;
		/////////////////////////////////////////////////// // full
		"position 5".postln; // this fizzfade from tonestack into orch is great
		~bringin.("oneper_to_orch_thrum_varsaw_fizzin", 0, 0.5, amp:0.4); // bring in to scene 1 with a 0.5 fade in and amplitude of 0.4
		20.wait;
		~crossfadeparams.(1, 10.0, amp: [0.3, 0]); // remove tonestack slowly
		20.wait;
		~crossfadeparams.(0, 1.0, width: [1, 0], rapidity: [5, 0]); // thins and hits stasis
		10.wait;
		~crossfadeparams.(0, 0.5, width: [0], rapidity: [0, -1], amp: [0.7, 0.4]); // then goes
		1.6.wait;
		~bringin.("low_orch_thrum_varsaw", 0, 0.5);
		10.wait;
		~jumpcut.("tracerbeep", 1);
		};
}).play(TempoClock);
/*
~playertask.stop;
*/
) // end
