global function newVelocityEase {
    parameter velocityToEase.
    
    local this is lexicon(
        "velToEase", velocityToEase,
        "targetValue", 0,
        "targetSetTime", 0,
        "startValue", 0
    ).

    local getCurrentValue is {
        parameter _this.

        if _this:targetSetTime = 0 {
            return 0.
        }

        local currentVal is _this:velToEase * (time:seconds - _this:targetSetTime).

        if (_this:targetValue > _this:startValue) {
            return min(_this:targetValue, _this:startValue + currentVal).
        } else {
            return max(_this:targetValue, _this:startValue - currentVal).
        }
    }.
    set this["getCurrentValue"] to getCurrentValue:bind(this).

    local setTargetValue is {
        parameter _this.
        parameter targetValue.
        parameter currentValue.
        
        if (targetValue = _this:targetValue) {
            return.
        }

        set _this:targetValue to targetValue.
        set _this:startValue to currentValue.
        set _this:targetSetTime to time:seconds.
    }.
    set this["setTargetValue"] to setTargetValue:bind(this).
    
    return this.
}

local function clamp360 {
    parameter t.

    set t to t / 360.0.
    return (t - floor(t)) * 360.0.
}

global function newHeadingEase {
    parameter velocityToEase.

    
    local this is lexicon(
        "velToEase", velocityToEase,
        "targetValue", 0,
        "targetSetTime", 0,
        "startValue", 0
    ).
    
    local getCurrentValue is {
        parameter _this.

        if _this:targetSetTime = 0 {
            return 0.
        }

        local currentVel is _this:velToEase * (time:seconds - _this:targetSetTime).

        if (_this:targetValue > _this:startValue) {
            return clamp360(min(_this:targetValue, _this:startValue + currentVel)).
        } else {
            return clamp360(max(_this:targetValue, _this:startValue - currentVel)).
        }
    }.
    set this["getCurrentValue"] to getCurrentValue:bind(this).

    local setTargetValue is {
        parameter _this.
        parameter targetValue.
        parameter currentValue.

        if (targetValue = _this:targetValue) {
            return.
        }

        set _this:targetValue to targetValue.
        set _this:startValue to currentValue.
        set _this:targetSetTime to time:seconds.
    }.
    set this["setTargetValue"] to setTargetValue:bind(this).
    
    return this.
}