(
// /Applications/SuperCollider365/SuperCollider.app/Contents/Resources/sclang runme.scd

Task{
	"uvacurve.scd".loadRelative;
	3.wait;
	s.sync;
	~scope = ~finalaudiobus.scope;
	~scope.yZoom_(100);
	~scope.window.bounds_(Rect(10, 10, 200, 700));
	//~levmeter = ServerMeter(s, 0, 8);
	//~levmeter.window.bounds_(~levmeter.window.bounds.left_(1500).top_(700));
	~fscope = FreqScope();
	~fscope.window.bounds_(~fscope.window.bounds.left_(1400).top_(100));
	//"gui_uvacurve.scd".loadRelative;
	1.wait;
	s.sync;
	~automoving.value(false);
	"osc_uvacurve.scd".loadRelative;
}.play(AppClock);

)
// ServerShmInterface


/*
s.boot
s.scope(2)
*/
