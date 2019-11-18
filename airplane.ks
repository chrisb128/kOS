run once logging.

local writeLog is true.

global function initAutopilot {

    // input - potential + kinetic energy
    // output - throttle ctl
    local throttlePid is pidLoop(0.075, 0.000, 0.0175, 0, 1).

    // input - potential / potential + kinetic energy
    // output - target pitch
    local pitchPid is pidLoop(100, 0, 20, -30, 30).

    // input - pitch
    // output - target pitch vel
    local pitchRotPid is pidLoop(0.3, 0.0015, 0.001, -2, 2).

    // input - pitch vel
    // output - pitch ctl
    local pitchCtlPid is pidLoop(0.5, 0.05, 0.000, -1, 1).

    // input - heading err
    // output - roll angle
    local rollPid is pidLoop(-2, -0.0, -0.1, -45, 45).

    // input - roll
    // output - target roll vel
    local rollRotPid is pidLoop(-0.06, -0.00, -0.04, -15, 15).

    // input - roll vel
    // output - roll ctl
    local rollCtlPid is pidLoop(0.025, 0.005, 0.00, -1, 1).

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

global function flightPlan {
    parameter cruiseSpeed.
    parameter cruiseAltitude.
    parameter waypoints.
    parameter destination.

    return lexicon(
        "cruiseSpeed", cruiseSpeed,
        "cruiseAltitude", cruiseAltitude,
        "waypoints", waypoints,
        "destination", destination
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

    local headingErr is currentHeading - targetHeading.
    if abs((currentHeading + 360) - targetHeading) < abs(headingErr) {
        set headingErr to (currentHeading + 360) - targetHeading.
    }

    if abs(headingErr) > 180 {
        set headingErr to -headingErr.
    }

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
    set ctl:pitch to ctlPitch * cos(shipRoll) + ctlYaw * sin(shipRoll).
    set ctl:yaw to ctlYaw * cos(shipRoll) + ctlPitch * sin(shipRoll).

    wait 0.
}

global function initNavigator {
    parameter plan.

    return lexicon(
        "plan", (plan),
        "autopilot", initAutopilot(),
        "target", ship:geoposition,
        "currentWaypoint", (-1),
        "mode", "idle",
        "speed", 0,
        "heading", getShipHeading(),
        "altitude", ship:altitude,
        "startPoint", ship:geoposition,
        "liftPoint", ship:geoposition
    ).
}

local function closeTo {
    parameter target.
    local closeDistance is 1000.
    return distanceTo(target) < closeDistance.
}

global function navigatorSetWaypoint {
    parameter nav.

    local plan is nav:plan.
    if (nav:mode = "cruise") {
        if  (nav:currentWaypoint < 0) {
            set nav:currentWaypoint to 0.
            set nav:target to plan:waypoints[nav:currentWaypoint].
        } else if (nav:currentWaypoint < plan:waypoints:length and closeTo(nav:target)) {
            set nav:currentWaypoint to nav:currentWaypoint + 1.

            if (nav:currentWaypoint < plan:waypoints:length) {
                set nav:target to plan:waypoints[nav:currentWaypoint].
            } else {
                set nav:target to plan:destination:approach.
            }
        }
    } else if (nav:mode = "approach") {
        if (nav:currentWaypoint = plan:waypoints:length) {
            set nav:target to plan:destination:approach.
        }

        if (closeTo(plan:destination:approach) and nav:currentWaypoint = plan:waypoints:length) {
            set nav:target to plan:destination:start.
            set nav:currentWaypoint to -1.
        }
    }
}

global function navigatorUpdateFlightMode {
    parameter nav.

    local plan is nav:plan.


    if (nav:mode = "ascend"
        and abs(plan:cruiseAltitude - ship:altitude) < 10) {
        set nav:mode to "cruise".
    }

    if (nav:mode = "cruise"
        and nav:currentWaypoint = plan:waypoints:length
        and closeTo(plan:destination:approach)) {
        set nav:mode to "approach".
    } else if (nav:mode = "approach") {
        if (distanceTo(plan:destination:start) < 500) {
            set nav:mode to "land".
        }
    } else if (nav:mode = "land") {
        if (ship:bounds:bottomaltradar < 1) {
            set nav:mode to "break".
        }
    } else if (nav:mode = "break") {
        if (ship:velocity:surface:mag < 0.1) {
            set nav:mode to "idle".
        }
    }
}

global function navigatorSetAutopilotParams {
    parameter nav.
    local plan is nav:plan.

    if (nav:mode = "ascend") {
        if (ship:bounds:bottomaltradar < 1) {
            nav:autopilot:pitchPid:reset().
        }

        setAutopilotPitchRange(nav:autopilot,
            max(-20.0, min(1, 1-(ship:bounds:bottomaltradar / 20))),
            min(20.0, max(4, ship:bounds:bottomaltradar / 20))).

    } else if (nav:mode = "cruise") {
        setAutopilotPitchRange(nav:autopilot, -20, 20).

    } else if (nav:mode = "approach") {

        setAutopilotPitchRange(nav:autopilot,
            max(-20.0, min(1, 1-(ship:bounds:bottomaltradar / 20))),
            min(20.0, max(4, ship:bounds:bottomaltradar / 20))).

    } else if (nav:mode = "land") {
        if (ship:bounds:bottomaltradar < 1) {
            setAutopilotPitchRange(nav:autopilot, 0, 0).
        }
    }
}

global function navigatorSetTargets {
    parameter nav.
    local plan is nav:plan.

    if (nav:mode = "ascend") {
        set nav:heading to getShipHeading().

        if (ship:bounds:bottomaltradar < 1) {
            set nav:liftPoint to ship:geoposition.
        }

        set nav:speed to max(20, min(plan:cruiseSpeed, log10(1.4 + distanceTo(nav:startPoint) / 600) * plan:cruiseSpeed)).
        set nav:altitude to max(nav:liftPoint:terrainHeight, min(plan:cruiseAltitude, (distanceTo(nav:liftPoint) / 8) + nav:liftPoint:terrainHeight)).
    }
    else if (nav:mode = "cruise") {
        set nav:heading to nav:target:heading.
        set nav:altitude to plan:cruiseAltitude.
    }
    else if (nav:mode = "approach") {
        set nav:heading to nav:target:heading.
        set nav:altitude to min(plan:cruiseAltitude, max(plan:destination:start:terrainheight, plan:destination:start:terrainheight + distanceTo(plan:destination:start) / 10)).
        set nav:speed to max(50, min(100, distanceTo(plan:destination:start) / 40)).

        if (not closeTo(plan:destination:start)) {
            local correction is (plan:destination:end:heading - plan:destination:start:heading) * -10.
            set nav:heading to nav:heading + correction.
        }

        if (distanceTo(plan:destination:start) < 500) {
            set nav:target to plan:destination:end.
            set nav:altitude to plan:destination:start:terrainheight.
        }
    } else if (nav:mode = "land") {
        set nav:heading to nav:destination:end:heading.
        set nav:speed to min(nav:speed, max(50, ship:bounds:bottomaltradar)).

    } else if (nav:mode = "break") {
        set nav:heading to getShipHeading().
        set nav:speed to 0.
    }
}

global function navigatorSetShipControls {
    parameter nav.

    if (nav:mode = "ascend") {
        brakes off.
        sas off.
        if (ship:bounds:bottomaltradar > 10) {
            gear off.
        }
    }
    if (nav:mode = "approach") {
        if (distanceTo(nav:plan:destination:start) < 500) {
            gear on.
        }
    }
    if (nav:mode = "idle") {
        unlock all.
        sas on.
        brakes on.
    }
}