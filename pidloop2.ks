global function pidLoop2 {
    parameter kp, ki, kd, extraUnwind is false, minOutput is 0, maxOutput is 0.

    local this is lexicon(
        "kp", kp,
        "ki", ki,
        "kd", kd,
        "input", 0,
        "setPoint", 0,
        "errorSum", 0,
        "changeRate", 0,
        "pTerm", 0,
        "iTerm", 0,
        "dTerm", 0,
        "minOutput", minOutput,
        "maxOutput", maxOutput,

        "prevTime", -1,

        "extraUnwind", extraUnwind,
        "unwinding", false,
        "loopKi", ki
    ).


    local update is { parameter _this, t, input, setPoint, maxOut. return pidUpdate(_this, t, input, setPoint, maxOut).}.
    set this:update to update:bind(this).

    local setKp is { parameter _this, kp.  set _this:kp to kp.}.
    set this:setKp to setKp:bind(this).
    
    local setKi is { parameter _this, ki.  set _this:ki to ki. set _this:loopKi to ki. }.
    set this:setKi to setKi:bind(this).
    
    local setKd is { parameter _this, kd.  set _this:kd to kd.}.
    set this:setKd to setKd:bind(this).

    local reset is { parameter _this. set _this:errorSum to 0.  set _this:iTerm to 0. }.
    set this:reset to reset:bind(this).

    return this.
}

local function pidUpdate {
    parameter this, t, input, setPoint, maxOut.
    
    set this:maxOutput to maxOut.
    set this:minOutput to -maxOut.

    local error is setPoint - input.
    local pTerm is error * this:kp.
    local iTerm is 0.
    local dTerm is 0.
    local dt is 0.10.

    if (this:prevTime > 0) {
        set dt to t - this:prevTime.
    }

    if (this:loopKi <> 0) {
        if (this:extraUnwind) {
            if (signOf(error) <> signOf(this:errorSum)) {
                if (not this:unwinding) {
                    set this:loopKi to this:loopKi * 2.
                    set this:unwinding to true.
                }
            } else if (this:unwinding) {
                set this:loopKi to this:ki.
                set this:unwinding to false.
            }
        }
        set iTerm to this:iTerm + error * dt * this:loopKi.
    }
    set this:changeRate to (input - this:input) / dt.
    if (this:kd <> 0) {
        set dTerm to -this:changeRate * this:kd.
    }

    set this:output to pTerm + iTerm + dTerm.

    if (this:output > this:maxOutput) {
        set this:output to this:maxOutput.
        if (this:loopKi <> 0) {
            set iTerm to this:output - min(pTerm + dTerm, this:maxOutput).
        }
    }
    if (this:output < this:minOutput) {
        set this:output to this:minOutput.
        if (this:loopKi <> 0) {
            set iTerm to this:output - max(pTerm + dTerm, this:minOutput).
        }
    }

    set this:input to input.
    set this:setPoint to setPoint.
    set this:error to error.
    set this:pTerm to pTerm.
    set this:iTerm to iTerm.
    set this:dTerm to dTerm.
    set this:prevTime to t.

    if (this:loopKi <> 0) {
        set this:errorSum to iTerm / this:loopKi.
    } else {
        set this:errorSum to 0.
    }

    return this:output.
}

local function signOf {
    parameter x.
    if x = 0 { return 0. }
    return x / abs(x).
}.