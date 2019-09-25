run once math.
run once logging.

declare function inclinationDv {
    parameter v.
    parameter i.
    return 2 * v * sin( i / 2 ).
}

global function vecToRelativeAn {
    parameter tgt.
    local parentBody is tgt:body.
    
    local shipP to ship:position - parentBody:position.
    local shipN is vcrs(ship:obt:velocity:orbit, shipP):normalized.
    local tgtN is vcrs(tgt:obt:velocity:orbit, tgt:position - parentBody:position):normalized.
    return vcrs(shipN, tgtN).
}

declare function addMatchInclinationNode {
    parameter targetBody.

    local parentBody is targetBody:obt:body.
    
    local shipP to ship:position - parentBody:position.
    local shipN is vcrs(ship:obt:velocity:orbit, shipP):normalized.
    local tgtN is vcrs(targetBody:obt:velocity:orbit, targetBody:position - parentBody:position):normalized.
    local intersectV is vcrs(shipN, tgtN).

    local iChange is vAng(tgtN, shipN).

    local iChangeDv to -inclinationDv(ship:obt:velocity:orbit:mag, iChange).
    local halfBurnTime is maneuverTime(abs(iChangeDv) / 2).
    local shipAngV to meanMotion(ship:obt).

    local nodeAnomaly to angleBetween(shipP, intersectV).
    if (nodeAnomaly > 180) {
        // start with closest node
        set nodeAnomaly to nodeAnomaly - 180.
        set iChangeDv to -iChangeDv.
    }

    local nodeTime is time:seconds + (nodeAnomaly / shipAngV).
    
    if (time:seconds > nodeTime - halfBurnTime - 30) {
        // switch AN/DN if too close
        set nodeAnomaly to nodeAnomaly + 180.
        set iChangeDv to -iChangeDv.
        set nodeTime to time:seconds + (nodeAnomaly / shipAngV).
    }
    
	local n to node(nodeTime, 0, 0, 0).
 	set n:normal to iChangeDv * cos(iChange/2).
	set n:prograde to 0 - abs(iChangeDv * sin(iChange/2)).
    add n.
    return n.
}


declare function addZeroInclinationNode {    
    local parentBody is ship:obt:body.
    local iChange is -ship:obt:inclination.

    local iChangeDv to inclinationDv(ship:obt:velocity:orbit:mag, iChange).
    local halfBurnTime is maneuverTime(abs(iChangeDv) / 2).
    local shipAngV to meanMotion(ship:obt).

    local shipP to ship:position - parentBody:position.
    local shipN is vcrs(ship:obt:velocity:orbit, shipP):normalized.
    local tgtN is parentBody:angularvel:normalized.
    local vecToAn is vcrs(shipN, tgtN).
    
    local nodeAnomaly to angleBetween(shipP, vecToAn).
    if (nodeAnomaly > 180) {
        // start with closest node
        set nodeAnomaly to nodeAnomaly - 180.
        set iChangeDv to -iChangeDv.
    }

    local nodeTime is time:seconds + (nodeAnomaly / shipAngV).    
    if (time:seconds > nodeTime - halfBurnTime - 30) {
        // switch AN/DN if too close
        set nodeAnomaly to nodeAnomaly + 180.
        set iChangeDv to -iChangeDv.
        set nodeTime to time:seconds + (nodeAnomaly / shipAngV).
    }

	local n to node(nodeTime, 0, 0, 0).
 	set n:normal to iChangeDv * cos(iChange/2).
	set n:prograde to 0 - abs(iChangeDv * sin(iChange/2)).
    add n.
    return n.
}