run once logging.
run once time.

local debug is false.
local logFile is "0:/airplane_log.csv".

brakes on.
local targetAltitude is 3000. // m
local targetSpeed is 250.     // m/s

local throtLock to 0.5.
lock throttle to throtLock.

set ctl to ship:control.

local throttlePid is pidLoop(1.2, 0.1, 2.5).
set throttlePid:maxoutput to 1.
set throttlePid:minoutput to 0.
set throttlePid:setpoint to targetSpeed.

// output - target vertical speed
local vSpeedPid is pidLoop(0.1, 0.0, 0.0).
set vSpeedPid:maxoutput to 50.
set vSpeedPid:minoutput to -50.
set vSpeedPid:setpoint to targetAltitude.

// output - target pitch

local pitchPid is pidLoop(0.6, 0.1, 0.0).
set pitchPid:maxoutput to 15.
set pitchPid:minoutput to -15.
set pitchPid:setpoint to 0.

// output - pitch ctl
local pitchCtlPid is pidLoop(0.5, 0.1, 0.1).
set pitchCtlPid:maxoutput to 1.
set pitchCtlPid:minoutput to -1.
set pitchCtlPid:setpoint to 0.

local rollPid is pidLoop(1, 0, 0).
set rollPid:maxoutput to 1.
set rollPid:minoutput to -1.
set rollPid:setpoint to 0.

local yawPid is pidLoop(1, 0, 0).
set yawPid:maxoutput to 1.
set yawPid:minoutput to -1.
set yawPid:setpoint to 0.

countdown(3).

until ship:maxThrust > 0 {
    stage.
}

brakes off.

on (ship:altitude > 100) {
    gear off.
}

if exists(logFile) {
    local f is open(logFile).
    f:clear().
}

log "Time,Throttle,Altitude,Target Altitude,Vertical Speed,Target Vertical Speed,Pitch,Target Pitch,Pitch Ctl" to logFile.

until false {
    set throtLock to throttlePid:update(time:seconds, ship:velocity:surface:mag).

    local tgtVertSpeed is vSpeedPid:update(time:seconds, ship:altitude).
    set pitchPid:setpoint to tgtVertSpeed.

    local tgtPitch to pitchPid:update(time:seconds, ship:verticalspeed).
    set pitchCtlPid:setpoint to tgtPitch.

    local shipPitch is 90 - vAng(ship:up:forevector, ship:facing:forevector).
    local tgtCtlPitch to pitchCtlPid:update(time:seconds, shipPitch).
    set ctl:pitch to tgtCtlPitch.

    local newRoll to rollPid:update(time:seconds, ship:direction:roll).
    set ctl:roll to newRoll.
    local newYaw to yawPid:update(time:seconds, ship:direction:yaw).
    set ctl:yaw to newYaw.

    log time:seconds + "," + throtLock + "," + ship:altitude + "," + targetAltitude + "," + ship:verticalspeed + "," + tgtVertSpeed + "," + shipPitch + "," + tgtPitch + "," + tgtCtlPitch to logFile.

    if debug {
        hudtext(round(ship:verticalspeed, 2) + "," + round(tgtVertSpeed, 2) + "," + round(shipPitch, 2) + "," + round(tgtPitch, 2) + "," + round(tgtCtlPitch, 2),
            1, 3, 12, red, false).
    }

    wait 0.
}