run once logging.
run once moving_average.
run once torque.
run once pidloop2.
run once torque_pi.

local epsilon is 10^(-16).
local writeLog is true.

global function attitudeController {
  
    local pitchPI is newTorquePI().
    local rollPI is newTorquePI().
    local yawPI is newTorquePI().

    local rateScale is 1.0.

    local ratePScale is 1.0.
    local rateIScale is 0.05.
    local rateDScale is 2.0.

    local pitchScale is 1.0.
    local rollScale is 0.5.
    local yawScale is 1.0.

    local pitchRatePI is pidLoop2(pitchScale * rateScale * ratePScale, pitchScale * rateScale * rateIScale, pitchScale * rateScale * rateDScale, true).
    set pitchRatePI:setpoint to 0.
    local rollRatePI is pidLoop2(rollScale * rateScale * ratePScale, rollScale * rateScale * rateIScale, rollScale * rateScale * rateDScale, true).
    set rollRatePI:setpoint to 0.
    local yawRatePI is pidLoop2(yawScale * rateScale * ratePScale, yawScale * rateScale * rateIScale, yawScale * rateScale * rateDScale, true).
    set yawRatePI:setpoint to 0.

    local this is lexicon(
        "pitchPI", pitchPI,
        "rollPI", rollPI,
        "yawPI", yawPI,
        "pitchRatePI", pitchRatePI,
        "rollRatePI", rollRatePI,
        "yawRatePI", yawRatePI,

        "actuation", V(0,0,0),
        "targetTorque", V(0,0,0),
        "omega", V(0,0,0),

        "phiTotal", 0.0,
        "phiVector", V(0,0,0),
        "targetOmega", V(0,0,0),
        "maxOmega", V(0,0,0),
        "controlTorque", V(0,0,0),
        "axis", V(1,1,1),
        
        "stoppingTimePitch", 1.0,
        "stoppingTimeRoll", 0.25,
        "stoppingTimeYaw", 1.0,

        "target", ship:facing,

        "startTime", time:seconds,
        "writeLog", writeLog
    ).

    local reset is { parameter _this. attitudeReset(_this).}.
    set this:reset to reset:bind(this).

    local drive is { parameter _this. return attitudeDrive(_this).}.
    set this:drive to drive:bind(this).

    local initLogs is { parameter _this. attitudeInitLogs(_this).}.
    set this:initLogs to initLogs:bind(this).
    
    local writeLogs is { parameter _this, startTime. attitudeWriteLogs(_this, startTime).}.
    set this:writeLogs to writeLogs:bind(this).

    return this.
}

local function attitudeReset {
    parameter this.

    this:pitchPi:pid:reset().
    this:rollPi:pid:reset().
    this:yawPi:pid:reset().

    this:pitchRatePi:reset().
    this:rollRatePi:reset().
    this:yawRatePi:reset().
}

local function attitudeDrive {
    parameter this.
    
    _updateLocalState(this).
    _updatePredictionPi(this).
    
    return _getControls(this).
}

local function _updateLocalState {
    parameter this.

    set this:omega to -ship:angularvel.
    set this:controlTorque to getAvailableTorque().
    set this:moi to momentOfInertia().
}

local function _updatePredictionPi {
    parameter this.
    
    local phiVector is _phiVector(this).
    set this:phiVector to phiVector.

    set this:maxOmega:x to ((this:controlTorque:x * this:stoppingTimePitch) / this:moi:x).
    set this:maxOmega:y to ((this:controlTorque:y * this:stoppingTimeRoll) / this:moi:y).
    set this:maxOmega:z to ((this:controlTorque:z * this:stoppingTimeYaw) / this:moi:z).
    
    set this:targetOmega:x to this:pitchRatePi:update(time:seconds, -phiVector:x, 0, this:maxOmega:x).
    set this:targetOmega:y to this:rollRatePi:update(time:seconds, -phiVector:y, 0, this:maxOmega:y).
    set this:targetOmega:z to this:yawRatePi:update(time:seconds, -phiVector:z, 0, this:maxOmega:z).

    set this:targetTorque:x to this:pitchPi:update(this:omega:x, this:targetOmega:x, this:moi:x, this:controlTorque:x).
    set this:targetTorque:y to this:rollPi:update(this:omega:y, this:targetOmega:y, this:moi:y, this:controlTorque:y).
    set this:targetTorque:z to this:yawPi:update(this:omega:z, this:targetOmega:z, this:moi:z, this:controlTorque:z).
}

local function _getControls {
    parameter this.
    
    local clampX is max(abs(this:actuation:x), 0.005) * 2.
    set this:actuation:x to 0.
    if (this:controlTorque:x <> 0) {
        set this:actuation:x to this:targetTorque:x / this:controlTorque:x.
        if (abs(this:actuation:x) < epsilon) {
            set this:actuation:x to 0.
        }
    }
    set this:actuation:x to max(min(this:actuation:x, clampX), -clampX).
    
    local clampY is max(abs(this:actuation:y), 0.005) * 2.
    set this:actuation:y to 0.
    if (this:controlTorque:y <> 0) {
        set this:actuation:y to this:targetTorque:y / this:controlTorque:y.
        if (abs(this:actuation:y) < epsilon) {
            set this:actuation:y to 0.
        }
    }
    set this:actuation:y to max(min(this:actuation:y, clampY), -clampY).
        
    local clampZ is max(abs(this:actuation:z), 0.005) * 2.
    set this:actuation:z to 0.
    if (this:controlTorque:z <> 0) {
        set this:actuation:z to this:targetTorque:z / this:controlTorque:z.
        if (abs(this:actuation:z) < epsilon) {
            set this:actuation:z to 0.
        }
    }
    set this:actuation:z to max(min(this:actuation:z, clampZ), -clampZ).

    set this:actuation to V(this:actuation:x * this:axis:x, this:actuation:y * this:axis:y, this:actuation:z * this:axis:z).
    
    return this:actuation.
}

local function _phiVector {
    parameter this.

    local phi is V(0,0,0).

    local vesselTop is ship:facing:upvector.
    local vesselForward is ship:facing:forevector.
    local vesselStarboard is ship:facing:starvector.

    local targetForward is this:target:forevector.
    local targetTop is this:target:upvector.

    set phi:x to vAng(vesselForward, vXcl(vesselStarboard, targetForward)) * constant:degtorad.
    if (vAng(vesselTop, vXcl(vesselStarboard, targetForward)) > 90) {
        set phi:x to -phi:x.
    }
    set phi:y to vAng(vesselTop, vXcl(vesselForward, targetTop)) * constant:degtorad.
    if (vAng(vesselStarboard, vXcl(vesselForward, targetTop)) > 90) {
        set phi:y to -phi:y.
    }
    set phi:z to vAng(vesselForward, vXcl(vesselTop, targetForward)) * constant:degtorad.
    if (vAng(vesselStarboard, vXcl(vesselTop, targetForward)) > 90) {
        set phi:z to -phi:z.
    }
    

    return phi.
}


local function attitudeInitLogs {
    parameter this.
    
    if this:writeLog {
        initPidLog("PitchPi.csv").
        initPidLog("RollPi.csv").
        initPidLog("YawPi.csv").
        
        initPidLog("PitchRatePi.csv").
        initPidLog("RollRatePi.csv").
        initPidLog("YawRatePi.csv").
    }
}

local function attitudeWriteLogs {
    parameter this, startTime.

    if this:writeLog {
        log pidLogEntry(this:pitchPi:pid, startTime) to logFileName("PitchPi.csv").
        log pidLogEntry(this:rollPi:pid, startTime) to logFileName("RollPi.csv").
        log pidLogEntry(this:yawPi:pid, startTime) to logFileName("YawPi.csv").
        
        log pidLogEntry(this:pitchRatePi, startTime) to logFileName("PitchRatePi.csv").
        log pidLogEntry(this:rollRatePi, startTime) to logFileName("RollRatePi.csv").
        log pidLogEntry(this:yawRatePi, startTime) to logFileName("YawRatePi.csv").
    }
}
