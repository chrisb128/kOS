run once "list.ks".
run once optimizers.
run once hyperbolic.

declare function angleBetween {
    local parameter v1.
    local parameter v2.

    local ang is arctan2(v2:z, v2:x) - arctan2(v1:z, v1:x).

    if (ang < 0) {
        set ang to ang + 360.
    }

    return ang.
}

declare function maneuverTime {
    parameter dV.

    local currentStage is currentStage().
    list engines in engs.
    local stageEngines is filter(engs, { parameter item. return item:stage = currentStage. }).

    local f is ship:maxThrust * 1000.  // Engine Thrust (kg * m/s²)
    local p is avgIsp(stageEngines).          // Engine ISP (s)
    if p = 0 return 0.

    local m is ship:mass * 1000.        // Starting mass (kg)
    local e is constant:e.              // Base of natural log
    local g is 9.80665.                 // Gravitational acceleration constant (m/s²)

    RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.
}

declare function currentStage {
    local st is 0.
    local allEngines is list().
    list engines in allEngines.
    for eng in allEngines {
        if eng:stage > st {
            set st to eng:stage.
        }
    }

    return st.
}

declare function avgIsp {
    local parameter engs.

    local totalWeightedIsp is sum(engs, { parameter item. return item:isp * maxFuelMassRate(item).}).
    local totalFlow is sum(engs, { parameter item. return maxFuelMassRate(item).}).
    if totalFlow = 0 return 0.
    return totalWeightedIsp / totalFlow.
}

declare function maxFuelMassRate {
    local parameter eng.
    if (eng:isp = 0) return 0.
    return eng:maxThrust / (eng:isp * constant:g0).
}

function clamp360 {
    parameter t.

    set t to t / 360.0.
    return (t - floor(t)) * 360.0.
}


function vecToPe {
    parameter i is ship:obt:inclination.
    parameter lan is ship:obt:lan.
    parameter w is ship:obt:argumentOfPeriapsis.
    parameter b is ship:obt:body.

    local n is obtNormal(i, lan, b).
    local eqAxis is vecToAn(lan).
    local majAxis is angleAxis(w, n) * eqAxis.
    return majAxis:normalized.
}

function vecToAn {
    parameter lan is ship:obt:lan.

    return r(0,-lan,0) * solarPrimeVector:normalized.
}

function obtNormal {
    parameter i is ship:obt:inclination.
    parameter lan is ship:obt:lan.
    parameter b is ship:obt:body.

    local an is vecToAn(lan).
    LOCAL v IS angleAxis(-i,an) * vCrs(b:angularVel, an):normalized.
    return -vCrs(v, an).
}

function smaFromApPe {
    parameter Ra.
    parameter Rp.

    return (Ra + Rp) / 2.
}

function eFromApPe {
    parameter Ra.
    parameter Rp.
  
    local a is smaFromApPe(Ra, Rp).
    local b is sqrt(Ra * Rp).

    return sqrt(1 - (b^2/a^2)).
}

global function distanceAtTime {
    parameter t, o1, o2.

    return (positionAt(o2, t) - positionAt(o1, t)):mag.
}
