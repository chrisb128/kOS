run once "list.ks".
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

declare function timeToRelativeAngle {
    local parameter tgt.
    local parameter src.
    local parameter org.
    local parameter angle.
    
    local dW TO relativeAngVel(tgt, src).
    
    local t is time:seconds.
    local currentAngle is angleBetween(tgt:orbit:position - org:position, src:orbit:position - org:position).
    local angleToWait to (angle - currentAngle).

    if (dW < 0) {
        set angleToWait to 360 - angleToWait.
    }

    if (angleToWait < 0) {
        set angleToWait to angleToWait + 360.
    }

    return angleToWait / dW + t.
}

declare function relativeAngVel {
    local parameter a.
    local parameter b.
    local wA TO 360 / a:orbit:period.
    local wB TO 360 / b:orbit:period.
    return wB - wA.
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

function meanAnomalyFromEccentricAnomaly {
    parameter E.
    parameter ec.

    if ec < 1 {
        return E + ec * constant:radtodeg * sin(E).
    } else {
        return E + ec * constant:radtodeg * sinh(E).
    }
}

function eccentricAnomalyFromMeanAnomaly {
    parameter M. // mean anomaly
    parameter ec. // eccentricity

    local E is 0.
    set M to clamp360(M).

    if (ec < 0.8) { set E to M. } 
    else { set E to 180. }

    if ec < 1 {    
        return newtonSolver(
            { parameter x. return x - ec * constant:radtodeg * sin(x) - M. },
            { parameter x. return -ec * constant:radtodeg * cos(x) + 1. },
            E
        ).
    } else {
        // hopefully a good guess
        return newtonSolver(
            { parameter x. return ec * constant:radtodeg * sinh(x) - x - M. },
            { parameter x. return ec * constant:radtodeg * cosh(x) - 1. },
            E
        ).
    }
}

function newtonSolver {
    parameter f.
    parameter df.
    parameter guess.
    parameter d is 0.00001.
    parameter c is 30.

    local err is d + 1.
    local x0 is guess.
    for n in range(c + 1) {
        if (abs(err) <= d) { break. }
        if (n >= c) { print "!!! SOLVER OVERRUN !!!" at (0, terminal:height - 2). break. }

        local x1 is x0 - f(x0)/df(x0).
        set err to x1 - x0.
        set x0 to x1.
    }

    return x0.
}

function trueAnomalyFromMeanAnomaly {
    parameter M. // mean anomaly
    parameter e. // eccentricity

    return M 
        + (2*e - (0.25*e^3)) * sin(M) 
        + (1.25*e^2) * sin(2*M) 
        + ((13/12)*e^3) * sin(3*M).
        // could add more terms for better accuracy, but probably not necessary
}

function meanAnomalyFromTrueAnomaly {
    parameter v. // true anomaly
    parameter e. // eccentricity

    return v 
        - 2*e*sin(v) 
        + (0.75*e^2 + 0.125*e^4)*sin(2*v) 
        - ((1/3)*e^3*sin(3*v))
        + ((5/32)*e^4*sin(4*v)).
        // could add more terms for better accuracy, but probably not necessary
}

function radiusFromTrueAnomaly {
    parameter v. // true anomaly
    parameter e. // eccentricity
    parameter a. // semi-major axis

    return a * ( (1-e^2) / ( 1+(e*cos(v)) ) ).
}

function eccentricAnomalyFromTrueAnomaly {
    parameter v. // true anomaly
    parameter e. // eccentricity

    // not sure this works?
    return arctan2( 1 + e*cos(v), cos(v) + e ).
}

function trueAnomalyFromEccentricAnomaly {
    parameter Et. // eccentric anomaly
    parameter e.  // eccentricity

    if (e < 1) {
        return 2 * arctan(sqrt((1 + e)/(1 - e)) * tan(Et / 2)).
    } else {
        return 2 * arctan(sqrt((e + 1)/(e - 1)) * tanh(Et / 2)).
    }
}

function meanMotion {
    parameter obt.
    return sqrt(obt:body:mu / abs(obt:semimajoraxis)^3) * constant:radtodeg.
}

function meanAnomalyAtTime {
    parameter obt.
    parameter t.

    local dt is t - obt:epoch.
    local n is meanMotion(obt).
    local Mt is obt:meanAnomalyAtEpoch + (n * dt).
    
    return clamp360(Mt).
}

function  trueAnomalyAtTime {
    parameter obt.
    parameter t.
    return trueAnomalyFromMeanAnomaly(meanAnomalyAtTime(obt, t), obt:eccentricity).
}

function vecToPe {
    parameter i is ship:obt:inclination.
    parameter lan is ship:obt:lan.
    parameter w is ship:obt:argumentOfPeriapsis.
    parameter b is ship:obt:body.

    local n is obtNormal(i, lan, b).
    local eqAxis is vecToAn(lan, b).
    local majAxis is angleAxis(w, n) * eqAxis.
    return majAxis:normalized.
}

function vecToAn {
    parameter lan is ship:obt:lan.
    parameter b is ship:obt:body.

    local lanOff is b:rotationAngle.
    local eqAxis is latlng(0, lan - lanOff):position - b:position.

    return eqAxis:normalized.
}

function obtNormal {
    parameter i is ship:obt:inclination.
    parameter lan is ship:obt:lan.
    parameter b is ship:obt:body.

    local axis is vecToAn(lan, b).

    local s is latlng(-90, 0):position - b:position.
    local n is angleaxis(-i, axis) * s.
    return n:normalized.
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