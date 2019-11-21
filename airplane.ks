run once logging.

local writeLog is true.

global function initAutopilot {

    // input - potential + kinetic energy
    // output - throttle ctl
    local throttlePid is pidLoop(0.1, 0.000, 0.015, 0, 1).

    // input - potential / potential + kinetic energy
    // output - target pitch
    local pitchPid is pidLoop(150, 0, 15, -30, 30).

    //local pitchPid is pidLoop(300, 10, 25, -30, 30).

    // input - pitch
    // output - target pitch vel
    local pitchRotPid is pidLoop(0.05, 0.00, 0.0, -1, 1).

    // input - pitch vel
    // output - pitch ctl
    local pitchCtlPid is pidLoop(1.5, 0.1, 0, -1, 1).

    // input - heading err
    // output - roll angle
    local rollPid is pidLoop(-2, -0.0, -0.1, -35, 35).

    // input - roll
    // output - target roll vel
    local rollRotPid is pidLoop(-0.005, -0.00, -0.00375, -5, 5).

    // input - roll vel
    // output - roll ctl
    local rollCtlPid is pidLoop(0.25, 0.05, 0.00, -1, 1).

    // input - heading err
    // output - target yaw vel
    local yawRotPid is pidLoop(0.2, 0.0, 0, -1.5, 1.5).

    // input - yaw vel
    // output - yaw ctl
    local yawCtlPid is pidLoop(0.3, 0.0, 0, -1, 1).

    if writeLog {
        if exists("0:/" + ship:name + "/ThrottlePid.csv") { deletePath("0:/" + ship:name + "/ThrottlePid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/ThrottlePid.csv".

        if exists("0:/" + ship:name + "/PitchPid.csv") { deletePath("0:/" + ship:name + "/PitchPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/PitchPid.csv".

        if exists("0:/" + ship:name + "/PitchRotPid.csv") { deletePath("0:/" + ship:name + "/PitchRotPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/PitchRotPid.csv".

        if exists("0:/" + ship:name + "/RollRotPid.csv") { deletePath("0:/" + ship:name + "/RollRotPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/RollRotPid.csv".

        if exists("0:/" + ship:name + "/YawRotPid.csv") { deletePath("0:/" + ship:name + "/YawRotPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/YawRotPid.csv".

        if exists("0:/" + ship:name + "/PitchCtlPid.csv") { deletePath("0:/" + ship:name + "/PitchCtlPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/PitchCtlPid.csv".

        if exists("0:/" + ship:name + "/RollCtlPid.csv") { deletePath("0:/" + ship:name + "/RollCtlPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/RollCtlPid.csv".

        if exists("0:/" + ship:name + "/YawCtlPid.csv") { deletePath("0:/" + ship:name + "/YawCtlPid.csv"). }
        log pidLogHeader() to "0:/" + ship:name + "/YawCtlPid.csv".
    }

    return lexicon(
        "throttlePid", throttlePid,
        "pitchPid", pitchPid,
        "pitchRotPid", pitchRotPid,
        "pitchCtlPid", pitchCtlPid,
        "rollPid", rollPid,
        "rollRotPid", rollRotPid,
        "rollCtlPid", rollCtlPid,
        "yawRotPid", yawRotPid,
        "yawCtlPid", yawCtlPid,
        "lockRoll", false,
        "writeLog", writeLog
    ).
}


global function setAutopilotPitchRange {
    parameter autopilot.
    parameter min.
    parameter max.


    set autopilot:pitchPid:maxoutput to max.
    set autopilot:pitchPid:minoutput to min.
}

global function setAutopilotRollRange {
    parameter autopilot.
    parameter min.
    parameter max.

    set autopilot:rollPid:maxoutput to max.
    set autopilot:rollPid:minoutput to min.
}

local function potentialEnergy {
    parameter alt.

    return ship:mass * alt.
}

local function kineticEnergy {
    parameter alt.
    parameter speed.

    local bodyG is body:mu / (alt + body:radius)^2.

    return (ship:mass * speed^2) / (2 * bodyG).
}

local function momentOfInertia {
    local angMom is ship:angularMomentum.
    local angVel is ship:angularVel.

    return V(angMom:x / angVel:x, angMom:y / angVel:y, angMom:z / angVel:z).
}

local function pidLogHeader {
    return "Time,Kp,Ki,Kd,Input,SetPoint,Err,PTerm,ITerm,DTerm,Output".
}

local function pidLogEntry {
    parameter pid.
    return time:seconds + ","
        + pid:kp + ","
        + pid:ki + ","
        + pid:kd + ","
        + pid:input + ","
        + pid:setpoint + ","
        + pid:error + ","
        + pid:pterm + ","
        + pid:iterm + ","
        + pid:dterm + ","
        + pid:output.
}

global function autopilotSetControls {
    parameter autopilot.
    parameter targetSpeed.
    parameter targetAltitude.
    parameter targetHeading.

    local currentPotential is potentialEnergy(ship:altitude).
    local currentKinetic is kineticEnergy(ship:altitude, ship:velocity:surface:mag).
    local currentTotal is (currentPotential + currentKinetic) / ship:mass.
    local currentRatio is currentPotential / (currentPotential + currentKinetic).

    local desiredPotential is potentialEnergy(targetAltitude).
    local desiredKinetic is kineticEnergy(targetAltitude, targetSpeed).
    local desiredTotal is (desiredPotential + desiredKinetic) / ship:mass.
    local desiredRatio is desiredPotential / (desiredPotential + desiredKinetic).

    logInfo("Target Speed: " + targetSpeed, 3).
    logInfo("Speed: " + ship:velocity:surface:mag, 4).
    logInfo("Desired Total: " + desiredTotal, 6).
    logInfo("Total: " + currentTotal, 7).
    logInfo("Total Err: " + (desiredTotal - currentTotal), 8).


    logInfo("Target Altitude: " + targetAltitude, 1).
    logInfo("Altitude: " + ship:altitude, 2).
    logInfo("Desired Ratio: " + desiredRatio, 9).
    logInfo("Ratio: " + currentRatio, 10).
    logInfo("Ratio Err: " + (desiredRatio - currentRatio), 11).

    local shipPitch is 90 - vAng(ship:up:forevector, ship:facing:forevector).
    logInfo("Pitch: " + round(shipPitch, 3), 13).

    local shipRoll is -(90-vAng(ship:up:forevector, -1 * ship:facing:starvector)).
    logInfo("Roll: " + round(shipRoll, 3), 14).

    local currentHeading is getShipHeading().
    logInfo("Current heading: " + currentHeading, 15).
    logInfo("Target heading: " + targetHeading, 16).

    local headingErr is headingError(currentHeading, targetHeading).

    if not autopilot:lockRoll {
        set autopilot:rollPid:setpoint to 0.
        set targetRoll to autopilot:rollPid:update(time:seconds, headingErr).
    }

    set autopilot:throttlePid:setpoint to desiredTotal.
    local throtLock is autopilot:throttlePid:update(time:seconds, currentTotal).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:throttlePid) to "0:/" + ship:name + "/ThrottlePid.csv". }

    lock throttle to throtLock.

    set autopilot:pitchPid:setpoint to desiredRatio.
    local targetPitch to autopilot:pitchPid:update(time:seconds, currentRatio).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:pitchPid) to "0:/" + ship:name + "/PitchPid.csv". }

    logInfo("Target Pitch: " + round(targetPitch, 3), 12).

    local angVel is ship:angularVel.

    local rollAngVel is vDot(angVel, ship:facing:starvector).
    local pitchAngVel is vDot(angVel, ship:facing:forevector).
    local yawAngVel is vDot(angVel, ship:facing:upvector).

    // actual controls
    set autopilot:pitchRotPid:setpoint to targetPitch.
    local tgtPitchVel to autopilot:pitchRotPid:update(time:seconds, shipPitch).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:pitchRotPid) to "0:/" + ship:name + "/PitchRotPid.csv". }

    set autopilot:rollRotPid:setpoint to targetRoll.
    local tgtRollVel to autopilot:rollRotPid:update(time:seconds, shipRoll).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:rollRotPid) to "0:/" + ship:name + "/RollRotPid.csv". }

    set autopilot:yawRotPid:setpoint to 0.
    local tgtYawVel to autopilot:yawRotPid:update(time:seconds, headingErr).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:yawRotPid) to "0:/" + ship:name + "/YawRotPid.csv". }

    set autopilot:pitchCtlPid:setpoint to tgtPitchVel.
    local ctlPitch to autopilot:pitchCtlPid:update(time:seconds, pitchAngVel).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:pitchCtlPid) to "0:/" + ship:name + "/PitchCtlPid.csv". }

    set autopilot:rollCtlPid:setpoint to tgtRollVel.
    local ctlRoll to autopilot:rollCtlPid:update(time:seconds, rollAngVel).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:rollCtlPid) to "0:/" + ship:name + "/RollCtlPid.csv". }

    set autopilot:yawCtlPid:setpoint to tgtYawVel.
    local ctlYaw to autopilot:yawCtlPid:update(time:seconds, yawAngVel).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:yawCtlPid) to "0:/" + ship:name + "/YawCtlPid.csv". }

    local ctl to ship:control.
    set ctl:roll to ctlRoll.

    set ctl:pitch to ctlPitch * cos(shipRoll).// + ctlYaw * sin(shipRoll).
    set ctl:yaw to ctlYaw * cos(shipRoll).// + (ctlPitch * sin(shipRoll) * 0.1).

    wait 0.
}
