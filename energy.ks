run once logging.
local writeLog to true.

global function newEnergyController {
    // input - potential + kinetic energy
    // output - throttle ctl
    local throttlePid is pidLoop(0.005, 0.000, 0.001, 0, 1).

    // input - potential / potential + kinetic energy
    // output - target pitch
    local pitchPid is pidLoop(50, 10, 0, -15, 15).

    if (writeLog) {
        if exists(logFileName("ThrottlePid.csv")) { deletePath(logFileName("ThrottlePid.csv")). }
        log pidLogHeader() to logFileName("ThrottlePid.csv").

        if exists(logFileName("PitchPid.csv")) { deletePath(logFileName("PitchPid.csv")). }
        log pidLogHeader() to logFileName("PitchPid.csv").
    }

    return lexicon(
        "throttlePid", throttlePid,
        "pitchPid", pitchPid,
        "writeLog", writeLog,
        "startTime", time:seconds
    ).
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

global function energyGetControls {
    parameter ctlr.
    parameter targetAltitude.
    parameter targetSpeed.

    local currentPotential is potentialEnergy(ship:altitude).
    local currentKinetic is kineticEnergy(ship:altitude, ship:velocity:surface:mag).
    local currentTotal is (currentPotential + currentKinetic) / ship:mass.
    local currentRatio is currentPotential / currentKinetic.

    local desiredPotential is potentialEnergy(targetAltitude).
    local desiredKinetic is kineticEnergy(targetAltitude, targetSpeed).
    local desiredTotal is (desiredPotential + desiredKinetic) / ship:mass.
    local desiredRatio is desiredPotential / desiredKinetic.

    local totalError is desiredTotal - currentTotal.
    local ratioError is desiredRatio - currentRatio.

    logInfo("Target Speed   : " + round(targetSpeed, 3), 11).
    logInfo("Target Altitude: " + round(targetAltitude, 3), 12).
    logInfo("Target Total   : " + round(desiredTotal, 3), 13).
    logInfo("Target Ratio   : " + round(desiredRatio, 3), 14).
    
    logInfo("Speed Err      : " + round(targetSpeed - ship:velocity:surface:mag, 3), 15).
    logInfo("Altitude Err   : " + round(targetAltitude - ship:altitude, 3), 16).
    logInfo("Total Err      : " + round(totalError, 3), 17).
    logInfo("Ratio Err      : " + round(ratioError, 3), 18).

    set ctlr:throttlePid:setpoint to 0.
    local throtLock is ctlr:throttlePid:update(time:seconds, -totalError).
    if (ctlr:writeLog) { log pidLogEntry(ctlr:throttlePid, ctlr:startTime) to logFileName("ThrottlePid.csv"). }

    set ctlr:pitchPid:setpoint to 0.
    local targetPitch to ctlr:pitchPid:update(time:seconds, -ratioError).
    if (ctlr:writeLog) { log pidLogEntry(ctlr:pitchPid, ctlr:startTime) to logFileName("PitchPid.csv"). }

    return lexicon("throttle", throtLock, "pitch", targetPitch).
}