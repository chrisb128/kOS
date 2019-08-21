run once math.
run once warp.

global function executeNode {
    parameter doWarp is true.
    parameter warpLead is 10.

    local theNode to nextNode.
    local halfBurnTime is maneuverTime(theNode:deltav:mag/2).
    local nodeDir to theNode:deltav:vec.

    lock steering to nodeDir.
    wait until vAng(nodeDir, ship:facing:vector) < 0.15 and ship:angularVel:mag < 0.05.
    
    local nodeTime is time:seconds + (theNode:eta - halfBurnTime - warpLead).
    if doWarp {

        until time:seconds > nodeTime {
            autoWarp(nodeTime).
            
            if vAng(theNode:deltav, ship:facing:vector) > 15 {
                set nodeDir to theNode:deltav:vec.
                set kuniverse:timewarp:warp to 0.

                wait until vAng(nodeDir, ship:facing:vector) < 1.
            }
        }
        
        set kuniverse:timewarp:warp to 0.
    }

    set nodeDir to theNode:deltav:vec.
    lock steering to nodeDir.

    wait until theNode:eta < halfBurnTime.

    local throttleLock to 0.
    lock throttle to throttleLock.

    local done is false.

    local dV0 to theNode:deltav.

    until done {

        if vAng(theNode:deltav, ship:facing:vector) > 15 {
            set throttleLock to 0.
            set nodeDir to theNode:deltav:vec.
            
            wait until vAng(nodeDir, ship:facing:vector) < 1.
        }
        
        if vDot(dV0, theNode:deltav) < 0 {
            break.
        }

        if theNode:deltav:mag < 0.1 {
            wait until vDot(dv0, theNode:deltav) < 0.
            set throttleLock to 0.
            set done to true.
        } else {
            local ang is vAng(theNode:deltav, ship:facing:vector).
            if ang > 0 and ang < 5 {
                set nodeDir to theNode:deltav:vec.
            }

            local maxAcc to ship:maxthrust / ship:mass.
            if maxAcc > 0 {
                set throttleLock to min(theNode:deltav:mag / maxAcc, 1).
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
