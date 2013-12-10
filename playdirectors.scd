// This is an example of some sequencing. (It assumes that other files have already been loaded.)
/*
// Directly sets the amps of all scenes (also ensures running/paused correctly). Use this for when you've silently prepared a scene and want to jump to it
~jumpcutamps = {|amps|
// Just pushes parameter settings to a single scene, whether it's playing or not
~setparams = {|index, amp=0.7, width=0.5, freqscale=1, circlesize=1, rapidity=5|
// Crossfades current parameters slowly to a new set
~crossfadeparams = {|index, xfadetime=4, amp=[0.7,], width=0.5, freqscale=1, circlesize=1, rapidity=5|
// Loads a new scene into a player. Intended for use with players that are already muted, hence amp=0.
~preparesilent = {|index, scenename, amp=0.0, width=0.5, freqscale=1, circlesize=1, rapidity=5|
*/
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
	~crossfadeparams.value(1, 5, amp:0.7, width:0.1, rapidity:[5, 30]);
	5.wait;
	"~oneper_orch_modulations; c".postln;
	~crossfadeparams.value(1, 10, amp:0.7, width:[0.1, 0.0], rapidity:[30, 50]);
	~crossfadeparams.(0, 5, amp: [0.1, 0.0]); // de-emphasise bed entirely
	20.wait;
	"~oneper_orch_modulations; d".postln;
	~crossfadeparams.value(1, 5, amp:0.7, width:[0.0, 1.0], rapidity:[50, 100]);
	20.wait;
};

~bringin = { |name, on, dur=20, width=1, rapidity=5, amp=0.7|   // NB assumes always bringing in from silence
	"~bringin(%, %)".format(name, on).postln;
	~preparesilent.value(on, name, width: width, rapidity: rapidity);
	0.3.wait;
	~crossfadeparams.value(on, dur, amp:[0, amp], width: width, rapidity: rapidity);
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

~alternate_fragpwm = {
	"~alternate_fragpwm".postln;
	3.do{
		~setparams.(1, width:0.1, rapidity:30);
		5.wait;
		~setparams.(1, width:1, rapidity:30);
		5.wait;
	};
};


// let's go
~playertask = Task({
	// TODO IN PRACTICE WE DO NOT WANT TO START WITH THE ORCH FILL <<<<<<<<<<<<<<
	// TODO WE WANT MANY MORE MOMENTS OF SPARSITY - eg with wide circle,  <<<<<<<<<<<<<
	~jumpcut.("one_harmonic_per", 0);
	loop{
		~setparams.value(1, amp:0.0); // ensure set at least once
		0.2.wait;
		~bringin.("oneper_to_orch_thrum_varsaw", 1, 20);
		//~bringin.("oneper_to_orch_thrum", 1, 20);
		~crossfadeparams.(0, 5, amp: [0.7, 0.1]); // de-emphasise bed
		5.wait;
		~oneper_orch_modulations.();
		~jumpcut.("one_harmonic_per+waveactiv", 0);
		30.wait;
		~bringin.("tracerbeep", 1, 20);
		10.wait;
		~crossfadeparams.(0, 20, amp: [0.7, 0.0]); // fadeout wavactiv
		20.wait;
		20.wait;
		~jumpadd_fragpwm.();
		20.wait;
		~jumpcutamps.([0, 0.7]); // pull away tracerbeep (i.e. silence 0)
		5.wait;
		~brief_superhigh.(); // on 0
		~alternate_fragpwm.();
		~jumpcut.("tracerbeep", 0);
		15.wait;
		~bringin.("one_harmonic_per+chord+lfo", 1, 20);
		15.wait;
		~setparams.value(0, amp:0.0);
		0.2.wait;
		~bringin.("one_harmonic_per", 0, 20);
		5.wait;
		~crossfadeparams.(0, 20, amp: [0.7, 0.0]); // fadeout oneper
		20.wait;
		~bringin.("tracerbeep", 0, 0.1);
		5.wait;
		~setparams.value(1, amp:0.0);
		5.wait;
		~jumpcut.("one_harmonic_per+waveactiv", 1);
		10.wait;
		~bringin.("tonestack01sin", 0, 20, amp:0.4);
		30.wait;
		~crossfadeparams.(1, 2, amp: [0.7, 0.0]); // fadeout wavactiv
		30.wait;
	};
}).play(AppClock);
/*
~playertask.stop;
*/
) // end
