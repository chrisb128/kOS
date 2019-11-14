run once logging.
run once time.

local debug is false.
local writeLog is true.
local logFile is "0:/airplane_log.csv".

global function initAutopilot {

    // input - potential + kinetic energy
    // output - throttle ctl
    local throttlePid is pidLoop(0.075, 0.001, 0.02, 0, 1).

    // input - potential / potential + kinetic energy
    // output - target pitch
    local pitchPid is pidLoop(100, 6, 20, -30, 30).

    // input - pitch
    // output - target pitch vel
    local pitchRotPid is pidLoop(0.1, 0.001, 0.000, -12, 12).

    // input - pitch vel
    // output - pitch ctl
    local pitchCtlPid is pidLoop(0.2, 0.05, 0.000, -1, 1).

    // input - heading err
    // output - roll angle
    local rollPid is pidLoop(-3, -0.2, -0.01, -45, 45).

    // input - roll
    // output - target roll vel
    local rollRotPid is pidLoop(-0.09, -0.00, -0.075, -25, 25).

    // input - roll vel
    // output - roll ctl
    local rollCtlPid is pidLoop(0.05, 0.01, 0.00, -1, 1).

    // input - yaw
    // output - target yaw vel
    local yawRotPid is pidLoop(0.15, 0.01, 0, -1, 1).

    // input - yaw vel
    // output - yaw ctl
    local yawCtlPid is pidLoop(0.3, 0.0, 0, -1, 1).

    if writeLog {
        if exists(logFile) {
            local f is open(logFile).
            f:clear().
        }

        log (
            "Time,Tgt Speed,Speed,Kp,Ki,Kd,Out,Tgt Alt,Alt,Kp,Ki,Kd,Out,Tgt Pitch,Pitch,Kp,Ki,Kd,Out,Tgt PitchV,PitchV,Kp,Ki,Kd,Out"
        ) to logFile.
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
        "lockRoll", false
    ).
}

global function setAutopilotPitchRange {
    parameter autopilot.
    parameter range.

    set autopilot:pitchPid:maxoutput to range.
    set autopilot:pitchPid:minoutput to -range.
}

global function setAutopilotRollRange {
    parameter autopilot.
    parameter range.

    set autopilot:rollPid:maxoutput to range.
    set autopilot:rollPid:minoutput to -range.
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


global function autopilotLoop {
    parameter autopilot.
    parameter targetSpeed.
    parameter targetAltitude.
    parameter targetHeading.
    parameter targetRoll.
    parameter lockRoll.

    logInfo("Target Altitude: " + targetAltitude, 1).
    logInfo("Altitude: " + ship:altitude, 2).
    logInfo("Target Speed: " + targetSpeed, 3).
    logInfo("Speed: " + ship:velocity:surface:mag, 4).

    local currentPotential is potentialEnergy(ship:altitude).
    local currentKinetic is kineticEnergy(ship:altitude, ship:velocity:surface:mag).
    local currentTotal is (currentPotential + currentKinetic) / ship:mass.
    local currentRatio is currentPotential / (currentPotential + currentKinetic).
    logInfo("Total: " + currentTotal, 7).
    logInfo("Ratio: " + currentRatio, 10).

    local desiredPotential is potentialEnergy(targetAltitude).
    local desiredKinetic is kineticEnergy(targetAltitude, targetSpeed).
    local desiredTotal is (desiredPotential + desiredKinetic) / ship:mass.
    local desiredRatio is desiredPotential / (desiredPotential + desiredKinetic).
    logInfo("Desired Total: " + desiredTotal, 6).
    logInfo("Desired Ratio: " + desiredRatio, 9).

    logInfo("Total Err: " + (desiredTotal - currentTotal), 8).
    logInfo("Ratio Err: " + (desiredRatio - currentRatio), 11).

    local shipPitch is 90 - vAng(ship:up:forevector, ship:facing:forevector).
    logInfo("Pitch: " + round(shipPitch, 3), 13).

    local shipRoll is -(90-vAng(ship:up:forevector, -1 * ship:facing:starvector)).
    logInfo("Roll: " + round(shipRoll, 3), 14).

    local currentHeading is getShipHeading().
    logInfo("Current heading: " + currentHeading, 15).
    logInfo("Target heading: " + targetHeading, 16).

    local headingErr is currentHeading - targetHeading.
    if abs((currentHeading + 360) - targetHeading) < abs(headingErr) {
        set headingErr to (currentHeading + 360) - targetHeading.
    }

    if abs(headingErr) > 180 {
        set headingErr to -headingErr.
    }

    if not lockRoll {
        set autopilot:rollPid:setpoint to 0.
        set targetRoll to autopilot:rollPid:update(time:seconds, headingErr).
    }

    set ctl to ship:control.

    set autopilot:throttlePid:setpoint to desiredTotal.
    local throtLock is autopilot:throttlePid:update(time:seconds, currentTotal).
    lock throttle to throtLock.

    if autopilot:throttlePid:error < -1000 {
        brakes on.
    } else if autopilot:throttlePid:error > -600 {
        brakes off.
    }

    set autopilot:pitchPid:setpoint to desiredRatio.
    local targetPitch to autopilot:pitchPid:update(time:seconds, currentRatio).
    logInfo("Target Pitch: " + round(targetPitch, 3), 12).

    local angVel is ship:angularVel.

    local rollAngVel is vDot(angVel, ship:facing:starvector).
    local pitchAngVel is vDot(angVel, ship:facing:forevector).
    local yawAngVel is vDot(angVel, ship:facing:upvector).

    // actual controls
    set autopilot:pitchRotPid:setpoint to targetPitch.
    local tgtPitchVel to autopilot:pitchRotPid:update(time:seconds, shipPitch).
    logInfo("Tgt Pitch rate: " + tgtPitchVel, 24).

    set autopilot:rollRotPid:setpoint to targetRoll.
    local tgtRollVel to autopilot:rollRotPid:update(time:seconds, shipRoll).
    logInfo("Tgt Roll rate: " + tgtRollVel, 25).

    set autopilot:yawRotPid:setpoint to 0.
    local tgtYawVel to autopilot:yawRotPid:update(time:seconds, headingErr).
    logInfo("Tgt Yaw rate: " + tgtYawVel, 26).

    set autopilot:pitchCtlPid:setpoint to tgtPitchVel.
    local ctlPitch to autopilot:pitchCtlPid:update(time:seconds, pitchAngVel).

    set autopilot:rollCtlPid:setpoint to tgtRollVel.
    local ctlRoll to autopilot:rollCtlPid:update(time:seconds, rollAngVel).

    set autopilot:yawCtlPid:setpoint to tgtYawVel.
    local ctlYaw to autopilot:yawCtlPid:update(time:seconds, yawAngVel).

    set ctl:roll to ctlRoll.
    set ctl:pitch to ctlPitch * cos(shipRoll).
    set ctl:yaw to ctlYaw * cos(shipRoll) + ctlPitch * sin(shipRoll).

    logInfo("Ctl Pitch: " + ctl:pitch, 17).
    logInfo("Ctl  Roll: " + ctl:roll, 18).
    logInfo("Ctl   Yaw: " + ctl:yaw, 19).


    if writeLog {
        log (
            time:seconds + "," +
            targetSpeed + "," +
            ship:velocity:surface:mag + "," +
            autopilot:throttlePid:pTerm + "," +
            autopilot:throttlePid:iTerm + "," +
            autopilot:throttlePid:dTerm + "," +
            autopilot:throttlePid:output + "," +
            targetAltitude + "," +
            ship:altitude + "," +
            autopilot:pitchPid:pTerm + "," +
            autopilot:pitchPid:iTerm + "," +
            autopilot:pitchPid:dTerm + "," +
            autopilot:pitchPid:output + "," +
            targetPitch + "," +
            shipPitch + "," +
            autopilot:pitchRotPid:pTerm + "," +
            autopilot:pitchRotPid:iTerm + "," +
            autopilot:pitchRotPid:dTerm + "," +
            autopilot:pitchRotPid:output + "," +
            tgtPitchVel + "," +
            pitchAngVel + "," +
            autopilot:pitchCtlPid:pTerm + "," +
            autopilot:pitchCtlPid:iTerm + "," +
            autopilot:pitchCtlPid:dTerm + "," +
            autopilot:pitchCtlPid:output
        ) to logFile.
    }

    wait 0.
}