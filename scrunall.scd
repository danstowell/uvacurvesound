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
	1.wait;
	s.sync;
	//"osc_uvacurve.scd".loadRelative;
}.play(AppClock);

)
// ServerShmInterface

/*
s.scope(5)
*/
