run once hohmannDv.
run once math.
run once vec.

// Compute required angle between source and destination in order to rendezvous at apoapsis
global function hohmannTargetAngle {
    parameter r1.
    parameter r2.

    return 360 - ((constant:pi * ( (1-(1/(2*sqrt(2)))) * sqrt( ((r1/r2)+1)^3 ))) * constant:radToDeg).
}

global function addHohmannTransferNode {
    parameter tgt.

    local parentBody is tgt:body.

    if ship:body:name <> parentBody:name {
        PRINT "!!!! Ship not in orbit of target's parent !!!!" AT (0, terminal:height - 1).
        return.
    }
    
    local xferR2 is tgt:obt:semimajoraxis.
    local xferDV is hohmannDV1(parentBody:mu, ship:obt:semimajoraxis, xferR2).
    local xferAngle is hohmannTargetAngle(ship:obt:semimajoraxis, xferR2).
    local xferNodeTime is timeToRelativeAngle(tgt, ship, parentBody, xferAngle).
    add node(xferNodeTime, 0, 0, xferDV).
}

global function addRendezvousTransferNode {
    parameter tgt.

    local to is tgt:obt.
    local so is ship:obt.
    local b is ship:body.
    
    local function iterateXferOrbit {
        parameter o. // transfer orbit info lexicon

        local xferMm to meanMotionK(b:mu, o:sma).
        local travelTime to 180 / xferMm.

        local tgtMm is meanMotion(to).
        local tgtAngle is clamp360(travelTime * tgtMm + 180).

        set o:nt to timeToRelativeAngle(tgt, ship, b, tgtAngle).

        local shipTaAtNodeTime is trueAnomalyAtTime(so, o:nt).
        local xferRPe to radiusFromTrueAnomaly(shipTaAtNodeTime, so:eccentricity, so:semimajoraxis).

        local tgtTa to trueAnomalyAtTime(to, o:nt + travelTime).
        local tgtRAp to radiusFromTrueAnomaly(tgtTa, to:eccentricity, to:semimajoraxis).

        set o:e to eFromApPe(tgtRAp, xferRPe).
        set o:w to clamp360((shipTaAtNodeTime + so:argumentOfPeriapsis + so:lan) - to:lan).
        set o:sma to smaFromApPe(tgtRAp, xferRPe).

        return o.
    }

    local xfer to recursiveSolver(
        { parameter x. return iterateXferOrbit(x). },
        { parameter x. parameter y. return x:sma - y:sma. },
        lexicon("sma", smaFromApPe(to:apoapsis + b:radius, so:periapsis + b:radius),
                "e", eFromApPe(to:apoapsis + b:radius, so:periapsis),
                "w", 0,
                "nt", 0)
    ).

    set shipTaAtNodeTime to trueAnomalyAtTime(so, xfer:nt).

    // vectors for simulated transfer orbit
    local xferVecAtPe is stateVectorsAtTrueAnomaly(xfer:e, xfer:sma, xfer:w, to:lan, to:inclination, 0, b).
    // vectors for the ship at transfer time
    local shipVecAtXferPe is stateVectorsAtTrueAnomaly(so:eccentricity, so:semimajoraxis, so:argumentOfPeriapsis, so:lan, so:inclination, shipTaAtNodeTime, b).
    // delta-v vector
    local dVec is xferVecAtPe[1] - shipVecAtXferPe[1].
    
    add nodeFromVector(dVec, xfer:nt, shipVecAtXferPe[0], shipVecAtXferPe[1]).
}
