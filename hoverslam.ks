
declare function hoverslam {
    parameter vOffset is 0.

    lock _hoverslam_trueRadar to ship:bounds:bottomaltradar - vOffset.
    lock _hoverslam_g to body:mu / (ship:altitude + body:radius)^2.
    lock _hoverslam_maxDecel to (ship:availableThrust / ship:mass) - _hoverslam_g.
    lock _hoverslam_stopDist to ship:verticalSpeed^2 / (2 * _hoverslam_maxDecel).
    lock _hoverslam_idealThrottle to _hoverslam_stopDist / _hoverslam_trueRadar.
    
    wait until ship:verticalspeed < -1.
    
	lock steering to srfretrograde.
    
    wait until _hoverslam_trueRadar < _hoverslam_stopDist.    
	lock throttle to _hoverslam_idealThrottle.
    
    wait until _hoverslam_trueRadar <= 1.
    lock _hoverslam_trueRadar to 1.

    wait until ship:verticalSpeed > -0.5.

    unlock throttle.
    unlock steering.
    unlock _hoverslam_idealThrottle.
    unlock _hoverslam_stopDist.
    unlock _hoverslam_maxDecel.
    unlock _hoverslam_g.
    unlock _hoverslam_trueRadar.
}

declare function hover {
    parameter shouldStop.
    parameter hoverVel is 0.
    
    local throtLock to throttle.
    lock throttle to throtLock.

    local throtPid is pidLoop(0.5, 0.1, 0).
    set throtPid:setpoint to hoverVel.
    
    until shouldStop() {
        set throtLock to throtPid:update(time:seconds, ship:verticalSpeed).
        wait 0.
    }
}