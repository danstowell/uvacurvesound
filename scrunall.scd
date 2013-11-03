(
// /Applications/SuperCollider365/SuperCollider.app/Contents/Resources/sclang runme.scd

Task{
	"uvacurve.scd".loadRelative;
	2.wait;
	s.sync;
	"gui_uvacurve.scd".loadRelative;
	~scope = s.scope(~npendulums);
	~scope.yZoom_(100);
	~scope.window.bounds_(Rect(10, 10, 200, 700));
}.play(AppClock);

)
// ServerShmInterface
