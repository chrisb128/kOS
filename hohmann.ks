// Compute Hohmann Transfer delta-V to enter the elliptical orbit at r=r1 from the r1 circular orbit
// climb-to-elliptical
// fall-to-circular
declare function hohmannDV1 {
    parameter mu.
    parameter r1. 
    parameter r2. 

    return sqrt( mu / r1 ) * ( sqrt( (2*r2) / (r1+r2) ) - 1 ).
}

// Compute Hohmann Transfer delta-V to leave the elliptical orbit at r=r2 to the r2 circular orbit
// climb-to-circular
// fall-to-elliptical
declare function hohmannDV2 {
    parameter mu.
    parameter r1. 
    parameter r2. 

    return sqrt( mu / r2 ) * ( 1 - sqrt( (2*r1) / (r1+r2) ) ).
}

// Compute required angle between source and destination in order to rendezvous at apoapsis
declare function hohmannTargetAngle {
    parameter r1.
    parameter r2.

    return 360 - ((constant:pi * ( (1-(1/(2*sqrt(2)))) * sqrt( ((r1/r2)+1)^3 ))) * constant:radToDeg).
}
