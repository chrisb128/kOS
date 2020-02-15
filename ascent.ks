run once logging.
run once math.

declare function ascent {
    parameter options.

    local targetAp is options:targetAp.
    
    set doAutoWarp to true.
    set accelerationLimit to 15.
    set pressurePhaseOut to ship:body:atm:height * 0.35.
    set turnStart to ship:body:atm:height * 0.015.
    set turnEnd to targetAp * 0.9.

    local function ascentCurve {
        parameter p.

        local s is (p + 0.06) * 14.
        return 1 - p ^ (1 / s).
    }


    local steerLock to heading(90, 90, options:roll).
    local throttleLock to 1.

    lock steering to steerLock.
    lock throttle to throttleLock.
    
    until ship:maxThrust > 0 {
        wait 0.5.
        stage.
    }
    
    until ship:apoapsis > targetAp {
        local limitedThrottle is min(accelerationLimit / (ship:availableThrust / ship:mass), 1).
        local throttleAdjust is max(0, ((ship:altitude - pressurePhaseOut) / 5000) * (1 - limitedThrottle)).
        set limitedThrottle to min(1, limitedThrottle + throttleAdjust).

        set throttleLock to limitedThrottle.

        if ship:altitude < turnStart {
            set steerLock to heading(90, 90).

            logStatus("Ascent").
            logInfo("Ap: " + round(ship:apoapsis, 0), 1).
        }
        else {
            local progress to ((ship:altitude - turnStart) / (turnEnd - turnStart)).
            local pitch to ascentCurve(progress) * 80.
            set steerLock to heading(90, pitch).

            logStatus("Gravity turn").
            logInfo("Ap: " + round(ship:apoapsis, 0), 1).
            logInfo("Pitch: " + round(pitch, 0), 2).
        }.
    }.

    set throttleLock to 0.

    if (ship:obt:body:atm:height > 0) {
        logStatus("Coasting to edge of atmosphere").

        if (doAutoWarp) {
            set warpMode to "PHYSICS".
            set warp to 3.
        }

        until ship:altitude > ship:obt:body:atm:height {
            logInfo("Ap: " + round(ship:apoapsis, 0), 1).
            set steerLock to ship:prograde.

            if ship:apoapsis < targetAp * 0.999 {
                logStatus("Adjusting apoapsis").
                if (doAutoWarp) {
                    set warp to 0.
                }
                set throttleLock to 0.1.
            } else if (throttleLock > 0 and ship:apoapsis > targetAp * 1.001) {    
                logStatus("Coasting to edge of atmosphere").        
                if (doAutoWarp) {
                    set warp to 3.
                }
                set throttleLock to 0.
            }
        }
        
        if (doAutoWarp) {
            set warp to 0.
        }
    }

    unlock steering.
}
