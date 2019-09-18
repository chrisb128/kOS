run once hohmannDv.
run once math.
run once orbits.
run once vec.
run once optimizers.

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
    local wA TO meanMotion(a:obt).
    local wB TO meanMotion(b:obt).
    return wB - wA.
}
// Compute required angle between source and destination in order to rendezvous at apoapsis
global function hohmannTargetAngle {
    parameter r1.
    parameter r2.

    return 360 - ((constant:pi * ( (1-(1/(2*sqrt(2)))) * sqrt( ((r1/r2)+1)^3 ))) * constant:radToDeg).
}

global function addRendezvousTransferNode {
    parameter tgt.

    local to is tgt:obt.
    local so is ship:obt.
    local b is ship:body.
            
    local xferMm to meanMotionK(b:mu, (so:semimajoraxis + to:semimajoraxis) / 2).
    local travelTime to 180 / xferMm.
    local tgtMm is meanMotion(to).
    local tgtAngle is clamp360(travelTime * tgtMm + 180).
    set nodeTime to timeToRelativeAngle(tgt, ship, b, tgtAngle).

    local function getTransferParamsForNodeTime {
        parameter nt.

        local shipTaAtNodeTime is trueAnomalyAtTime(so, nt).
        local tgtTaAtXferAp is clamp360(((shipTaAtNodeTime + 180) + (so:argumentOfPeriapsis + so:lan)) - (to:argumentOfPeriapsis + to:lan)).

        local xferW is (shipTaAtNodeTime + so:argumentOfPeriapsis + so:lan) - so:lan.
        local xferRPe to radiusFromTrueAnomaly(shipTaAtNodeTime, so:eccentricity, so:semimajoraxis).
        local xferRAp to radiusFromTrueAnomaly(tgtTaAtXferAp, to:eccentricity, to:semimajoraxis).
        local xferSma is smaFromApPe(xferRAp, xferRPe).
        local xferE is eFromApPe(xferRAp, xferRPe).

        return lexicon(
            "e", xferE,
            "sma", xferSma,
            "w", xferW
        ).
    }

    local function interceptDistance {
        parameter nt.

        local xfer is getTransferParamsForNodeTime(nt).

        local xferMm is meanMotionK(b:mu, xfer:sma).
        local travelTime is 180 / xferMm.

        local tgtTaAtShipXferApTime is trueAnomalyAtTime(to, nt + travelTime).
        
        local xferVecAtAp is stateVectorsAtTrueAnomaly(xfer:e, xfer:sma, xfer:w, to:lan, to:inclination, 180, b).
        local tgtVecAtShipXferAp is stateVectorsAtTrueAnomaly(to:eccentricity, to:semimajoraxis, to:argumentofperiapsis, to:lan, to:inclination, tgtTaAtShipXferApTime, b).

        return (xferVecAtAp[0] - tgtVecAtShipXferAp[0]):mag.
    }

    set nodeTime to steepestDescentHillClimb(
        { parameter x. return interceptDistance(x[0]). },
        list(nodeTime),
        list(1)
    )[0].

    local xfer is getTransferParamsForNodeTime(nodeTime).
    local shipTaAtNodeTime is trueAnomalyAtTime(so, nodeTime).

    // vectors for simulated transfer orbit
    local xferVecAtPe is stateVectorsAtTrueAnomaly(xfer:e, xfer:sma, xfer:w, to:lan, to:inclination, 0, b).
    // vectors for the ship at transfer time
    local shipVecAtXferPe is stateVectorsAtTrueAnomaly(so:eccentricity, so:semimajoraxis, so:argumentOfPeriapsis, so:lan, so:inclination, shipTaAtNodeTime, b).
    // delta-v vector
    local dVec is xferVecAtPe[1] - shipVecAtXferPe[1].
    
    add nodeFromVector(dVec, nodeTime, shipVecAtXferPe[0], shipVecAtXferPe[1]).
}