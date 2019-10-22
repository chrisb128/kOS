run once logging.
run once time.

local debug is false.
local writeLog is true.
local logFile is "0:/airplane_log.csv".

global function initAutopilot {

    // input - ground speed
    // output - throttle ctl
    local throttlePid is pidLoop(0.5, 0.04, 0.8, 0, 1).

    // input - altitude
    // output - target vertical speed
    local vSpeedPid is pidLoop(0.5, 0, 0.25, -50, 50).

    // input - vertical speed
    // output - target pitch
    local pitchPid is pidLoop(0.5, 0.1, 0.00, -15, 15).

    // input - pitch
    // output - target pitch vel
    local pitchRotPid is pidLoop(0.8, 0.1, 0.00, -10, 10).

    // input - pitch vel
    // output - pitch ctl
    local pitchCtlPid is pidLoop(0.05, 0.0, 0.015, -1, 1).

    // input - roll
    // output - target roll vel
    local rollRotPid is pidLoop(-0.5, -0.1, 0.00, -10, 10).

    // input - roll vel
    // output - roll ctl
    local rollCtlPid is pidLoop(0.01, 0.0, 0.005, -1, 1).

    // input - yaw
    // output - target yaw vel
    local yawRotPid is pidLoop(1, 0.1, 0, -10, 10).

    // input - yaw vel
    // output - yaw ctl
    local yawCtlPid is pidLoop(0.00, 0.0, 0, -1, 1).

    if writeLog {
        if exists(logFile) {
            local f is open(logFile).
            f:clear().
        }

        log (
            "Time,Tgt Speed,Speed,Kp,Ki,Kd,Out,Tgt Alt,Alt,Kp,Ki,Kd,Out,Tgt VSpeed,VSpeed,Kp,Ki,Kd,Out,Tgt Pitch,Pitch,Kp,Ki,Kd,Out,Tgt PitchV,PitchV,Kp,Ki,Kd,Out"
        ) to logFile.
    }

    return lexicon(
        "throttlePid", throttlePid,
        "vSpeedPid", vSpeedPid,
        "pitchPid", pitchPid,
        "pitchRotPid", pitchRotPid,
        "pitchCtlPid", pitchCtlPid,
        "rollRotPid", rollRotPid,
        "rollCtlPid", rollCtlPid,
        "yawRotPid", yawRotPid,
        "yawCtlPid", yawCtlPid,
        "rollRange", 45
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

    set autopilot:rollRange to range.
}

global function autopilotLoop {
    parameter autopilot.
    parameter targetSpeed.
    parameter targetAltitude.
    parameter targetHeading.

    local targetRoll is 0.

    logInfo("Ground speed: " + ship:velocity:surface:mag, 1).
    logInfo("Altitude: " + ship:altitude, 2).
    logInfo("Pitch range: " + round(autopilot:pitchPid:maxoutput, 2), 3).

    local shipPitch is 90 - vAng(ship:up:forevector, ship:facing:forevector).
    logInfo("Pitch: " + round(shipPitch, 3), 4).

    local shipRoll is -(90-vAng(ship:up:forevector, -1 * ship:facing:starvector)).
    logInfo("Roll: " + round(shipRoll, 3), 6).

    local currentHeading is getShipHeading().
    logInfo("Current heading: " + currentHeading, 8).
    logInfo("Target heading: " + targetHeading, 9).

    local headingErr is currentHeading - targetHeading.
    if abs((currentHeading + 360) - targetHeading) < abs(headingErr) {
        set headingErr to (currentHeading + 360) - targetHeading.
    }


    if abs(headingErr) > 0.25 {
        // set roll to turn towards new heading
        if (headingErr > 0) {
            set targetRoll to min(headingErr * 5, autopilot:rollRange).
        } else {
            set targetRoll to max(headingErr * 5, -autopilot:rollRange).
        }
    }

    logInfo("Target roll: " + round(targetRoll, 3), 7).

    set ctl to ship:control.

    set autopilot:throttlePid:setpoint to targetSpeed.
    local throtLock is autopilot:throttlePid:update(time:seconds, ship:velocity:surface:mag).
    lock throttle to throtLock.

    set autopilot:vSpeedPid:setpoint to targetAltitude.
    local tgtVertSpeed is autopilot:vSpeedPid:update(time:seconds, ship:altitude).
    set autopilot:pitchPid:setpoint to tgtVertSpeed.
    logInfo("Target vSpeed: " + tgtVertSpeed, 15).
    logInfo("Actual vSpeed: " + ship:verticalspeed, 16).


    local targetPitch to autopilot:pitchPid:update(time:seconds, ship:verticalspeed).

    logInfo("Target pitch: " + targetPitch, 5).


    local angVel is ship:angularVel.

    local rollAngVel is vDot(angVel, ship:facing:starvector).
    local pitchAngVel is vDot(angVel, ship:facing:forevector).
    local yawAngVel is vDot(angVel, ship:facing:upvector).

    logInfo("Roll rate: " + rollAngVel, 10).
    logInfo("Pitch rate: " + pitchAngVel, 11).
    logInfo("Yaw rate: " + yawAngVel, 12).

    // actual controls
    set autopilot:pitchRotPid:setpoint to targetPitch.
    local tgtPitchVel to autopilot:pitchRotPid:update(time:seconds, shipPitch).

    set autopilot:pitchCtlPid:setpoint to tgtPitchVel.
    set ctl:pitch to autopilot:pitchCtlPid:update(time:seconds, pitchAngVel).

    set autopilot:rollRotPid:setpoint to targetRoll.
    local tgtRollVel to autopilot:rollRotPid:update(time:seconds, shipRoll).

    set autopilot:rollCtlPid:setpoint to tgtRollVel.
    set ctl:roll to autopilot:rollCtlPid:update(time:seconds, rollAngVel).

    if (abs(headingErr) < 0.25) {
        set autopilot:yawRotPid:setpoint to targetHeading.
    } else {
        set autopilot:yawRotPid:setpoint to currentHeading.
    }
    local tgtYawVel to autopilot:yawRotPid:update(time:seconds, currentHeading).

    set autopilot:yawCtlPid:setpoint to tgtYawVel.
    set ctl:yaw to autopilot:yawCtlPid:update(time:seconds, yawAngVel).

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
            autopilot:vSpeedPid:pTerm + "," +
            autopilot:vSpeedPid:iTerm + "," +
            autopilot:vSpeedPid:dTerm + "," +
            autopilot:vSpeedPid:output + "," +
            tgtVertSpeed + "," +
            ship:verticalspeed + "," +
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