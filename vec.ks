run once math.

global function stateVectorsAtTime {
    parameter o is ship:obt.
    parameter t is time:seconds.

    local e is o:eccentricity.
    local sma is o:semimajoraxis.
    local w is o:argumentOfPeriapsis.
    local lan is o:lan.
    local i is o:inclination.

    local Mt is meanAnomalyAtTime(o, t).

    return stateVectorsAtMeanAnomaly(e, sma, w, lan, i, Mt, o:body).
}

global function stateVectorsAtMeanAnomaly {
    parameter e.
    parameter sma.
    parameter w.
    parameter lan.
    parameter i.
    parameter Mt.
    parameter b.

    local Et is eccentricAnomalyFromMeanAnomaly(Mt, e).   
    local Vt is trueAnomalyFromEccentricAnomaly(Et, e).
    
    return stateVectorsAtTrueAnomaly(e, sma, w, lan, i, Vt, b).
}

global function stateVectorsAtTrueAnomaly {
    parameter e.
    parameter sma.
    parameter w.
    parameter lan.
    parameter i.
    parameter Vt.
    parameter b.
    
    local vel is velocityVecAt(Vt, sma, e, i, lan, w, b).
    local pos is positionVecAt(Vt, sma, e, i, lan, w, b).

    return list(pos, vel).
}

global function positionVecAt {    
    parameter t is ship:obt:trueAnomaly.
    parameter sma is ship:obt:semimajoraxis.
    parameter e is ship:obt:eccentricity.
    parameter i is ship:obt:inclination.
    parameter lan is ship:obt:lan.
    parameter w is ship:obt:argumentOfPeriapsis.
    parameter b is ship:obt:body.
    
    local r to radiusFromTrueAnomaly(t, e, sma).
    local pe is vecToPe(i, lan, w, b).
    local pos is pe * r.

    set pos to angleAxis(t, obtNormal(i, lan, b)) * pos.

    return pos.
}

global function velocityVecAt {
    parameter t is ship:obt:trueAnomaly.
    parameter sma is ship:obt:semimajoraxis.
    parameter e is ship:obt:eccentricity.
    parameter i is ship:obt:inclination.
    parameter lan is ship:obt:lan.
    parameter w is ship:obt:argumentofperiapsis.
    parameter b is ship:obt:body.
    
    // normal vector, major axis
    local n to obtNormal(i, lan, b).
    local maj to vecToPe(i, lan, w, b).

    // radial vector, along-track vector
    // note that these are not the radialout and prograde burn directions
    local rad to angleAxis(t, n) * maj.
    local pro to vCrs(n, rad).

    // equations from http://orbiter-forum.com/showthread.php?t=24457
    local r to radiusFromTrueAnomaly(t, e, sma).
    local h to sqrt(b:mu * sma * (1 - e^2)).
    local vr to b:mu * e * sin(t) / h.
    local vt to h / r.

    return vr * rad:normalized + vt * pro:normalized.
}

global function nodeFromVector {
  parameter vec.
  parameter t is time:seconds.

  local s_pro is velocityAt(ship, t):orbit.
  local s_pos is positionAt(ship, t) - body:position.
  local s_nrm is vCrs(s_pro,s_pos).
  local s_rad is vCrs(s_nrm,s_pro).

  local pro is vDot(vec,s_pro:normalized).
  local nrm is vDot(vec,s_nrm:normalized).
  local rad is vDot(vec,s_rad:normalized).

  return node(t, rad, nrm, pro).
}