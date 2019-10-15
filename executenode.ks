run once math.
run once warp.

global function executeNode {
    parameter doWarp is true.
    parameter warpLead is 10.
    parameter splitNode is true.
    parameter stopEarly is { return false. }.

    local theNode to nextNode.
    local burnTimeToNode is maneuverTime(theNode:deltav:mag/2).
    if not splitNode {
        set burnTimeToNode to maneuverTime(theNode:deltav:mag).
    }
    local nodeDir to theNode:deltav:vec.

    lock steering to nodeDir.
    wait until (vAng(nodeDir, ship:facing:vector) < 0.5 and ship:angularVel:mag < 0.05) or theNode:eta < 0.
    
    local nodeTime is time:seconds + (theNode:eta - burnTimeToNode - warpLead).
    if doWarp {

        until time:seconds > nodeTime {
            autoWarp(nodeTime).
            
            if vAng(theNode:deltav, ship:facing:vector) > 15 {
                set nodeDir to theNode:deltav:vec.
                set kuniverse:timewarp:warp to 0.

                wait until vAng(nodeDir, ship:facing:vector) < 0.5.
            }
        }
        
        set kuniverse:timewarp:warp to 0.
    }

    set nodeDir to theNode:deltav:vec.
    lock steering to nodeDir.

    wait until theNode:eta <= burnTimeToNode.

    local throttleLock to 0.
    lock throttle to throttleLock.

    local done is false.

    local dV0 to theNode:deltav.


    on (vDot(dV0, theNode:deltav) < 0) {
        set throttleLock to 0.
        set done to true.
    }.

    until done {        

        local ang is vAng(theNode:deltav, ship:facing:vector).
        
        // below 0.5 m/s remaining, the node target can change significantly
        // so just stay at the last throttle until the node is finished
        // otherwise, steer to stay on target and set the throttle
        if theNode:deltav:mag > 0.5 and ang <= 30 {
            if ang > 0 and ang < 5 {
                set nodeDir to theNode:deltav:vec.
            }

            local maxAcc to ship:maxthrust / ship:mass.
            if maxAcc > 0 {
                set throttleLock to max(0.05, min(theNode:deltav:mag * 0.5 / maxAcc, 1)).
            }

        // above 0.5 m/s remaining and more than 30 degrees off course, stop and resteer
        } else if theNode:deltav:mag > 0.5 and ang > 45 {
            set throttleLock to 0.
            set nodeDir to theNode:deltav:vec.
            
            wait until vAng(nodeDir, ship:facing:vector) < 1.
        } else if theNode:deltav:mag < 0.5 and throttleLock = 0 {         

            local maxAcc to ship:maxthrust / ship:mass.
            if maxAcc > 0 {
                set throttleLock to max(0.05, min(theNode:deltav:mag * 0.5 / maxAcc, 1)).
            }
        }

        wait 0.
    }
    
    lock throttle to 0.
    wait 1.

    remove theNode.
    unlock steering.

    wait 1.
}.
