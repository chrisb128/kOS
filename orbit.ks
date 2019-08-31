run once vec.

local function drawOrbitVelocityVectors {
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
            vecList:add(vecDraw()).
        }
    }

    for n in range(90) {
        local Mt is n * 4.        
        local newVec is getTrueVectors(e, sma, w, lan, i, Mt, b).

        set vecList[n]:start to newVec[0] + b:position.
        set vecList[n]:vec to newVec[1].
        set vecList[n]:show to true.
    }

    return vecList.
}
