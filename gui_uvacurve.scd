// assumes that uvacurve is already running
/* ALSO:
~finalaudiobus.scope;
~subbus.scope;
s.meter;
*/
(
var w, mainbox, obj, wrapperwidget, thiswidget, subwidget;
w = Window("gui_uvacurve_audio", Rect(800, 64, 400, 800));
mainbox = VLayout();

///////////////////////////////////////////////////
// GUI panel for global settings - main amp, speakers onoff+amp, subs onoff+amp, fakedoppler, fakereverb, fakependulums
// level meter would be nice too

wrapperwidget = HLayout();
//
thiswidget = VLayout();
thiswidget.add(StaticText().string_("MASTER"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
	if(but.value==0){~outputter.run(false)}{~outputter.run(true)}
});
thiswidget.add(obj);
obj = Slider().value_(0.7).action_({|slider|
	~outputter.set(\amp, slider.value);
});
thiswidget.add(obj);
wrapperwidget.add(thiswidget);
//
thiswidget = VLayout();
thiswidget.add(StaticText().string_("Mids"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
	~outputter.set(\midon, but.value);
});
thiswidget.add(obj);
obj = Slider().value_(0.7).action_({|slider|
	~outputter.set(\midamp, slider.value);
});
thiswidget.add(obj);
wrapperwidget.add(thiswidget);
//
thiswidget = VLayout();
thiswidget.add(StaticText().string_("Subs"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(0).action_({|but|
	~outputter.set(\subon, but.value);
});
thiswidget.add(obj);
obj = Slider().value_(0.7).action_({|slider|
	~outputter.set(\subamp, slider.value);
});
thiswidget.add(obj);
wrapperwidget.add(thiswidget);

mainbox.add(wrapperwidget);

////////

thiswidget = HLayout();
thiswidget.add(StaticText().string_("Scene pos motion"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
	if(but.value==0){~scenepossynth.run(false)}{~scenepossynth.run(true)}
});
thiswidget.add(obj);
mainbox.add(thiswidget);

thiswidget = HLayout();
thiswidget.add(StaticText().string_("Fake doppler"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
	~dopplerfaker.set(\active, but.value);
});
thiswidget.add(obj);
mainbox.add(thiswidget);

thiswidget = HLayout();
thiswidget.add(StaticText().string_("Fake reverb"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(0).action_({|but|
	~outputter.set(\reverbon, but.value);
});
thiswidget.add(obj);
mainbox.add(thiswidget);

thiswidget = HLayout();
thiswidget.add(StaticText().string_("Fake pendulum data"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
	if(but.value==0){~fakependulums.run(false)}{~fakependulums.run(true)}
});
thiswidget.add(obj);
mainbox.add(thiswidget);



///////////////////////////////////////////////////
// Foreach running scenemachine: an onoff button, scenetype, amp, width

~scenenames = ~scenetypes.keys.asArray.sort;
~scenesboxes = ~nscenes.collect{|whichscene|
	wrapperwidget = HLayout();
	thiswidget = VLayout();
	thiswidget.add(StaticText().string_("Scene %".format(whichscene)));
	obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
		if(but.value==0){~sceneplayers[whichscene].pause}{~sceneplayers[whichscene].resume};
	});
	thiswidget.add(obj);
	obj = Slider().value_(0.7).action_({|slider|
		~sceneplayers[whichscene].set(\amp, slider.value)
	});
	thiswidget.add(obj);
	wrapperwidget.add(thiswidget);

	thiswidget = VLayout();
	obj = Slider().orientation_(\horizontal).value_(0).action_({|slider|
		~sceneplayers[whichscene].set(\width, slider.value)
	});
	thiswidget.add(obj);

	subwidget = HLayout();
	obj = StaticText().string_("Rapidity:");
	subwidget.add(obj);
	obj = NumberBox().value_(1).action_({|widg|
		~scenepossynths[whichscene].set(\ratescale, widg.value)
	});
	subwidget.add(obj);
	obj = StaticText().string_("Freq x");
	subwidget.add(obj);
	obj = NumberBox().value_(1).action_({|widg|
		~sceneplayers[whichscene].set(\freqscale, widg.value)
	});
	subwidget.add(obj);
	thiswidget.add(subwidget);


	obj = ListView(bounds: Rect(0,0,100,100)).items_(~scenenames).selectionMode_(\single);
	obj.value_(~scenenames.indexOfEqual(~defaultscenes[whichscene]));
	obj.action_({|list|
		~pushascene.value(list.items[list.value], whichscene)
	});
	thiswidget.add(obj);

	wrapperwidget.add(thiswidget);

	mainbox.add(wrapperwidget);
	wrapperwidget
};



w.layout = mainbox;
w.front;
)