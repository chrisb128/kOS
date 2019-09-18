run once math.
run once optimizers.

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

function trueAnomalyFromMeanAnomaly {
    parameter M. // mean anomaly
    parameter e. // eccentricity

    // return M 
    //     + (2*e - (0.25*e^3)) * sin(M) 
    //     + (1.25*e^2) * sin(2*M) 
    //     + ((13/12)*e^3) * sin(3*M).
    //     // could add more terms for better accuracy, but probably not necessary

    return trueAnomalyFromEccentricAnomaly(eccentricAnomalyFromMeanAnomaly(M, e), e).
}

function meanAnomalyFromTrueAnomaly {
    parameter v. // true anomaly
    parameter e. // eccentricity

    // return v 
    //     - 2*e*sin(v) 
    //     + (0.75*e^2 + 0.125*e^4)*sin(2*v) 
    //     - ((1/3)*e^3*sin(3*v))
    //     + ((5/32)*e^4*sin(4*v)).
    //     // could add more terms for better accuracy, but probably not necessary
    return meanAnomalyFromEccentricAnomaly(eccentricAnomalyFromTrueAnomaly(v, e), e).
}

function radiusFromTrueAnomaly {
    parameter v. // true anomaly
    parameter e. // eccentricity
    parameter a. // semi-major axis

    if (1 + e*cos(v) = 0) {
        set v to v + 0.1.
    }

    return a * ( (1-e^2) / ( 1+(e*cos(v)) ) ).
}

function eccentricAnomalyFromTrueAnomaly {
    parameter v. // true anomaly
    parameter e. // eccentricity

    if (e < 1) {
        return 2 * arctan( sqrt((1 - e)/(1 + e)) * tan(v / 2) ).
    } else {
        return 2 * atanh( sqrt((e - 1)/(e + 1)) * tan(v / 2) ).
    }
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
    return meanMotionK(obt:body:mu, obt:semimajoraxis).
}

function meanMotionK {
    parameter mu.
    parameter a.
    return sqrt(mu/abs(a)^3)*constant:radtodeg.
}

function meanAnomalyAtTime {
    parameter obt.
    parameter t.

    local dt is t - obt:epoch.
    local n is meanMotion(obt).
    local Mt is obt:meanAnomalyAtEpoch + (n * dt).
    
    return clamp360(Mt).
}

function trueAnomalyAtTime {
    parameter obt.
    parameter t.
    return trueAnomalyFromMeanAnomaly(meanAnomalyAtTime(obt, t), obt:eccentricity).
}

function timeToTrueAnomaly {
    parameter obt.
    parameter t.

    local maAtTa is meanAnomalyFromEccentricAnomaly(eccentricAnomalyFromTrueAnomaly(t, obt:eccentricity), obt:eccentricity).
    local ma is meanAnomalyAtTime(obt, time:seconds).
    if (ma < 0) {
        set ma to ma + 360.
    }
    local timeToPe is 0.
    if (t < obt:trueAnomaly) {
        set timeToPe to (360 - ma) / meanMotion(obt).
    } else {
        set timeToPe to -ma / meanMotion(obt).
    }
    
    return (meanMotion(obt) * maAtTa) + timeToPe.
}

 function velocityAtR {
    parameter r.
    parameter mu.
    parameter sma.

    return sqrt(mu * ( (2/r) - (1/sma))).
}


global function trueAnomaliesWithRadius {
    //returns a list of the true anomalies of the 2 points where the craft's orbit passes the given altitude
	parameter sma,ecc,r.
	local rad is r.
	local taWithR is arcCos((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	return list(taWithR,360-taWithR).//first true anomaly will be as orbit goes from PE to AP
}