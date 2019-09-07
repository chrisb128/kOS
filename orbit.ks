run once math.
run once vec.

global function drawOrbitVelocityVectors {
    parameter vecList is list(),
              e is ship:obt:eccentricity,
              sma is ship:obt:semiMajorAxis,
              w is ship:obt:argumentOfPeriapsis,
              lan is ship:obt:lan,
              i is ship:obt:inclination,
              b is ship:obt:body.

    if (vecList:length <> 90) {
        vecList:clear().

        for _ in range(90) {
            local v is vecDraw(
                V(0, 0, 0), V(0, 0, 0),
                RGB(0, 1, 0), "",
                100.0, true, 0.001, true, true
            ).
            
            vecList:add(v).
        }
    }

    for n in range(90) {
        local t is n * 4.
        local newVec is stateVectorsAtTrueAnomaly(e, sma, w, lan, i, t, b).
        local st is newVec[0]:vec.
        local v is newVec[1]:vec.

        set vecList[n]:startupdater to { return st + b:position. }.
        set vecList[n]:vec to v.
        set vecList[n]:show to true.
    }

    return vecList.
}
