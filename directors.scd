(
// TODO LATER: each of these functions will be accessible by OSC messages from outside

////////////////////////////////////////////////////////////////
// Directly sets the amps of all scenes (also ensures running/paused correctly). Use this for when you've silently prepared a scene and want to jump to it
~jumpcutamps = {|amps|
	amps.do{|anamp, index|
		~sceneplayers[index].set(\amp, anamp);
		// We also set the running/notrunning
		//DEACTIVATED FOR SIMPLICITY   if(anamp==0){{~sceneplayers[index].pause}.defer(0.4)}{~sceneplayers[index].resume};
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
// Crossfades current parameters slowly to a new set -- to crossfade any given param, pass a [from, to] array rather than a single val
~crossfadeparams = {|index, xfadetime=4, amp=0.7, width=0.5, freqscale=1, circlesize=1, rapidity=5|

	var params = (amp:amp, width:width, freqscale:freqscale, circlesize:circlesize, rapidity:rapidity);
	var frm = Dictionary[];
	var too = Dictionary[];
	var delta = 0.05, xfade0, xfade1, interp = Dictionary[];
	var ourkeys = [\amp, \width, \freqscale, \circlesize, \rapidity];
	ourkeys.do{|key|
		frm[key] = params[key].asArray.wrapAt(0);
		too[key] = params[key].asArray.wrapAt(1);
	};
	"Crossfading these params: %".format(ourkeys.select{|key| params[key].asArray.size==2}).postln;

	Task{
		(0, delta .. xfadetime).do{|pos|
			xfade0 = pos.asFloat / xfadetime;
			xfade1 = 1 - xfade0;
			ourkeys.do{|key|
				interp[key] = (xfade0 * too[key]) + (xfade1 * frm[key]);
			};
			~setparams.value(index, amp:interp[\amp], width:interp[\width], freqscale:interp[\freqscale], circlesize:interp[\circlesize], rapidity:interp[\rapidity]);
			delta.wait;
		};
	}.play;
};
/*
~crossfadeparams.value(0, 0.5, freqscale: [1, 0.5], amp: [0.7, 0.3])
~crossfadeparams.value(0,   4, freqscale: [0.5, 1], amp: [0.3, 0.7])
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
