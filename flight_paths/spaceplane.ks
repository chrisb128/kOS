global function spaceplane_ascent {
    
    local ascent is createWaypoint(300, 9000, locationAfterDistanceAtHeading(kscWest:end, 90, 30000)).
    local startPt is nextWaypoint(ascent, 90, 30000, 650, 15000).
    local climb is nextWaypoint(startPt, 90, 30000, 850, 16000).
    local speedUp is nextWaypoint(climb, 90, 60000, 1600, 22000).
    local exitAtmo is nextWaypoint(speedUp, 90, 100000, 1800, 50000).
    local exitAtmo2 is nextWaypoint(exitAtmo, 90, 200000, 1800, 50000).

    local endPt is createWaypoint(300, 5000, locationAfterDistanceAtHeading(kscEast:approach, 270, 20000)).
    
    return createFlightPlan(300, 9000,
        list(
            ascent,
            startPt,
            climb, 
            speedUp,
            exitAtmo,
            exitAtmo2,
            endPt
        ),
        kscWest,
        kscEast
    ).
}