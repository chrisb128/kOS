run once math.
run once logging.

declare function inclinationDv {
    parameter v.
    parameter i.
    return 2 * v * sin( i / 2 ).
}

declare function addMatchInclinationNode {
    parameter targetBody.
    local parentBody is targetBody:obt:body.
    local iChangeDv to -inclinationDv(ship:obt:velocity:orbit:mag, targetBody:obt:inclination).
    local halfBurnTime is maneuverTime(abs(iChangeDv) / 2).
    local shipAngV to 360 / ship:obt:period.

    local shipP to ship:position - parentBody:position.
    local shipN is vcrs(ship:obt:velocity:orbit, shipP):normalized.
    local tgtN is vcrs(targetBody:obt:velocity:orbit, targetBody:position - parentBody:position):normalized.
    local intersectV is vcrs(shipN, tgtN).
    
    local nodeAnomaly to angleBetween(shipP, intersectV).
    logInfo("dAngle: " + nodeAnomaly, 3).
    logInfo("shipAngV: " + shipAngV, 4).
    if (nodeAnomaly > 180) {
        // start with closest node
        set nodeAnomaly to nodeAnomaly - 180.
        set iChangeDv to -iChangeDv.
        logInfo("dAngle: " + nodeAnomaly, 3).
    }

    local nodeTime is time:seconds + (nodeAnomaly / shipAngV).
    logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
    logInfo("dV: " + iChangeDv, 2).
    
    if (time:seconds > nodeTime - halfBurnTime - 30) {
        // switch AN/DN if too close
        set nodeAnomaly to nodeAnomaly + 180.
        set iChangeDv to -iChangeDv.
        set nodeTime to time:seconds + (nodeAnomaly / shipAngV).
        
        logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
        logInfo("dV: " + iChangeDv, 2).
    }

    add node(nodeTime, 0, iChangeDv, 0).
}


declare function addZeroInclinationNode {    
    local parentBody is ship:obt:body.
            
    local iChangeDv to inclinationDv(ship:obt:velocity:orbit:mag, ship:obt:inclination).
    local halfBurnTime is maneuverTime(abs(iChangeDv) / 2).
    local shipAngV to 360 / ship:obt:period.

    local shipP to ship:position - parentBody:position.
    local shipN is vcrs(ship:obt:velocity:orbit, shipP):normalized.
    local tgtN is parentBody:angularvel:normalized.
    local intersectV is vcrs(shipN, tgtN).
    
    local nodeAnomaly to angleBetween(shipP, intersectV).
    logInfo("dAngle: " + nodeAnomaly, 3).
    logInfo("shipAngV: " + shipAngV, 4).
    if (nodeAnomaly > 180) {
        // start with closest node
        set nodeAnomaly to nodeAnomaly - 180.
        set iChangeDv to -iChangeDv.
        logInfo("dAngle: " + nodeAnomaly, 3).
    }

    local nodeTime is time:seconds + (nodeAnomaly / shipAngV).
    logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
    logInfo("dV: " + iChangeDv, 2).
    
    if (time:seconds > nodeTime - halfBurnTime - 30) {
        // switch AN/DN if too close
        set nodeAnomaly to nodeAnomaly + 180.
        set iChangeDv to -iChangeDv.
        set nodeTime to time:seconds + (nodeAnomaly / shipAngV).
        
        logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
        logInfo("dV: " + iChangeDv, 2).
    }

    add node(nodeTime, 0, iChangeDv, 0).
}