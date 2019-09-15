declare function addCircularizeNodeAtAp {
    
    local body to ship:orbit:body.

    local r to ship:orbit:apoapsis + ship:orbit:body:radius.
    local initV to sqrt( body:mu * ( (2/r) - (1/ship:orbit:semimajoraxis) ) ).
    local finalV to sqrt( body:mu * ( (2/r) - (1/r) ) ).

    local n is node(time:seconds + eta:apoapsis, 0, 0, finalV - initV).
    add n.
    return n.
}

declare function addCircularizeNodeAtPe {
    
    local body to ship:orbit:body.

    local r to ship:orbit:periapsis + ship:orbit:body:radius.
    local initV to sqrt( body:mu * ( (2/r) - (1/ship:orbit:semimajoraxis) ) ).
    local finalV to sqrt( body:mu * ( (2/r) - (1/r) ) ).

    local n is node(time:seconds + eta:periapsis, 0, 0, finalV - initV).
    add n.
    return n.
}

global function addSetHyperbolicPeriapsisNode {
    parameter targetPe.
    parameter nodeTime.
    

    local b is ship:obt:body.
    local so_e is ship:obt:eccentricity.
    local so_sma is ship:obt:semimajoraxis.
    local so_w is ship:obt:argumentOfPeriapsis.
    local so_lan is ship:obt:lan.
    local so_i is ship:obt:inclination.

    local rAtNodeTime is positionAt(ship:body, nodeTime):mag.
    local ta is trueAnomaliesWithRadius(so_sma, so_e, b, rAtNodeTime)[1].
    local vecsAtNodeTime is stateVectorsAtTrueAnomaly(so_e, so_sma, so_w, so_lan, so_i, ta, b).
    //drawStateVectors(list(), vecsAtNodeTime, b).

    local no_rp is targetPe + b:radius.
    local no_sma is ( no_rp / (1 - so_e) ).
    set ta to trueAnomaliesWithRadius(no_sma, so_e, b, rAtNodeTime)[1].
    local newVecsAtNodeTime is stateVectorsAtTrueAnomaly(so_e, no_sma, so_w, so_lan, so_i, ta, b).
    local ang is -vAng(vecsAtNodeTime[0], newVecsAtNodeTime[0]).
    local no_w is so_w + ang.
    set newVecsAtNodeTime to stateVectorsAtTrueAnomaly(so_e, no_sma, no_w, so_lan, so_i, ta, b).
    //drawStateVectors(list(), newVecsAtNodeTime, b).

    local diff is newVecsAtNodeTime[1] - vecsAtNodeTime[1].
    local node is nodeFromVector(diff, nodeTime, vecsAtNodeTime[0], vecsAtNodeTime[1]).
    add node.
    return node.
}