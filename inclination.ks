run once math.
run once logging.

declare function matchInclination {
    parameter targetBody.
    local parentBody is targetBody:obt:body.
            
    local inclinationDv to -(2 * ship:obt:velocity:orbit:mag * sin( targetBody:obt:inclination / 2 )).
    local burnTime is maneuverTime(inclinationDv).
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
        set inclinationDv to -inclinationDv.
        logInfo("dAngle: " + nodeAnomaly, 3).
    }

    local nodeTime is time:seconds + (nodeAnomaly / shipAngV).
    logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
    logInfo("dV: " + inclinationDv, 2).
    
    if (time:seconds > nodeTime - (burnTime/2) - 30) {
        // switch AN/DN if too close
        set nodeAnomaly to nodeAnomaly + 180.
        set inclinationDv to -inclinationDv.
        set nodeTime to time:seconds + (nodeAnomaly / shipAngV).
        
        logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
        logInfo("dV: " + inclinationDv, 2).
    }

    add node(nodeTime, 0, inclinationDv, 0).
}


declare function zeroInclination {    
    local parentBody is ship:obt:body.
            
    local inclinationDv to -(2 * ship:obt:velocity:orbit:mag * sin( ship:obt:inclination / 2 )).
    local burnTime is maneuverTime(inclinationDv).
    local shipAngV to 360 / ship:obt:period.

    local shipP to ship:position - parentBody:position.
    local shipN is vcrs(ship:obt:velocity:orbit, shipP):normalized.
    local tgtN is vcrs(ship:obt:velocity:orbit, ship:position - parentBody:position):normalized.
    local intersectV is vcrs(shipN, tgtN).
    
    local nodeAnomaly to angleBetween(shipP, intersectV).
    logInfo("dAngle: " + nodeAnomaly, 3).
    logInfo("shipAngV: " + shipAngV, 4).
    if (nodeAnomaly > 180) {
        // start with closest node
        set nodeAnomaly to nodeAnomaly - 180.
        set inclinationDv to -inclinationDv.
        logInfo("dAngle: " + nodeAnomaly, 3).
    }

    local nodeTime is time:seconds + (nodeAnomaly / shipAngV).
    logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
    logInfo("dV: " + inclinationDv, 2).
    
    if (time:seconds > nodeTime - (burnTime/2) - 30) {
        // switch AN/DN if too close
        set nodeAnomaly to nodeAnomaly + 180.
        set inclinationDv to -inclinationDv.
        set nodeTime to time:seconds + (nodeAnomaly / shipAngV).
        
        logInfo("Node in T-" + round(nodeTime - time:seconds, 0), 1).
        logInfo("dV: " + inclinationDv, 2).
    }

    add node(nodeTime, 0, inclinationDv, 0).
}