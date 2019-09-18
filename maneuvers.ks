run once math.
run once vec.

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
    local ta is trueAnomaliesWithRadius(so_sma, so_e, rAtNodeTime)[1].
    local vecsAtNodeTime is stateVectorsAtTrueAnomaly(so_e, so_sma, so_w, so_lan, so_i, ta, b).
    //drawStateVectors(list(), vecsAtNodeTime, b, RGB(1, 0, 0)).

    local no_rp is targetPe + b:radius.
    local no_sma is ( no_rp / (1 - so_e) ).
    local no_i is so_i.
    local no_w is so_w.
    local no_lan is so_lan.

    if (so_i > 90) {
        // change from retrograde orbit to prograde
        set no_i to 180 - so_i.
        set no_lan to -(180 - so_lan).
        if no_lan < 0 { set no_lan to no_lan + 360. }.
        set no_w to 360 - so_w.
    }

    set ta to trueAnomaliesWithRadius(no_sma, so_e, rAtNodeTime)[1].
    local newVecsAtNodeTime is stateVectorsAtTrueAnomaly(so_e, no_sma, no_w, no_lan, no_i, ta, b).
    //drawStateVectors(list(), newVecsAtNodeTime, b, RGB(0, 1, 0)).

    local ang is vAng(vecsAtNodeTime[0], newVecsAtNodeTime[0]).
    if targetPe > ship:periapsis and so_i < 90 {
        set ang to -ang.
    }

    set newVecsAtNodeTime to stateVectorsAtTrueAnomaly(so_e, no_sma, no_w + ang, no_lan, no_i, ta, b).
    //drawStateVectors(list(), newVecsAtNodeTime, b, RGB(1, 1, 0)).

    local diff is (newVecsAtNodeTime[1] - vecsAtNodeTime[1]).
    local node is nodeFromVector(diff, nodeTime, vecsAtNodeTime[0], vecsAtNodeTime[1]).
    add node.
    return node.
}