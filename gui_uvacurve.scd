// assumes that uvacurve is already running
/* ALSO:
~finalaudiobus.scope;
~subbus.scope;
s.meter;
*/
(
var w, mainbox, obj, wrapperwidget, thiswidget, subwidget;
w = Window("gui_uvacurve_audio", Rect(800, 64, 600, 800));
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

/*
thiswidget = HLayout();
thiswidget.add(StaticText().string_("Scene pos motion"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(1).action_({|but|
if(but.value==0){~scenepossynth.run(false)}{~scenepossynth.run(true)}
});
thiswidget.add(obj);
mainbox.add(thiswidget);
*/
thiswidget = HLayout();
thiswidget.add(StaticText().string_("Fake doppler & indirectness"));
obj = Button().states_([["off", Color.white, Color.black], ["ON", Color.red, Color.white]]).value_(0).action_({|but|
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


~sceneshackboxes = [];


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

	/*  */
	subwidget = HLayout();
	obj = StaticText().string_("Rapidity:");
	subwidget.add(obj);
	obj = NumberBox().value_(1).action_({|widg|
		~scenepossynths[whichscene].set(\ratescale, widg.value)
	});
	subwidget.add(obj);
	thiswidget.add(subwidget);
	/*  */

	/*
	subwidget = HLayout();
	obj = StaticText().string_("Freq x");
	subwidget.add(obj);
	{
	var obj1, obj2;
	obj1 = NumberBox().value_(1);
	obj2 = Slider().orientation_(\horizontal).value_(0.5);
	obj1.action_({|widg|
	obj2.value_(widg.value.max(0.0001).explin(0.666666, 1.5, 0, 1));
	~sceneplayers[whichscene].set(\freqscale, widg.value)
	});
	obj2.action_({|widg|
	obj1.valueAction_(widg.value.linexp(0,1, 0.666666, 1.5));
	//~sceneplayers[whichscene].set(\freqscale, widg.value.linexp(0,1, 0.666666, 1.5))
	});

	subwidget.add(obj1);
	subwidget.add(StaticText().string_("     "));
	subwidget.add(obj2);
	thiswidget.add(subwidget);
	}.value();
	// */

	obj = ListView(bounds: Rect(0,0,100,100)).items_(~scenenames).selectionMode_(\single);
	obj.value_(~scenenames.indexOfEqual(~defaultscenes[whichscene]));
	obj.action_({|list|
		~pushascene.value(list.items[list.value], whichscene);
		~updatehackbox.value(list.items[list.value], whichscene);
	});
	subwidget = HLayout();
	subwidget.add(obj);
	// TODO now add a thing for hacking the vals
	{
		var container = VLayout();
		var subc;
		~myhackbox = Dictionary.new();
		//container.add(StaticText().string_("axis"));
		//~myhackbox[\axisch] = PopUpMenu().items_(["x", "z"]);
		//container.add(~myhackbox[\axisch]);

		(0..1).do{|hackindex|
			~myhackbox["lbl%".format(hackindex)] = StaticText().string_("val%".format(hackindex));
			container.add(~myhackbox["lbl%".format(hackindex)]);
			subc = HLayout();
			"abc".do{|subboxer, whichsubboxer|
				~myhackbox["val%%".format(hackindex, subboxer)] = TextField().value_(1).action_({|widg|
					~scenevalpointsbus[whichscene].setAt(hackindex * 3 + whichsubboxer, widg.value.asFloat);
					//"~scenevalpointsbus[%].setAt(%, %)".format(whichscene, hackindex * 3 + whichsubboxer, widg.value).postln;
				});
				subc.add(~myhackbox["val%%".format(hackindex, subboxer)]);
			};
			container.add(subc);
		};
		~sceneshackboxes = ~sceneshackboxes.add(~myhackbox);
		subwidget.add(container);

	}.value();
	thiswidget.add(subwidget);
	wrapperwidget.add(thiswidget);

	mainbox.add(wrapperwidget);
	wrapperwidget
};

~updatehackbox = {|scenename, whichscene|
	var hackdata = ~scenetypes[scenename][1];
	var hackbox = ~sceneshackboxes[whichscene];
	(0..1).do{|hackindex|
		if(hackdata[hackindex].notNil){
			hackbox["lbl%".format(hackindex)].string_(hackdata[hackindex][0]);
			"abc".do{|subboxer, whichsubboxer|
				hackbox["val%%".format(hackindex, subboxer)].value_(hackdata[hackindex][1].asArray.wrapAt(whichsubboxer));
			};
		}{
			hackbox["lbl%".format(hackindex)].string_("[unused]");
		};
	};
};

~nscenes.do{|i| ~updatehackbox.value(~defaultscenes[i], i) };

w.layout = mainbox;
w.front;
)
