run once logging.
run once energy.

local writeLog is true.

global function newAutopilot {

    local energyCtlr is newEnergyController().

    // input - heading err
    // output - roll angle
    local rollPid is pidLoop(-0.1, -0.0, -0.0, -20, 20).


    // Desired Rotation Rate Controllers

    local rotScale is 0.175.

    local rotScalePitch is 2.5 * rotScale.
    local rotScaleRoll is -1 * rotScale.
    local rotScaleYaw is -0.1 * rotScale.
    
    local rotKp is 0.10.
    local rotKi is 0.01.
    local rotKd is 0.00.

    // input - pitch err
    // output - target pitch vel
    local pitchRotPid is pidLoop(rotScalePitch*rotKp, rotScalePitch*rotKi, rotScalePitch*rotKd, -1, 1).    
    // input - roll err
    // output - target roll vel
    local rollRotPid is pidLoop(rotScaleRoll*rotKp, rotScaleRoll*rotKi, rotScaleRoll*rotKd, -1, 1).    
    // input - heading err
    // output - target yaw vel
    local yawRotPid is pidLoop(rotScaleYaw*rotKp, rotScaleYaw*rotKi,  rotScaleYaw*rotKd, -1, 1).


    // Desired Torque Output Controllers

    // input - pitch vel
    // output - pitch ctl
    local pitchCtlPid is pidLoop().
    // input - roll vel
    // output - roll ctl
    local rollCtlPid is pidLoop().
    // input - yaw vel
    // output - yaw ctl
    local yawCtlPid is pidLoop().

    if writeLog {
        if exists(logFileName("PitchRotPid.csv")) { deletePath(logFileName("PitchRotPid.csv")). }
        log pidLogHeader() to logFileName("PitchRotPid.csv").

        if exists(logFileName("RollRotPid.csv")) { deletePath(logFileName("RollRotPid.csv")). }
        log pidLogHeader() to logFileName("RollRotPid.csv").

        if exists(logFileName("YawRotPid.csv")) { deletePath(logFileName("YawRotPid.csv")). }
        log pidLogHeader() to logFileName("YawRotPid.csv").

        if exists(logFileName("PitchCtlPid.csv")) { deletePath(logFileName("PitchCtlPid.csv")). }
        log pidLogHeader() to logFileName("PitchCtlPid.csv").

        if exists(logFileName("RollCtlPid.csv")) { deletePath(logFileName("RollCtlPid.csv")). }
        log pidLogHeader() to logFileName("RollCtlPid.csv").

        if exists(logFileName("YawCtlPid.csv")) { deletePath(logFileName("YawCtlPid.csv")). }
        log pidLogHeader() to logFileName("YawCtlPid.csv").

        if exists(logFileName("Torque.csv")) { deletePath(logFileName("Torque.csv")). }
        log "Time,MaxAngularVelocityX,MaxAngularVelocityY,MaxAngularVelocityZ,AvailableTorqueX,AvailableTorqueY,AvailableTorqueZ,MomentOfInertiaX,MomentOfInertiaY,MomentOfInertiaZ"  to logFileName("Torque.csv").
    }

    return lexicon(
        "energyCtlr", energyCtlr,
        "pitchRotPid", pitchRotPid,
        "pitchCtlPid", pitchCtlPid,
        "rollPid", rollPid,
        "rollRotPid", rollRotPid,
        "rollCtlPid", rollCtlPid,
        "yawRotPid", yawRotPid,
        "yawCtlPid", yawCtlPid,
        "lockRoll", false,
        "writeLog", writeLog,
        "startTime", time:seconds,
        "stoppingTime", 4,
        "pitchTs", 5,
        "rollTs", 5,
        "yawTs", 5,
        "controlAvg", newMovingAverageVec(3)
    ).
}

global function setAutopilotPitchRange {
    parameter autopilot.
    parameter min.
    parameter max.


    set autopilot:energyCtlr:pitchPid:maxoutput to max.
    set autopilot:energyCtlr:pitchPid:minoutput to min.
}

global function setAutopilotRollRange {
    parameter autopilot.
    parameter min.
    parameter max.

    set autopilot:rollPid:maxoutput to max.
    set autopilot:rollPid:minoutput to min.
}

local function newMovingAverageVec {
    parameter count.

    return lexicon(
        "items", list(),
        "count", count
    ).
}

local function movingAverageVecUpdate {
    parameter ma.
    parameter item.

    if (ma:items:length >= ma:count) {
        ma:items:remove(0).
    }

    ma:items:add(item).
}

local function movingAverageVecMean {
    parameter ma.
    
    local avg is V(0,0,0).

    for i in ma:items {
        set avg:x to avg:x + i:x.
        set avg:y to avg:y + i:y.
        set avg:z to avg:z + i:z.
    }

    set avg:x to avg:x / ma:items:length.
    set avg:y to avg:y / ma:items:length.
    set avg:z to avg:z / ma:items:length.

    return avg.
}

local torqueAvg is newMovingAverageVec(10).

local function torqueProvidedByPartsTagged {
    parameter tag.
    local t is V(0,0,0).
    for elevator in ship:partsTagged(tag) {
        for moduleName in elevator:modules {
            local mod is elevator:getmodule(moduleName).
            if (mod:hasTorque) {
                local modTorque is mod:torque:availableTorque.
                set t:x to t:x + ((abs(modTorque[0]:x) + abs(modTorque[1]:x)) / 2).
                set t:y to t:y + ((abs(modTorque[0]:y) + abs(modTorque[1]:y)) / 2).
                set t:z to t:z + ((abs(modTorque[0]:z) + abs(modTorque[1]:z)) / 2).
            }
        }        
    }
    return t.
}

local minTorque is 0.00001.
local function getAvailableTorque {
    local torque is V(0,0,0).
    // for provider in ship:torque:allProviders {
    //     local moduleTorques is provider:availableTorque.
    //     set torque:x to torque:x + ((abs(moduleTorques[0]:x) + abs(moduleTorques[1]:x)) / 2).
    //     set torque:y to torque:y + ((abs(moduleTorques[0]:y) + abs(moduleTorques[1]:y)) / 2).
    //     set torque:z to torque:z + ((abs(moduleTorques[0]:z) + abs(moduleTorques[1]:z)) / 2).   
    // }
    
    // pitch
    set torque:x to max(minTorque, torqueProvidedByPartsTagged("elevator"):x).
    set torque:y to max(minTorque, torqueProvidedByPartsTagged("aileron"):y).
    set torque:z to max(minTorque, torqueProvidedByPartsTagged("rudder"):z).
    
    movingAverageVecUpdate(torqueAvg, torque).

    local mean is movingAverageVecMean(torqueAvg).

    if (mean:x < minTorque) { set mean:x to 0. }
    if (mean:y < minTorque) { set mean:y to 0. }
    if (mean:z < minTorque) { set mean:z to 0. }
    
    return mean.
}

local function momentOfInertia {
    return ship:moi.
}

global function autopilotSetControls {
    parameter autopilot.
    parameter targetHeading.
    parameter targetAltitude.
    parameter targetSpeed.

    local energyControls is energyGetControls(autopilot:energyCtlr, targetAltitude, targetSpeed).

    lock throttle to energyControls:throttle.
    local targetPitch is energyControls:pitch.

    local shipPitch is 90 - vAng(ship:up:forevector, ship:facing:forevector).    
    local shipRoll is -(90 - vAng(ship:up:forevector, -1 * ship:facing:starvector)).

    local currentHeading is getShipHeading().

    local headingErr is headingError(currentHeading, targetHeading).
    
    local targetRoll is 0.
    if ship:bounds:bottomaltradar > 10 {
        set autopilot:rollPid:setpoint to 0.
        set targetRoll to autopilot:rollPid:update(time:seconds, headingErr).
    }

    local pitchErr is targetPitch - shipPitch.
    local rollErr is targetRoll - shipRoll.    
    
    logInfo("Target Pitch: " + round(targetPitch, 3), 3).
    logInfo("Target Roll : " + round(targetRoll, 3), 4).
    logInfo("Tgt Heading : " + round(targetHeading, 3), 5).

    logInfo("Pitch Err   : " + round(pitchErr, 3), 7).
    logInfo("Roll Err    : " + round(rollErr, 3), 8).
    logInfo("Heading Err : " + round(headingErr, 3), 9).

    local availableTorque is getAvailableTorque().

    local moi is momentOfInertia().

    local stoppingTime is autopilot:stoppingTime.
    local maxAngVel is V(
        availableTorque:x * stoppingTime / moi:x,
        availableTorque:y * stoppingTime / moi:y,
        availableTorque:z * stoppingTime / moi:z
    ).

    if (autopilot:writeLog) { 
        log time:seconds - autopilot:startTime + "," + maxAngVel:x + "," + maxAngVel:y + "," + maxAngVel:z + ","
            + availableTorque:x + "," + availableTorque:y + "," + availableTorque:z + ","
            + moi:x + "," + moi:y + "," + moi:z
            to logFileName("Torque.csv").
    }
    
    // get the target velocities
    set autopilot:pitchRotPid:setpoint to 0.
    set autopilot:pitchRotPid:maxoutput to maxAngVel:x.
    set autopilot:pitchRotPid:minoutput to -maxAngVel:x.
    local tgtPitchVel to autopilot:pitchRotPid:update(time:seconds, -pitchErr).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:pitchRotPid, autopilot:startTime) to logFileName("PitchRotPid.csv"). }

    set autopilot:rollRotPid:setpoint to 0.
    set autopilot:rollRotPid:maxoutput to maxAngVel:y.
    set autopilot:rollRotPid:minoutput to -maxAngVel:y.
    local tgtRollVel to autopilot:rollRotPid:update(time:seconds, -rollErr).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:rollRotPid, autopilot:startTime) to logFileName("RollRotPid.csv"). }

    set autopilot:yawRotPid:setpoint to 0.
    set autopilot:yawRotPid:maxoutput to maxAngVel:z.
    set autopilot:yawRotPid:minoutput to -maxAngVel:z.
    local tgtYawVel to autopilot:yawRotPid:update(time:seconds, -headingErr).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:yawRotPid, autopilot:startTime) to logFileName("YawRotPid.csv"). }

    if abs(rollErr) > 0.1 {
        set tgtYawVel to 0.
    }

    local angVel is ship:angularVel.
    local rollAngVel is vDot(angVel, ship:facing:starvector).
    local pitchAngVel is vDot(angVel, ship:facing:forevector).
    local yawAngVel is vDot(angVel, ship:facing:upvector).
    
    logInfo("Cur AngVel: " + formatVec(V(pitchAngVel, rollAngVel, yawAngVel), 3), 20).
    logInfo("Tgt AngVel: " + formatVec(V(tgtPitchVel, tgtRollVel, tgtYawVel), 3), 21).
    logInfo("Available torque: " + formatVec(availableTorque, 3), 22).
    logInfo("Max AngVel: " + formatVec(maxAngVel, 3), 23).

    set autopilot:pitchCtlPid:ki to moi:x * (4.0 / autopilot:pitchTs) ^ 2.
    set autopilot:pitchCtlPid:kp to 2 * (moi:x * autopilot:pitchCtlPid:ki) ^ 0.5.
    set autopilot:pitchCtlPid:kd to 0.
    set autopilot:pitchCtlPid:maxoutput to availableTorque:x.
    set autopilot:pitchCtlPid:minoutput to -availableTorque:x.
    set autopilot:pitchCtlPid:setpoint to tgtPitchVel.
    local tgtPitchTorque to autopilot:pitchCtlPid:update(time:seconds, pitchAngVel).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:pitchCtlPid, autopilot:startTime) to logFileName("PitchCtlPid.csv"). }

    set autopilot:rollCtlPid:ki to moi:y * (4.0 / autopilot:rollTs) ^ 2.
    set autopilot:rollCtlPid:kp to 2 * (moi:y * autopilot:rollCtlPid:ki) ^ 0.5.
    set autopilot:rollCtlPid:kd to 0.
    set autopilot:rollCtlPid:maxoutput to availableTorque:y.
    set autopilot:rollCtlPid:minoutput to -availableTorque:y.
    set autopilot:rollCtlPid:setpoint to tgtRollVel.
    local tgtRollTorque to autopilot:rollCtlPid:update(time:seconds, rollAngVel).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:rollCtlPid, autopilot:startTime) to logFileName("RollCtlPid.csv"). }

    set autopilot:yawCtlPid:ki to moi:z * (4.0 / autopilot:yawTs) ^ 2.
    set autopilot:yawCtlPid:kp to 2 * (moi:z * autopilot:yawCtlPid:ki) ^ 0.5.
    set autopilot:yawCtlPid:kd to 0.
    set autopilot:yawCtlPid:maxoutput to availableTorque:z.
    set autopilot:yawCtlPid:minoutput to -availableTorque:z.
    set autopilot:yawCtlPid:setpoint to tgtYawVel.
    local tgtYawTorque to autopilot:yawCtlPid:update(time:seconds, yawAngVel).
    if (autopilot:writeLog) { log pidLogEntry(autopilot:yawCtlPid, autopilot:startTime) to logFileName("YawCtlPid.csv"). }

    local ctl to ship:control.

    local torqueRatios is V(
        tgtPitchTorque / availableTorque:x,
        tgtRollTorque / availableTorque:y,
        tgtYawTorque / availableTorque:z
    ).
    movingAverageVecUpdate(autopilot:controlAvg, torqueRatios).

    local ctlMean is movingAverageVecMean(autopilot:controlAvg).
    set ctl:pitch to ctlMean:x.
    set ctl:roll to ctlMean:y.
    set ctl:yaw to ctlMean:z.   

    wait 0.
}
