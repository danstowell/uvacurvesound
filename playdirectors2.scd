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

~bringin = { |name, on, dur=20, width=1, rapidity=5, amp=0.7, circlesize=1|   // NB assumes always bringing in from silence
	"~bringin(%, %)".format(name, on).postln;
	~preparesilent.value(on, name, width: width, rapidity: rapidity, circlesize: circlesize);
	0.3.wait;
	~crossfadeparams.value(on, dur, amp:[0, amp], width: width, rapidity: rapidity, circlesize: circlesize);
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

~brief_hinoise = { // on 1
	"~brief_hinoise".postln;
	~setparams.(1, amp:0);
	0.2.wait;
	~preparesilent.value(1, "hinoise", width:1, rapidity: 5);
	0.3.wait;
	~crossfadeparams.value(1, 2, amp:[0.0, 0.7]);
	2.wait;
	5.wait;
	~crossfadeparams.value(1, 2, amp:[0.7, 0.0]);
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
	~bringin.("tracer", 0, 0.5);
	loop{
		30.wait;
		~setparams.value(0, amp:0.0);
		0.2.wait;
		~bringin.("tonestack01tri02", 0, 20, amp:0.4, rapidity:5, width:1); ////// TODO THIS WOULD LIKE TO COME IN LOGARITHMIC AMPLY
		20.wait;
		~brief_hinoise.();
		~crossfadeparams.(0, 2, amp: 0.4, width:[1, 0], rapidity:5); // full to narrow
		20.wait;
		~brief_hinoise.();
		~crossfadeparams.(0, 2, amp: 0.4, width:[0, 1], rapidity:5);
		// no wait - simult
		~preparesilent.value(1, "frag_pwm", width: 0.1, rapidity: 30);
		~crossfadeparams.(1, 0.3, amp: [0, 0.7], width: 0, rapidity: 0);
		3.wait;
		~alternate_fragpwm.();
		// this is a kind of jumpcut
		~pushascene.value("tracer", 1);
		0.4.wait;
		~setparams.value(0, amp:0.7);
		~bringin.("passingzero_frompend", 0, 10, amp:0.7);
		10.wait;
		~crossfadeparams.(0, 0.5, amp: [0.7, 0]);
		0.6.wait;
		~bringin.("tracerbeep", 0, 0.5, amp:0.7);
		10.wait;
		~crossfadeparams.(0, 0.5, amp: [0.7, 0]);
		0.6.wait;
		//~bringin.("oneper_to_orch_thrum", 0, 10, amp:0.7);
		~bringin.("low_orch_thrum_varsaw", 0, 10, amp:0.7);
		10.wait;
		~crossfadeparams.(1, 0.5, amp: [0.7, 0]); // finally tracer goes
		0.6.wait;
		~bringin.("oneper_to_orch_thrum_both", 1, 0.5, amp:0.7, rapidity: 10, circlesize: 5, width: 0.3); // sweeps thru occasionally
		40.wait;
		~crossfadeparams.(0, 1.0, width: [1,0]);
		1.1.wait;
		~crossfadeparams.(0, 1.0, amp: [0.7, 0]); // fade scene 0 from 0.7 to 0 in 1 second
		4.wait;
		~preparesilent.value(0, "tracerbeep"); // loading in tracerbeep into scene 0
		1.0.wait;
		~jumpcutamps.([0.7, 0]); // hard cut. set amp of scene 0 to 0.7 and 1 to 0
		3.wait;
		~preparesilent.value(1, "frag_pwm"); // load in frag_pwm to scene 1
		1.0.wait;
		~jumpcutamps.([0.7, 0.7]);
		3.wait;
		~jumpcutamps.([0.7, 0]);
		0.1.wait;
		~preparesilent.value(1, "tracer");
		1.0.wait;
		~jumpcutamps.([0.0, 0.7]);
		0.4.wait;
		~bringin.("tonestack01tri02", 0, 0.2);
		~jumpcutamps.([0.7, 0]);
		15.wait;
		~bringin.("oneper_to_orch_thrum_varsaw_fizzin", 1, 0.5, amp:0.4); // bring in to scene 1 with a 0.5 fade in and amplitude of 0.4
		30.wait;
		~crossfadeparams.(1, 1.0, width: [1, 0], rapidity: [5, 0]); // thins and hits stasis
		10.wait;
		~crossfadeparams.(1, 0.5, width: [0], rapidity: [0, 5], amp: [0.7, 0]); // then goes
		0.6.wait;
		~bringin.("low_orch_thrum_varsaw", 1, 0.5);
		10.wait;
		~crossfadeparams.(1, 1.0, width: [1, 0], rapidity: [5, 0]); // thins and hits stasis
		10.wait;
		~crossfadeparams.(1, 0.5, width: [0], rapidity: [0, 5], amp: [0.7, 0]); // then goes
		0.6.wait;
		// putting tracerbeep back in for looparound
		~bringin.("tracerbeep", 1, 0.2);
		};
}).play(TempoClock);
/*
~playertask.stop;
*/
) // end
