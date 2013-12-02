(
// /Applications/SuperCollider365/SuperCollider.app/Contents/Resources/sclang runme.scd

Task{
	"uvacurve.scd".loadRelative;
	3.wait;
	s.sync;
	"gui_uvacurve.scd".loadRelative;
	~scope = ~finalaudiobus.scope;
	~scope.yZoom_(100);
	~scope.window.bounds_(Rect(10, 10, 200, 700));
	// ~levmeter = ServerMeter(s, 0, 8);
	// ~levmeter.window.bounds_(~levmeter.window.bounds.left_(1300).top_(500));
	// ~fscope = FreqScope()
	// ~fscope.window.bounds_(~fscope.window.bounds.left_(1000).top_(100));
	1.wait;
	s.sync;
	"osc_uvacurve.scd".loadRelative;
}.play(AppClock);

)
// ServerShmInterface


/*
s.boot
s.scope(5)
*/
