s.boot;
MIDIClient.init;
MIDIIn.connectAll;
~notes = Array.newClear(128);
##############################
(
SynthDef.new (\pad, {
	arg atk = 0.0, rel = 1, freq1 = 0, gate = 1, amp = 0.0, pw1 = 0.2, tune1 = 0, crv = -2, lffreq1 = 2, lffreq2 = 2, lfo1lo = 0, lfo1hi = 0, lfo2lo = 0.4, lfo2hi = 0.6;
	var env,  sig;
	var osc1, osc2, osc3, osc4;
	var lfo1, lfo2;
	lfo1 = Pulse.kr(lffreq1).range(lfo1lo,lfo1hi);
	env = EnvGen.kr(Env.adsr(atk, 1,  rel, crv), gate, doneAction:2);
	lfo2 = Pulse.kr(lffreq2).range(lfo2lo,lfo2hi);
	env = EnvGen.kr(Env.adsr(atk, 1,  rel, crv), gate, doneAction:2);
	osc1 = SinOsc.ar(lfo2, lfo1);
	osc2 = SinOsc.ar(lfo2 );
	osc3 = Saw.ar(freq1 );
	osc4 = VarSaw.ar(freq1, lfo1);
	sig = Mix.ar([osc1*0.7, osc2*0.25, osc3*0.120, osc4*0.1]);

	sig = sig * env * amp;

	Out.ar(0, sig*3);
} ).add;

)
b = Synth(\pad);
b.set(\freq1, 440);
######################################
(
SynthDef.new (\Synthbass, {

	arg atk = 0.0, rel = 0.00, crv = -3, gate = 1, freq1 = 30, amp = 0.9, ffrq1 = 20000, rq1=1, dky=0,sus =1, lffreq = 1.5,
	lflo = 0,lfhi = 5;
	var env, lpf1, sig;
	var osc1, osc2, osc3, osc4;
	var lfo1;
	lfo1 = Pulse.kr(lffreq).range(lflo, lfhi);
	env = EnvGen.ar(Env.adsr(atk,dky,sus,rel,curve:crv), gate, doneAction: 2);
	osc1 = SinOsc.ar(freq1,phase: Rand(0,1));
	osc2 = SinOsc.ar(freq1,phase: Rand(0,1));
	osc3 = SinOsc.ar(freq1,phase: Rand(0,1));
	osc4 = WhiteNoise.ar();
	sig = Mix.ar([osc1*0.2, osc2*0.2, osc3*0.3, osc4*0.00]);


	lpf1 = RLPF.ar(sig, ffrq1, rq1);
	Out.ar(0, lpf1*amp*env);
}).add

)
a = Synth(\Synthbass);
a.set(\freq, 440);
a.free;
###################################################
(
SynthDef.new(\iter,{
	arg freq =440, lflo = 1.0,lffreq = 4,lfhi = 1.5, rel = 0.5;
	var temp,temp1, sum, env;
	var lfo1;

	sum = 0;
	lfo1 = Pulse.kr(lffreq).range(lflo, lfhi);
	env = EnvGen.kr(Env.perc(0.01,rel,1,-2), 1 ,doneAction:2
		);
	10.do{

		temp = 0.6*VarSaw.ar(
			(3*freq/4)*{Rand(0.99,1.02)}!2,
			{Rand(0.0,1.0)!2},
			{ExpRand(0.005,0.05)}!2;);
		temp1 = 10*SinOsc.ar(
			(freq*3)*{Rand(0.99,1.02)}!2,
			{Rand(0.0,1.0)!2},
			{ExpRand(0.005,0.05)}!2
		);
		sum = sum  + temp + temp1;
	};
	sum = sum *0.1*env;
	Out.ar(0,sum);

}).add;


)
x = {Synth(\iter)}.scope;
x.free;

{SinOsc.ar}.scope.free;

####################################################
( SynthDef.new(\tone, {
	arg freq1=440, amp=0.3, gate=1, bend = 0;
	var sig , env;
	sig = LFTri.ar(freq1*bend.midiratio)!2;
	env = EnvGen.kr(Env.adsr, gate , doneAction:2);
	sig = sig * env * amp;
	Out.ar(0, sig);
}).add
)
a = Synth(\tone);
a.set(\freq1, 440);

######################################################
(

SynthDef.new(\FM, {

	arg atk = 0.0, rel = 1.0, crv = -5, freq = 0, amp = 0.5, freq1 = 1720, gate = 1, bend = 0;
	var  env, sig, lpf;
	var osc1, osc2, osc3, osc4;
	env = EnvGen.kr(Env.perc(atk, 1,  rel, crv), gate, doneAction:2);
	osc2 = Saw.ar(freq)!2;
	osc4 = Saw.kr(freq1)!2;
	osc1 = SinOscFB.ar(freq,osc4)!2;
	osc3 = PinkNoise.ar()!2;


	sig = Mix.ar([osc1*2,osc2*0.3,osc3*0.03]);

	sig = sig* env * amp;


	Out.ar(0, sig*2 );

}).add;
)

a = Synth(\FM);
a.set( \freq1, 110);
a.set(\freq, 440);
a.free;


######################################################
(
p = Pbind(
	\instrument, \FM,
	\dur, Pseq ([1/4],inf).trace,
	\freq, Pseq([220,329.63,349.23,392.00],inf).trace,
	\rel, 0.6,
	\amp, 0.1
).play(quant: 1);

)

a = Synth(\iter);
a.set(\rel, 1);
a.set(\freq 110);
a.play;
p.stop;

########################################################
(
MIDIdef.noteOn(\noteOnTest,{

	arg vel, nn, chan, src;


	~notes[nn] = Synth.new(\FM,[
		\freq, nn.midicps,
		\amp, vel.linexp(1,127,0.01,0.3),
		\gate,1,

	]
	);
});
)

(
MIDIdef.noteOff(\noteOffTest,{
	arg vel,nn;

	~notes[nn].set(\gate,0);
	~notes[nn]=nil;
});

)
(MIDIdef.bend(\bendTest, {
		arg val, chan, src;
		[val, chan, src].postln;
		~bend = val;
		~notes.do {arg synth; synth.set(\bend, val.linlin(0.16383,-2.2))};
},chan:[0]);

)
~bend = 8192;

MIDIdef.freeAll



