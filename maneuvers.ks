run once math.
run once vec.

global function addCircularizeNodeAtAp {
    
    local r to ship:orbit:apoapsis + ship:orbit:body:radius.
    local initV to sqrt( body:mu * ( (2/r) - (1/ship:orbit:semimajoraxis) ) ).
    local finalV to sqrt( body:mu * ( (2/r) - (1/r) ) ).

    local n is node(time:seconds + eta:apoapsis, 0, 0, finalV - initV).
    add n.
    return n.
}

global function addCircularizeNodeAtPe {
    
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

global function addSetPeriapsisNodeAtAp {
    parameter periapsis.
    
    local dV1 is -hohmannDV2(body:mu, periapsis + body:radius, ship:obt:semimajoraxis).        
    local node is node(eta:apoapsis + time:seconds, 0, 0, dV1).
    add node.
    return node.
}

global function addSetPeriapsisNode {
    parameter periapsis.
    parameter nodeTime.
    
    local b is ship:obt:body.
    local so_e is ship:obt:eccentricity.
    local so_sma is ship:obt:semimajoraxis.
    local so_w is ship:obt:argumentOfPeriapsis.
    local so_lan is ship:obt:lan.
    local so_i is ship:obt:inclination.
    
    local shipTaAtNode is vAng(positionAt(ship, nodeTime)-b:position, vecToPe(so_i, so_lan, so_w, b)).
    local shipRAtNode is radiusFromTrueAnomaly(shipTaAtNode, so_e, so_sma).
    local no_pe is periapsis + b:radius.
    local no_ap is shipRAtNode.
    local no_e is eFromApPe(no_ap, no_pe).
    local no_sma is smaFromApPe(no_ap, no_pe).
    local no_w is clamp360(shipTaAtNode + 180).
    
    local shipVecsAtNode is stateVectorsAtTrueAnomaly(so_e, so_sma, so_w, so_lan, so_i, shipTaAtNode, b).
    drawStateVectors(list(), shipVecsAtNode, b).
    local tgtVecsAtNode is stateVectorsAtTrueAnomaly(no_e, no_sma, no_w, so_lan, so_i, 180, b).
    local w_adj is vAng(shipVecsAtNode[0], tgtVecsAtNode[0]).
    drawStateVectors(list(), tgtVecsAtNode, b).

    // if periapsis > ship:obt:periapsis {
    //     set no_w to clamp360(no_w + w_adj).
    // } else {
    //     set no_w to clamp360(no_w - w_adj).
    // }
    // set tgtVecsAtNode to stateVectorsAtTrueAnomaly(no_e, no_sma, no_w, so_lan, so_i, 180, b).

    local diff is (tgtVecsAtNode[1] - shipVecsAtNode[1]).
    local node is nodeFromVector(diff, nodeTime, shipVecsAtNode[0], shipVecsAtNode[1]).
    add node.
    return node.
}