declare function hohmannDV1 {
    parameter mu.
    parameter r1.
    parameter r2.

    return sqrt( mu / r1 ) * ( sqrt( (2*r2) / (r1+r2) ) - 1 ).
}

declare function hohmannDV2 {
    parameter mu.
    parameter r1.
    parameter r2.

    return sqrt( mu / r2 ) * ( 1 - sqrt( (2*r1) / (r1+r2) ) ).
}

declare function hohmannTargetAngle {
    parameter r1.
    parameter r2.

    return 360 - ((constant:pi * ( (1-(1/(2*sqrt(2)))) * sqrt( ((r1/r2)+1)^3 ))) * constant:radToDeg).
}
