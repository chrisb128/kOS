run once math.
run once vec.
run once executenode.

global function addMatchVelocityAtClosestApproachNode {
    parameter tgt.

    local function distanceToTargetAtTime {
        parameter t.

        local sv0 is stateVectorsAtTime(ship:obt, t).
        local tv0 is stateVectorsAtTime(tgt:obt, t).
        return (tv0[0] - sv0[0]):mag.
    }

    // first guess is near ship Ap
    local travelTime is eta:apoapsis + time:seconds.
    set travelTime to hillClimber({ parameter x. return distanceToTargetAtTime(x). }, travelTime, 2, -4, round(ship:obt:period)).

    local shipVecAtTime is stateVectorsAtTime(ship:obt, travelTime).
    local targetVecAtTime is stateVectorsAtTime(tgt:obt, travelTime).
    local deltaV is targetVecAtTime[1] - shipVecAtTime[1].
    add nodeFromVector(deltaV, travelTime, shipVecAtTime[0], shipVecAtTime[1], false).
}

global function closeDistanceToTarget {
    parameter tgt.
    parameter dist.

    local closeSpeed is 30.

    lock currentDist to tgt:position:mag.

    if currentDist < 500 {
        set closeSpeed to 10.
    } else if currentDist < 50 {
        set closeSpeed to 5.
    } else if currentDist < 10 {
        set closeSpeed to 1.
    }

    if currentDist <= dist { return. }

    lock steering to tgt:position:normalized.

    wait until vAng(ship:facing:forevector, tgt:position) < 0.1.

    local kickTime is maneuverTime(closeSpeed).
    local kickStart is time:seconds.
    lock throttle to 1.
    wait until time:seconds >= kickStart + kickTime.
    lock throttle to 0.

    local meetTime is time:seconds + currentDist / closeSpeed.
    local stopTime is maneuverTime(closeSpeed).
    local nodeTime is meetTime - stopTime.

    local tgtVecAtNode is stateVectorsAtTime(tgt:obt, nodeTime).
    local shipVecAtNode is stateVectorsAtTime(ship:obt, nodeTime).

    add nodeFromVector(tgtVecAtNode[1] - shipVecAtNode[1], nodeTime, shipVecAtNode[0], shipVecAtNode[1], false).
    executeNode(true, 10, false).
    wait 1.

    until abs((tgtVecAtNode[1] - shipVecAtNode[1]):mag) < 0.15 {
        
        set tgtVecAtNode to stateVectorsAtTime(tgt:obt, time:seconds).
        set shipVecAtNode to stateVectorsAtTime(ship:obt, time:seconds).
        add nodeFromVector(tgtVecAtNode[1] - shipVecAtNode[1], nodeTime, shipVecAtNode[0], shipVecAtNode[1], false).
        executeNode(true, 10, false).
        wait 1.
    }

    unlock currentDist.
}