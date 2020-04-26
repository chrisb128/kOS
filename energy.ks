run once logging.
local writeLog to true.

global function newEnergyController {

    // input - potential + kinetic energy
    // output - throttle ctl
    local throttlePid is pidLoop(0.01, 0.001, 0.01, 0, 1).

    // input - potential / kinetic energy
    // output - target pitch
    local pitchPid is pidLoop(20, 0.05, 0, -20, 20).


    local this is lexicon(
        "throttlePid", throttlePid,
        "pitchPid", pitchPid,
        "currentTotal", 0,
        "currentRatio", 0,
        "desiredTotal", 0,
        "desiredRatio", 0,
        "writeLog", writeLog,
        "startTime", time:seconds
    ).

    local initLogs is { parameter _this. energyInitLogs(_this).}.
    set this:initLogs to initLogs:bind(this).

    local writeLogs is { parameter _this, startTime. energyWriteLogs(_this, startTime).}.
    set this:writeLogs to writeLogs:bind(this).

    local getControls is { parameter _this, tgtAlt, tgtSpeed. return energyGetControls(_this, tgtAlt, tgtSpeed).}.
    set this:getControls to getControls:bind(this).

    local setPitchRange is { parameter _this, min, max. return energySetPitchRange(_this, min, max). }.
    set this:setPitchRange to setPitchRange:bind(this).

    return this.
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

local function energyGetControls {
    parameter this.
    parameter targetAltitude.
    parameter targetSpeed.

    local currentPotential is potentialEnergy(ship:altitude).
    local currentKinetic is kineticEnergy(ship:altitude, ship:velocity:surface:mag).
    set this:currentTotal to (currentPotential + currentKinetic) / ship:mass.
    set this:currentRatio to currentPotential / currentKinetic.

    local desiredPotential is potentialEnergy(targetAltitude).
    local desiredKinetic is kineticEnergy(targetAltitude, targetSpeed).
    set this:desiredTotal to (desiredPotential + desiredKinetic) / ship:mass.
    set this:desiredRatio to desiredPotential / desiredKinetic.

    local totalError is this:desiredTotal - this:currentTotal.
    local ratioError is this:desiredRatio - this:currentRatio.

    set this:throttlePid:setpoint to 0.
    local throtLock is this:throttlePid:update(time:seconds, -totalError).

    set this:pitchPid:setpoint to 0.
    local targetPitch to this:pitchPid:update(time:seconds, -ratioError).
    
    return lexicon("throttle", throtLock, "pitch", targetPitch).
}

local function energySetPitchRange {
    parameter this, min, max.

    set this:pitchPid:minOutput to min.
    set this:pitchPid:maxOutput to max.
}

local function energyInitLogs {
    parameter this.
    
    if (writeLog) {
        initPidLog("ThrottlePid.csv").
        initPidLog("EnergyPitchPid.csv").
    }
}

local function energyWriteLogs {
    parameter this, startTime.

    if (this:writeLog) { log pidLogEntry(this:throttlePid, startTime) to logFileName("ThrottlePid.csv"). }
    if (this:writeLog) { log pidLogEntry(this:pitchPid, startTime) to logFileName("EnergyPitchPid.csv"). }
}

