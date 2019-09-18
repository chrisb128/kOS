run once math.
run once vec.
run once executenode.
run once optimizers.

global function addMatchVelocityAtClosestApproachNode {
    parameter tgt.

    local function distanceToTargetAtTime {
        parameter t.

        local sv0 is stateVectorsAtTime(ship:obt, t).
        local tv0 is stateVectorsAtTime(tgt:obt, t).
        return (tv0[0] - sv0[0]):mag.
    }

    local intersectTime is eta:apoapsis + time:seconds.
    set intersectTime to steepestDescentHillClimb(
        { parameter x. return distanceToTargetAtTime(x[0]). }, 
        list(intersectTime),
        list(1),
        0.1
    )[0].

    local shipVecAtTime is stateVectorsAtTime(ship:obt, intersectTime).
    local targetVecAtTime is stateVectorsAtTime(tgt:obt, intersectTime).
    local deltaV is targetVecAtTime[1] - shipVecAtTime[1].
    local n is nodeFromVector(deltaV, intersectTime, shipVecAtTime[0], shipVecAtTime[1]).
    add n.
    return n.
}

global function closeDistanceToTarget {
    parameter tgt.
    parameter dist.

    local closeSpeed is 30.

    lock currentDist to tgt:position:mag.

    if currentDist < 1000 {
        set closeSpeed to 10.
    } else if currentDist < 100 {
        set closeSpeed to 1.
    } else if currentDist < 60 {
        set closeSpeed to 0.
    }

    if currentDist <= dist { return. }

    lock steering to tgt:position:normalized.

    wait until vAng(ship:facing:forevector, tgt:position) < 0.1.

    local kickTime is maneuverTime(closeSpeed).
    local kickStart is time:seconds.
    lock throttle to 1.
    wait until time:seconds >= kickStart + kickTime.
    lock throttle to 0.

    local meetTime is time:seconds + ((currentDist - dist) / closeSpeed).
    local stopTime is maneuverTime(closeSpeed).
    local nodeTime is meetTime - stopTime.

    local tgtVecAtNode is stateVectorsAtTime(tgt:obt, nodeTime).
    local shipVecAtNode is stateVectorsAtTime(ship:obt, nodeTime).

    add nodeFromVector(tgtVecAtNode[1] - shipVecAtNode[1], nodeTime, shipVecAtNode[0], shipVecAtNode[1]).
    executeNode(true, 10, false).
    wait 1.

    set tgtVecAtNode to stateVectorsAtTime(tgt:obt, time:seconds).
    set shipVecAtNode to stateVectorsAtTime(ship:obt, time:seconds).

    until abs((tgtVecAtNode[1] - shipVecAtNode[1]):mag) < 0.25 {
        
        add nodeFromVector(tgtVecAtNode[1] - shipVecAtNode[1], nodeTime, shipVecAtNode[0], shipVecAtNode[1]).
        executeNode(true, 10, false).
        wait 1.
        
        set tgtVecAtNode to stateVectorsAtTime(tgt:obt, time:seconds).
        set shipVecAtNode to stateVectorsAtTime(ship:obt, time:seconds).
        
        if (abs((tgtVecAtNode[1] - shipVecAtNode[1]):mag) < 0.25) {
            break.
        }
    }

    unlock currentDist.
}