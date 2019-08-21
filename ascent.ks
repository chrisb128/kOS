run once logging.
run once math.

declare function ascent {
    parameter targetAp.

    local steerLock to heading(90, 90).
    local throttleLock to 1.

    lock steering to steerLock.
    lock throttle to throttleLock.
    
    until ship:maxThrust > 0 {
        wait 0.5.
        stage.
    }

    set turnStart to ship:body:atm:height * 0.015.
    set turnEnd to targetAp * 0.9.

    local function ascentCurve {
        parameter p.

        local s is (p + 0.08) * 9.
        return 1 - p ^ (1 / s).
    }

    until ship:apoapsis > targetAp {
        local limitedThrottle is min(20 / (ship:availableThrust / ship:mass), 1).
        
        if ship:altitude > ship:body:atm:height * 0.35 {
            set limitedThrottle to 1.
        } 

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

    logStatus("Coasting to edge of atmosphere").

    set warpMode to "PHYSICS".
    SET warp to 3.

    until ship:altitude > ship:obt:body:atm:height {
        set steerLock to ship:prograde.
    }    
    
    set warp to 0.

    unlock steering.
}

declare function stageFlameout {
    local lastStage is 0.
    list engines in engineList.
    
    for en in engineList {
        if en:stage > lastStage {
            set lastStage to en:stage.
        }
    }

    for en in engineList {
        if en:stage = lastStage {
            if en:flameout {
                return true.
            }
        }
    }
}.