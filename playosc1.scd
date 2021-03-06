(
if(~fromport.isNil){"Please run osc_uvacurve before running playosc1".error}{
	~selfsendaddr = NetAddr("127.0.0.1", ~fromport);

	/*
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "tracer")
	~selfsendaddr.sendMsg("/d3/sound/0/bang", 11)
	12.do{|val| ~selfsendaddr.sendMsg("/d3/sound/0/bang", val) }
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "tracerbeep")
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "tonestack01sin", 1, "freqscale", 1)
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "tonestack01tri02", 1, "freqscale", 1.2)
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "tonestack01tri02", 12, "freqscale", 1.2)
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "tonestack01sin", 0, "freqscale", 1)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "freqscale", 0.5)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "freqscale", 2)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "width", 1)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "width", 0)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "amp", 0)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "amp", 0.7)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "position", 0)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "position", 4)
	~selfsendaddr.sendMsg("/d3/sound/0/setparam", "position", 5)
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "silent")
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "bal_riffle", 1, "freqscale", 1, "amp", 0.6, "width", 1);
	~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "bal_riffle", 1, "freqscale", 1, "amp", 0.6, "width", 0);
	*/

	~automoving.value(true);

	~playertask = Task({
		loop{
			/////////////////////////////////////////////////////////////////
			// bal_riffle (or tri) as a bed
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "bal_riffle", 1, "freqscale", 1, "amp", 0.6, "width", 1);
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "silent", 4);
			15.wait;
			// bal_purity1 in briefly, moving around spatially, then it narrows and goes
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "bal_purity2", 4, "amp", 0.7, "width", 0.2);
			15.wait;
			(0.3, 0.25 .. 0).do{|wid|
				~selfsendaddr.sendMsg("/d3/sound/1/setparam", "width", wid);
				1.0.wait;
			};
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "silent", 4);
			8.0.wait;

			/////////////////////////////////////////////////////////////////
			// then elastic_boinger2d comes in, narrow then widening
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "elastic_boinger2d", 10, "width", 0);
			20.wait;
			(0, 0.1 .. 0.4).do{|wid|
				~selfsendaddr.sendMsg("/d3/sound/1/setparam", "width", wid);
				1.0.wait;
			};
			// - underneath it, the natural bed goes and is replaced by unbal_clustpot
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "unbal_clustpot", 10, "freqscale", 1, "amp", 0.7, "width", 1);
			(0.5, 0.6 .. 1).do{|wid|
				~selfsendaddr.sendMsg("/d3/sound/1/setparam", "width", wid);
				1.0.wait;
			};

			/////////////////////////////////////////////////////////////////
			15.wait;
			// boinger2d goes
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "silent", 2);
			15.wait;
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "unbal_clustpot_hi", 3);
			15.wait;
			// tracerbeep comes in
			~selfsendaddr.sendMsg("/d3/sound/1/changepatch", "tracerbeep", 0.1, "amp", 0.5);
			15.wait;
			// clustpot goes (suddenly?) leaving space for tracerbeep to live on its own
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "puresine01", 0.2, "amp", 0.01);
			2.wait;
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "silent", 0.2);
			10.wait;
			// a couple of high hisses fine under
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "hinoise", 0.4, "amp", 0.4);
			1.0.wait;
			3.do{
				~selfsendaddr.sendMsg("/d3/sound/0/setparam", "amp", 0.4);
				3.wait;
				~selfsendaddr.sendMsg("/d3/sound/0/setparam", "amp", 0.0);
				rand(5, 13).wait;
			};
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "frag_pwm", 0.4, "amp", 0.3);
			5.wait;
			~selfsendaddr.sendMsg("/d3/sound/0/changepatch", "silent", 0.2);
			rand(5, 13).wait;
			10.wait;
		};
	}).play(TempoClock);
	/*
	~playertask.stop;
	*/
})