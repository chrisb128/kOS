global function steepestDescentHillClimb {
    parameter fErr.                  // function to minimize
    parameter p0 is list(0,0,0).     // initial vector
    parameter s0 is list(1,1,1).     // initial step size vector
    parameter acc is 1.2.            // acceleration
    parameter epsilon is 0.000001.   // max change in error
    parameter maxN is 100.           // max iterations

    local stepSize is s0:copy().

    local candidates is list().
    candidates:add(-acc).
    candidates:add(-1/acc).
    candidates:add(0).
    candidates:add(1/acc).
    candidates:add(acc).
    
    local n is 0.
    until false {
        local before is fErr(p0).
        
        local currentPoint is p0.
        for i in range(0, currentPoint:length) {
            local best is -1.
            local bestScore is 999999999999.

            for j in range(0, 5) {
                set currentPoint[i] to currentPoint[i] + stepSize[i] * candidates[j].
                local t is fErr(currentPoint).
                set currentPoint[i] to currentPoint[i] - stepSize[i] * candidates[j].
                if (t < bestScore) {
                    set bestScore to t.
                    set best to j.
                }
            }

            if candidates[best] = 0 {
                set stepSize[i] to stepSize[i] / acc.
            } else {
                set currentPoint[i] to currentPoint[i] + stepSize[i] * candidates[best].
                set stepSize[i] to stepSize[i] * candidates[best].
            }
        }

        local nextPoint is currentPoint.

        local after is fErr(nextPoint).
        local delta is after - before.

        if (abs(delta) < epsilon) {
            return nextPoint.
        }

        set n to n + 1.
        if n > maxN {
            print "!!! SOLVER OVERRUN !!!" at (0, terminal:height - 1).
            return nextPoint.
        }
    }
}

global function vecToList {
    parameter v.

    return list(v:x, v:y, v:z).
}

global function listToVec {
    parameter l.

    return v(l[0], l[1], l[2]).
}