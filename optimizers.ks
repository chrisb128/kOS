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
            print "!!! HILL CLIMBER OVERRUN !!!" at (0, terminal:height - 1).
            return nextPoint.
        }
    }
}


function newtonSolver {
    parameter f.
    parameter df.
    parameter guess.
    parameter d is 0.000001.
    parameter c is 100.

    local err is d + 1.
    local x0 is guess.
    for n in range(c + 1) {
        if (abs(err) <= d) { break. }
        if (n >= c) { print "!!! NEWTON SOLVER OVERRUN !!!" at (0, terminal:height - 2). break. }

        local x1 is x0 - f(x0)/df(x0).
        set err to x1 - x0.
        set x0 to x1.
    }

    return x0.
}


function recursiveSolver {
    parameter f.
    parameter e.
    parameter guess.
    parameter d is 0.00000001.
    parameter c is 10000.

    local err is d.
    local x0 is guess.
    for n in range(c + 1) {
        if (n > 0 and abs(err) < d) { break. }
        if (n >= c) { print "!!! RECURSIVE SOLVER OVERRUN !!!" at (0, terminal:height - 3). break. }
        
        local x1 is f(x0).
        set err to e(x1, x0).
        set x0 to x1.
    }

    return x0.
}

function steppedSearch {
    parameter f.    
    parameter x0.
    parameter s0.
    parameter sMin.
    parameter c.

    local d is 10^(s0-1).

    local prevDir is 0.
    local f0 is x0.

    for n in range(c + 1) {
        print n at (0, terminal:height - 1).
        local f10 is f(f0 - d).
        local f1 is f(f0).
        local f11 is f(f0 + d).
        
        if (f10 < f1) {
            set f0 to f0 - d.
            if prevDir > 0 {
                set s0 to s0 - 1.
                set d to 10^s0.
            }
            set prevDir to -1.
        } else if (f11 < f1) {
            set f0 to f0 + d.
            if prevDir < 0 {
                set s0 to s0 - 1.
                set d to 10^s0.
            }
            set prevDir to 1.
        } else {
            set s0 to s0 - 1.
            set d to 10^s0.

            if prevDir > 0 {
                set f0 to f0 - d.
                set prevDir to -1.
            } else {
                set f0 to f0 + d.
                set prevDir to 1.
            }
        }

        if s0 < sMin {
            return f0.
        }
    }
}
