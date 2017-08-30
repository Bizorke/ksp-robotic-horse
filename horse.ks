set ir to addons:ir.

//Get the parts.
set shoulders to ir:partservos(ship:partsdubbed("shoulders")[0])[0]. //shoulders servo.
set pelvis to ir:partservos(ship:partsdubbed("pelvis")[0])[0]. //pelvis servo.
set fr to ir:partservos(ship:partsdubbed("fr")[0])[0]. //front right leg servo.
set fl to ir:partservos(ship:partsdubbed("fl")[0])[0]. //front left leg servo.
set br to ir:partservos(ship:partsdubbed("br")[0])[0]. //back right leg servo.
set bl to ir:partservos(ship:partsdubbed("bl")[0])[0]. //back left leg servo.
set neck1 to ir:partservos(ship:partsdubbed("neck1")[0])[0]. //neck up/down servo.
set neck2 to ir:partservos(ship:partsdubbed("neck2")[0])[0]. //neck left/right servo.
set neck3 to ir:partservos(ship:partsdubbed("neck3")[0])[0]. //neck rotation servo.
set frleg to ship:partsdubbed("frleg")[0]. //front right leg part.
set flleg to ship:partsdubbed("flleg")[0]. //front left leg part.
set brleg to ship:partsdubbed("brleg")[0]. //back right leg part.
set blleg to ship:partsdubbed("blleg")[0]. //back left leg part.
set controlcore to ship:partsdubbed("control")[0]. //The control core for this vehicle. Should be facing up. Make sure it's rotated the right way.
set la to ship:partsdubbed("la")[0]:GETMODULE("moduledeployableantenna"). //left antenna - used for random animations.
set ra to ship:partsdubbed("ra")[0]:GETMODULE("moduledeployableantenna"). //right antenna - used for random animations.

//SET STEERINGMANAGER:ROLLTORQUEFACTOR TO 0.1. //Not sure what this does.

function resethorse{
	sas off.
	controlcore:controlfrom().
	set gallop_state to 0.
	set lean_direction to 0.
	if gear{
		shoulders:moveto(0, 10).
		pelvis:moveto(0, 10).
		fr:moveto(0, 10).
		fl:moveto(0, 10).
		br:moveto(0, 10).
		bl:moveto(0, 10).
	}
	else{
		shoulders:moveto(90, 10).
		pelvis:moveto(90, 10).
		fr:moveto(0.87, 10).
		fl:moveto(0.87, 10).
		br:moveto(0.87, 10).
		bl:moveto(0.87, 10).
	}
	neck1:moveto(0, 10).
	//neck2:moveto(0, 10).
	//neck3:moveto(0, 10).
	wait until not shoulders:ismoving.
	wait until not pelvis:ismoving.
	wait until not fr:ismoving.
	wait until not fl:ismoving.
	wait until not br:ismoving.
	wait until not bl:ismoving.
	//wait until not neck1:ismoving.
	//wait until not neck2:ismoving.
	//wait until not neck3:ismoving.
}



//print ship:geoposition:terrainheight. //- facing:vector * blleg:position.

//Definitions.
set t_mul to 9. //Maximum speed multiplier (-1 because this gets added to the min, 1).
set gallop_state to 0. //0 = setup. 1 = forward. 2 = backward.
set lean_direction to 0. //0 = no lean. 1 = forward-leaning. 2 = backward-leaning.
set tilt_amount to 15. //Forward/backward tilt amount (using steering). Totally experimental. //TODO: the optimal value for this may be dependant on planet, mass, etc. Need to configure.
set f_direction to ship:facing:roll - up:roll.

function get_lean{ //TODO: Fine-tune this lean value. Maybe set up an experiment program to collect data and determine optimal lean and it's factors using KOS.
	if not lean_direction {return 0.}
	if lean_direction = 1 {return tilt_amount * 2.} //I found that it works better when I multiply tilt_amount by 2 here. Yes this is bad.
	if lean_direction = 2 {return -tilt_amount.}
}

lock lean to get_lean().

function onward{ 
	//print lean.
	
	//FIX: this only appears to work while facing west (90°). Maybe try a forward facing computer and adjust the code. Alternatively it could be because the coordinate system is using orbital coords instead of surface coords.
	return up + r(0, lean, f_direction).
}

lock steering to onward().

//TODO: in addition to pointing the computer up, we should also use the forearms and forelegs to keep the horse stable on slopes. I added some distance lasers, just haven't coded them in yet.

//The following two functions went through a lot of iterations and testing to get working. 
//These are the most important things to optimize.

function thrust_front{
	shoulders:moveto(-50, 1 + t_mul * throttle).
	neck1:moveto(30, 1 + t_mul * throttle).
	fl:moveto(0, 1 + t_mul * throttle).
	fr:moveto(0, 1 + t_mul * throttle).
	
	wait until not shoulders:ismoving.
	
	set lean_direction to 0.
	fl:moveto(0.87, 1 + t_mul * throttle).
	fr:moveto(0.87, 1 + t_mul * throttle).
	
	wait until not fl:ismoving.
	
	//Reset early.
	set lean_direction to 2.
	
	wait 0.2. //TODO: these 0.2 values may depend on throttle, t_mul, or other foactors.
	
	shoulders:moveto(-10, 1 + t_mul * throttle). //The reason I don't reset this to -30 is because I find that it causes the robot to trip over itself and slow down.
												 //so instead of relying on rotation of the legs to add momentum to the bot, it uses more the forearms to push itself forward.
	neck1:moveto(-30 + default_neck, 1 + t_mul * throttle).
}

function thrust_back{
	pelvis:moveto(50, 1 + t_mul * throttle).
	bl:moveto(0, 1 + t_mul * throttle).
	br:moveto(0, 1 + t_mul * throttle).
	
	wait until not pelvis:ismoving.
	
	set lean_direction to 0.

	bl:moveto(0.87, 1 + t_mul * throttle).
	br:moveto(0.87, 1 + t_mul * throttle).
	
	wait until not br:ismoving.
	
	//Reset early.
	set lean_direction to 1.
	wait 0.2.
	pelvis:moveto(-30, 1 + t_mul * throttle). //Here I've reset this to -30, not -10. Just found it works better (for minmus).
}

//Would love to add a "naay" sound, somehow.
function random_events{
	if random() < 0.001 and la:getfield("status") = "Extended" {la:DOEVENT("retract antenna").}
	else if random() < 0.01 and la:getfield("status") = "Retracted" {la:DOEVENT("extend antenna").}
	if random() < 0.001 and ra:getfield("status") = "Extended" {ra:DOEVENT("retract antenna").}
	else if random() < 0.01 and ra:getfield("status") = "Retracted" {ra:DOEVENT("extend antenna").}
	if not ship:control:PILOTWHEELSTEER{
		if random() < 0.01 {neck2:moveto((random() - 0.5) * 60, 1).}
		if random() < 0.01 {neck2:moveto(0, 1).}
	}
	else{
		neck2:moveto(45 * ship:control:PILOTWHEELSTEER, 1).
	}
	if random() < 0.001 {neck3:moveto((random() - 0.5) * 60, 1).}
	if random() < 0.01 {neck3:moveto(0, 1).}
}

resethorse().
wait 0.5.

set noinputcnt to 0.

until 0{
	//print ship:control:PILOTWHEELTHROTTLE.
	set f_direction to f_direction - ship:control:PILOTWHEELSTEER * 2. //TODO: this method of turning is slow and sucks. Partly because it's blocked by the rest of the code. If only we could run it in a different thread.
																	   //alternatively, make the rest of the code non-blocking. i.e. Don't wait for robot parts to finish moving, etc.
																	   //Another problem is that the steering manager turns the vessel far too slowly. 
	//print f_direction.
	if not brakes and gear and ship:control:PILOTWHEELTHROTTLE = 1 { //Wheel controls. 
		set noinputcnt to 0.
		if ship:status = "landed"{
			if not gallop_state {set gallop_state to 2.}
			if gallop_state = 1 {
				thrust_front().
				set gallop_state to 2.
			}
			else if gallop_state = 2 {
				thrust_back().
				set gallop_state to 1.
			}
		}
	}
	else{
		set noinputcnt to noinputcnt + 1.
		if noinputcnt > 100 { //Arbitrary number. TODO: might be better to make it time based.
			resethorse().
			
		}
	}
	random_events(). //If you don't want random events like the ears retracting, etc, comment this out.
}