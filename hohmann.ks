run once hohmannDv.
run once math.

// Compute required angle between source and destination in order to rendezvous at apoapsis
local function hohmannTargetAngle {
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