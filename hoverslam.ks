//created by /u/supreme_blorgon (blorgon on KSP forum).
 
declare function _hoverslam {
    parameter vOffset is 0.

    wait until verticalspeed < 0.
    lock steering to srfretrograde.
    set throt to 0.
    lock throttle to throt.
    local h to altitude - vOffset.
    
    //the '0.635' down there in the throttle function should be bigger the lower your TWR is. 0.635 works for any TWR > 2, so I'm thinking of adding a small function that adjusts that value if your TWR is < 2, but it's not really a priority for me since my propulsive landers always have higher TWRs than that (and I use parachutes when possible).
    until (h - geoposition:terrainheight) < 2 {
        set throt to min(1,max(0,(((0.635/(1+constant:e^(5-1.5*(h-geoposition:terrainheight))))+((h-geoposition:terrainheight)/min(-1,(verticalspeed))))+(abs(verticalspeed)/(availablethrust/mass))))).
        wait 0.
        
        set h to altitude - vOffset.
    }

    set throt to 0.
}

declare function hoverslam {

    lock trueRadar to ship:bounds:bottomaltradar.
    lock g to constant:g * body:mass / body:radius^2.
    lock maxDecel to (ship:availablethrust / ship:mass) - g.
    lock stopDist to ship:verticalspeed^2 / (2*maxDecel).
    lock idealThrottle to stopDist / trueRadar.
    
    wait until ship:verticalspeed < -1.
    
	lock steering to srfretrograde.
    
    wait until trueRadar < stopDist.
	lock throttle to idealThrottle.
    
    wait until ship:verticalspeed > -0.01.
    
    lock throttle to 0.
}

declare function softdrop {
    local g is ship:body:mu / (ship:altitude + ship:body:radius)^2.
    
    wait until ship:verticalspeed < -0.5.

    lock maxAcc to ship:availableThrust / ship:mass.
    local hoverThrottle is g / maxAcc.

    lock throttle to hoverThrottle * 0.95.

    wait until ship:bounds:bottomaltradar < 0.5.

    lock throttle to 0.
}