run once energy.
run once attitude.
run once navigator.

global function initAutopilot {
    parameter plan.

    local this is lexicon(
        "plan", plan,
        "nav", initNavigator(plan),
        "energy", newEnergyController(),
        "attitude", attitudeController(),
        "rollCtl", pidLoop(1.0, 0.1, 0, -30, 30),
        "pitchAvg", newMovingAverage(5),
        "throttle", 0,
        "startTime", time:seconds
    ).

    set this:rollCtl:setpoint to 0.
    
    set this:nav:mode to "ascend".

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
    
    nav:setWaypoint().
    nav:setTargets().

    if (nav:mode = "idle") {
        return.
    }

    local pitch is 0.
    local roll is 0.
    local head is nav:heading:getCurrentValue().
    local tgtAlt is nav:altitude:getCurrentValue().
    local speed is nav:speed:getCurrentValue().

    local phi is attitude:phiVector.
    
    local shipHead is getShipHeading().
    local headingErr is -headingError(shipHead, head).
    set roll to this:rollCtl:update(time:seconds, headingErr).
    
    local ctls is energy:getControls(tgtAlt, speed).
    set this:throttle to ctls:throttle.
    if (nav:mode = "ascend") {
        local minPitch is 6.
        local maxPitch is 20.

        local pitchRange is max(minPitch, min((ship:bounds:bottomaltradar / 4) + minPitch, maxPitch)).
        energy:setPitchRange(-pitchRange, pitchRange).
        set roll to 0.
    } else if (nav:mode = "approach") {
        energy:setPitchRange(-10, 5).
    } else if (nav:mode = "land") {
        set this:throttle to 0.
        energy:setPitchRange(-5, 0).
    } else if (nav:mode = "break") {
        set this:throttle to 0.
    }


    this:pitchAvg:update(ctls:pitch).
    set pitch to this:pitchAvg:mean().

    set attitude:target to heading(shipHead, pitch, roll).

    local actuation is attitude:drive().    

    set ship:control:pitch to actuation:x * cos(roll).
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
            roll,
            head,
            speed,
            pitch + phi:x * constant:radtodeg,
            roll + phi:y * constant:radtodeg,
            head + phi:z * constant:radtodeg,
            ship:velocity:surface:mag,
            phi:x * constant:radtodeg,
            phi:y * constant:radtodeg,
            phi:z * constant:radtodeg,
            speed - ship:velocity:surface:mag), ",") to logFileName("TestPilot.csv").

    logInfo("Nav Mode    : " + nav:mode, 1).

    logInfo("Tgt Pitch   : " + round(pitch, 3), 3).
    logInfo("Tgt Roll    : " + round(roll, 3), 4).
    logInfo("Tgt Heading : " + round(head, 3), 5).

    logInfo("Pitch Err   : " + round(phi:x * constant:radtodeg, 3), 6).
    logInfo("Roll Err    : " + round(phi:y * constant:radtodeg, 3), 7).
    logInfo("Heading Err : " + round(headingErr, 3), 8).
    logInfo("Yaw Err     : " + round(phi:z * constant:radtodeg, 3), 9).

    local waypointIndex is min(plan:waypoints:length, max(0, nav:currentWaypoint)).
    if (nav:mode = "approach") {        
        logInfo("Waypoint #  : Approach", 10).
        logInfo("Bearing to  : " + round(plan:destination:start:heading, 3), 11).
        logInfo("Distance to : " + round(distanceTo(plan:destination:start), 3), 12).
    } else if (nav:mode = "land") {
        logInfo("Waypoint #  : Runway", 10).
        logInfo("Bearing to  : " + round(plan:destination:end:heading, 3), 11).
        logInfo("Distance to : " + round(distanceTo(plan:destination:end), 3), 12).
    } else if (waypointIndex < plan:waypoints:length) {
        local waypoint is plan:waypoints[waypointIndex].
        logInfo("Waypoint #  : " + waypointIndex, 10).
        logInfo("Bearing to  : " + round(waypoint:location:heading, 3), 11).
        logInfo("Distance to : " + round(distanceTo(waypoint:location), 3), 12).
    } 

    logInfo("Angular Vel : " + formatVec(attitude:omega, 3), 16).
    logInfo("Tgt Ang Vel : " + formatVec(attitude:targetOmega, 3), 17).
    logInfo("Tgt Torque  : " + formatVec(attitude:targetTorque, 3), 18).
    
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
    log "Time,TgtPitch,TgtRoll,TgtHead,TgtSpeed,Pitch,Roll,Head,Speed,PitchErr,RollErr,HeadErr,SpeedErr" to logFileName("TestPilot.csv").
}
