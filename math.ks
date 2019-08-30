run once "list.ks".

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

function eccentricAnomalyFromMeanAnomaly {
    parameter M. // mean anomaly
    parameter ec. // eccentricity

    local delta is 0.00001.

    local E is 0.
    local F is 1.

    set M to (M / 360.0).
    set M to (M - floor(M)) * 360.0.

    if (ec < 0.8) { set E to M. } 
    else { set E to 180. }
    
    // set F to (E - ec * constant:radtodeg * sin(E) - M).
    local i is 0.
    for _ in range(30) {
        if (abs(F) <= delta) { break.}

        local E1 to M + ec * constant:radtodeg * sin(E).
        set F to E1 - E.
        set E to E1.  

        // set E to E - F / (1.0 - ec * constant:radtodeg * cos(E)).
        // set F to E - ec * constant:radtodeg * sin(E) - M.

        set i to i + 1.
    }

    return E.
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
    parameter a. // semi-major axis
    parameter e. // eccentricity
    parameter v. // true anomaly

    return a * ( (1-e^2) / ( 1+(e*cos(v)) ) ).
}

function eccentricAnomalyFromTrueAnomaly {
    parameter e. // eccentricity
    parameter v. // true anomaly

    // not sure this works?
    return arccos( (cos(v) + e) / (1 + e*cos(v)) ).
}

function meanAnomalyAtTime {
    parameter obt.
    parameter t.

    local dt is t - obt:epoch.
    local n is sqrt(obt:body:mu / abs(obt:semimajoraxis)^3) * constant:radtodeg.
    //local n is 360 / obt:period.
    return obt:meanAnomalyAtEpoch + (n * dt).
}

function trueAnomalyAtTime {
    parameter obt.
    parameter t.

    return trueAnomalyFromMeanAnomaly(meanAnomalyAtTime(obt, t), obt:eccentricity).
}

function obtNormal {
    parameter o. // orbitable
    parameter n. // target orbit normal.
    return vcrs(n,vcrs(o:position-o:body:position,o:velocity:orbit)):normalized.
}
