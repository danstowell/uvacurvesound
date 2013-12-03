(
// TODO LATER: each of these functions will be accessible by OSC messages from outside

////////////////////////////////////////////////////////////////
// Directly sets the amps of all scenes (also ensures running/paused correctly). Use this for when you've silently prepared a scene and want to jump to it
~jumpcutamps = {|amps|
	amps.do{|anamp, index|
		~sceneplayers[index].set(\amp, anamp);
		// We also set the running/notrunning
		if(anamp==0){{~sceneplayers[index].pause}.defer(0.4)}{~sceneplayers[index].resume};
	};
};
/*
~jumpcutamps.value([0, 0.7])
~jumpcutamps.value([0.7, 0])
~jumpcutamps.value([0.7, 0.7])
*/

////////////////////////////////////////////////////////////////
// Just pushes parameter settings to a single scene, whether it's playing or not
~setparams = {|index, amp=0.7, width=0.5, freqscale=1, circlesize=1, rapidity=5|
	~sceneplayers[index].set(\amp, amp, \width, width, \freqscale, freqscale, \circlesize, circlesize);
	~scenepossynths[index].set(\rapidity, rapidity, \circlesize, circlesize);
};

////////////////////////////////////////////////////////////////
// Crossfades current parameters slowly to a new set
~crossfadeparams = {|index, xfadetime=4, amp=0.7, width=0.5, freqscale=1, circlesize=1, rapidity=5|

	var origs = (xfadetime:4, amp:0.7, width:0.5, freqscale:1, circlesize:1, rapidity:5), interp = Dictionary[];
	var delta = 0.05, xfade0, xfade1;
	[\amp, \width, \freqscale, \circlesize, \rapidity].do{|key|
		origs[key] = ~sceneplayers[0].get(key) ?? {
			~sceneplayers[0].set(key, origs[key]);
			origs[key]
		};
	};

	Task{
		(0, delta .. xfadetime).do{|pos|
			xfade0 = pos.asFloat / xfadetime;
			xfade1 = 1 - xfade0;
			interp[\amp]        = (xfade0 * amp)        + (xfade1 * origs[\amp]);
			interp[\width]      = (xfade0 * width)      + (xfade1 * origs[\width]);
			interp[\freqscale]  = (xfade0 * freqscale)  + (xfade1 * origs[\freqscale]);
			interp[\circlesize] = (xfade0 * circlesize) + (xfade1 * origs[\circlesize]);
			interp[\rapidity]   = (xfade0 * rapidity)   + (xfade1 * origs[\rapidity]);
			~setparams.value(index, amp:interp[\amp], width:interp[\width], freqscale:interp[\freqscale], circlesize:interp[\circlesize], rapidity:interp[\rapidity]);
			delta.wait;
		};
	}.play;
};
/*
~crossfadeparams.value(0, 0.5, freqscale: 0.5, amp: 0.3)
~crossfadeparams.value(0, 4, freqscale: 1, amp: 0.7)
*/

////////////////////////////////////////////////////////////////
// Loads a new scene into a player. Intended for use with players that are already muted, hence amp=0.
// TO CONSIDER: why isn't this all bundled into ~pushascene?
~preparesilent = {|index, scenename, amp=0.0, width=0.5, freqscale=1, circlesize=1, rapidity=5|
	//~sceneplayers[index].pause; // WTF>>>>>>>>>>>>>>>>>>> WEIRD MISBEHAVIOUR
	~pushascene.value(scenename, index);
	Task{
		0.2.wait;
		s.sync;
		~setparams.value(index, amp, width, freqscale, circlesize, rapidity);
	}.play;
};
/*
~preparesilent.value(1, "orch_saw1")
~preparesilent.value(0, "superhigh")
~preparesilent.value(0, "tonestack01sin", 0.7)
*/

)
