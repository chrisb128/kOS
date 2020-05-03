run once navigator.
run once energy.
run once runways.
run once attitude.
run once airplane.
run once flight_plan.
run once mission.
run once maneuvers.
run once executenode.

run once "0:/flight_paths/spaceplane.ks".

global function ascend {
    parameter targetAp.

    clearScreen.

    local cfg is lexicon(
        "rollRange", 40,
        "rollResponse", 0.5,
        "pitchRange", 30,
        "ascentMinPitch", 8,
        "attitudeResponse", 1,
        "stoppingTime", 2
    ).


    local exitAngle is 10.

    local pilot is initAutopilot(spaceplane_ascent_plan(), cfg).
    pilot:initLogs().
    set pilot:nav:mode to "ascend".
    lock throttle to pilot:throttle.

    if (ship:maxthrust <= 0) {
        stage.
        wait 1.
    }

    local quit is false.

    on AG7 { set quit to true. }.

    local prevVel is ship:velocity:surface:mag.

    until ship:altitude > (.3 * body:atm:height) and ship:velocity:surface:mag > 1200 and prevVel > ship:velocity:surface:mag {

        set prevVel to ship:velocity:surface:mag.

        pilot:drive().
        
        wait 0.
    }

    set pilot:nav:mode to "idle".
    clearscreen.

    lock throttle to 0.

    local attitude is attitudeController(cfg).

    ag5 on.

    local throt is 1.
    lock throttle to throt.


    local function getExitingAttTarget {

        local velVec is ship:velocity:surface.
        if (ship:altitude > body:atm:height * .75) {
            set velVec to ship:velocity:orbit.
        }

        // aim for prograde, but minimum pitch is 10
        local progradePitch is (90-vAng(-ship:body:position, velVec)).
        if ((ship:apoapsis < (targetAp * 0.99) or eta:periapsis < eta:apoapsis) and progradePitch < exitAngle) {
            return lookDirUp(velVec, -ship:body:position) * R(-(exitAngle-progradePitch), 0, 0).
        } else {
            return lookDirUp(velVec, -ship:body:position).
        }
    }

    until ship:altitude > 70000 {
        
        set attitude:target to getExitingAttTarget().
        rcs on.

        // burn to make and keep apoapsis above target AP
        if (ship:apoapsis < targetAp and throt = 1) {
            set throt to 1.
        } else if (ship:apoapsis < targetAp) {
            set throt to 0.1.
        } else {
            set throt to 0.
        }

        local actuation is attitude:drive().
        
        set ship:control:pitch to actuation:x.
        set ship:control:roll to actuation:y.
        set ship:control:yaw to actuation:z.
        
        logInfo("Nav Mode    : exit", 1).
        logInfo("Phi : " + formatVec(attitude:phiVector, 3), 9).
        logInfo("Axis : " + formatVec(attitude:axis, 0), 10).

        logInfo("Angular Vel : " + formatVec(attitude:omega, 3), 11).
        logInfo("Tgt Ang Vel : " + formatVec(attitude:targetOmega, 3), 12).
        logInfo("Ctl Torque  : " + formatVec(attitude:controlTorque, 3), 13).
        logInfo("Tgt Torque  : " + formatVec(attitude:targetTorque, 3), 14).
        logInfo("MOI         : " + formatVec(attitude:moi, 3), 15).
        local moiOverTorque is V(
            attitude:moi:x/attitude:controlTorque:x,
            attitude:moi:y/attitude:controlTorque:y,
            attitude:moi:z/attitude:controlTorque:z).
        logInfo("MOI/Torque  : " + formatVec(moiOverTorque, 3), 16).

        wait 0.
    }.

    wait 5.

    set ship:control:pitch to 0.
    set ship:control:roll to 0.
    set ship:control:yaw to 0.
    lock throttle to 0.
}