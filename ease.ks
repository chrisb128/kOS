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

        set _this:targetValue to targetValue.
        set _this:startValue to currentValue.
        set _this:targetSetTime to time:seconds.
    }.
    set this["setTargetValue"] to setTargetValue:bind(this).
    
    return this.
}