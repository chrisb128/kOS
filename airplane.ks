run once ease.
run once energy.
run once attitude.
run once navigator.


global function initAutopilot {
    parameter plan, cfg.

    local this is lexicon(
        "plan", (plan),
        "cfg", (cfg),
        "nav", initNavigator(plan, cfg),
        "energy", energyController(),
        "attitude", attitudeController(cfg),
        "rollCtl", pidLoop(cfg:rollResponse * 2.0, cfg:rollResponse * 0.01, cfg:rollResponse * 0.0, -cfg:rollRange, cfg:rollRange),
        "pitchAvg", newMovingAverage(10),
        "throttle", 0,
        "startTime", time:seconds
    ).

    set this:rollCtl:setpoint to 0.
    
    set this:nav:mode to "idle".

    local initLogs is { parameter _this. autopilotInitLogs(_this).}.
    set this:initLogs to initLogs:bind(this).


    local drive is { parameter _this. return autopilotDrive(_this).}.
    set this:drive to drive:bind(this).

    return this.
}

local function autopilotDrive {
    parameter this.

    local nav is this:nav.
    local plan is this:plan.
    local energy is this:energy.
    local attitude is this:attitude.    

    if (sas) {
        this:attitude:reset().
    }
    
    if (nav:mode = "idle") {
        return.
    }

    nav:setWaypoint().
    nav:setTargets().
    local head is nav:heading.
    local tgtAlt is nav:altitude.
    local speed is nav:speed.

    local pitch is 0.
    local roll is 0.

    local phi is attitude:phiVector.
    
    local shipHead is getShipHeading().
    local headingErr is -headingError(shipHead, head).
    set roll to this:rollCtl:update(time:seconds, headingErr).
    
    local ctls is energy:getControls(tgtAlt, speed).

    if (nav:mode = "ascend") {
        local minPitch is this:cfg:ascentMinPitch.
        local maxPitchRange is this:cfg:pitchRange.

        if (ship:bounds:bottomaltradar < 10) {
            set roll to 0.
        }

        local maxPitch is max(minPitch, min((ship:bounds:bottomaltradar / 4) + minPitch, maxPitchRange)).
        energy:setPitchRange(minPitch, maxPitch).
        set this:throttle to ctls:throttle.
    } else if (nav:mode = "cruise") {
        energy:setPitchRange(-this:cfg:pitchRange, this:cfg:pitchRange).
        set this:throttle to ctls:throttle.
    } else if (nav:mode = "approach") {
        energy:setPitchRange(-this:cfg:pitchRange / 2, this:cfg:pitchRange / 4).
        set this:throttle to ctls:throttle.
    } else if (nav:mode = "land") {
        set this:throttle to 0.
        energy:setPitchRange(-5, 1).
    } else if (nav:mode = "break") {
        energy:setPitchRange(0, 1).
        set this:throttle to 0.
    }

    this:pitchAvg:update(ctls:pitch).
    set pitch to this:pitchAvg:mean().

    set attitude:target to heading(getShipHeading(), pitch, roll).

    local actuation is attitude:drive().
    
    set ship:control:pitch to actuation:x.
    set ship:control:roll to actuation:y.
    set ship:control:yaw to actuation:z.

    nav:updateFlightMode().
    nav:setShipControls().

    local t is time:seconds.

    this:energy:writeLogs(this:startTime).
    this:attitude:writeLogs(this:startTime).

    log joinString(
        list(t - this:startTime,
            pitch,
            pitch + phi:x * constant:radtodeg,
            phi:x * constant:radtodeg,
            roll,
            roll + phi:y * constant:radtodeg,
            phi:y * constant:radtodeg,
            head,
            getShipHeading(),
            headingErr,
            speed,
            ship:velocity:surface:mag,
            speed - ship:velocity:surface:mag,
            tgtAlt,
            ship:altitude,
            tgtAlt - ship:altitude), ",") to logFileName("TestPilot.csv").

    logInfo("Nav Mode    : " + nav:mode, 1).

    logInfo("Tgt Pitch   : " + round(pitch, 3), 3).
    logInfo("Tgt Roll    : " + round(roll, 3), 4).
    logInfo("Tgt Heading : " + round(head, 3), 5).

    logInfo("Heading Err : " + round(headingErr, 3), 8).
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


    local waypointIndex is min(plan:waypoints:length, max(0, nav:currentWaypoint)).
    if (nav:mode = "approach") {        
        logInfo("Waypoint #  : Approach", 17).
        logInfo("Bearing to  : " + round(plan:destination:start:heading, 3), 18).
        logInfo("Distance to : " + round(distanceTo(plan:destination:start), 3), 19).
    } else if (nav:mode = "land") {
        logInfo("Waypoint #  : Runway", 17).
        logInfo("Bearing to  : " + round(plan:destination:end:heading, 3), 18).
        logInfo("Distance to : " + round(distanceTo(plan:destination:end), 3), 19).
    } else if (waypointIndex < plan:waypoints:length) {
        local waypoint is plan:waypoints[waypointIndex].
        logInfo("Waypoint #  : " + waypointIndex, 17).
        logInfo("Bearing to  : " + round(waypoint:location:heading, 3), 18).
        logInfo("Distance to : " + round(distanceTo(waypoint:location), 3), 19).
    } 
    logInfo("Target Speed   : " + round(speed, 3), 20).
    logInfo("Target Altitude: " + round(tgtAlt, 3), 21).
    logInfo("Target Total   : " + round(energy:desiredTotal, 3), 22).
    logInfo("Target Ratio   : " + round(energy:desiredRatio, 3), 23).
    
    logInfo("Speed Err      : " + round(speed - ship:velocity:surface:mag, 3), 25).
    logInfo("Altitude Err   : " + round(tgtAlt - ship:altitude, 3), 26).
    logInfo("Total Err      : " + round(energy:desiredTotal - energy:currentTotal, 3), 27).
    logInfo("Ratio Err      : " + round(energy:desiredRatio - energy:currentRatio, 3), 28).
}

local function autopilotInitLogs {
    parameter this.
    
    this:energy:initLogs().
    this:attitude:initLogs().
    
    initLog("TestPilot.csv").
    log "Time,TgtPitch,Pitch,PitchErr,TgtRoll,Roll,RollErr,TgtHead,Head,HeadErr,TgtSpeed,Speed,SpeedErr,TgtAltitude,Altitude,AltitudeErr" to logFileName("TestPilot.csv").
}
