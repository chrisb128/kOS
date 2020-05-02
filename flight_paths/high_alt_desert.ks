global function high_alt_desert {
    
    local startPt is createWaypoint(400, 11000, locationAfterDistanceAtHeading(kscEast:end, 270, 70000)).
    local speedUp is createWaypoint(850, 12000, locationAfterDistanceAtHeading(startPt:location, 270, 50000)).

    local slowDown is createWaypoint(850, 12000, dessertSouth:approach).
    local turnAround is createWaypoint(300, 5000, locationAfterDistanceAtHeading(dessertNorth:approach, 270, 40000)).
    local endPt is createWaypoint(300, 5000, locationAfterDistanceAtHeading(dessertNorth:approach, 0, 40000)).
    
    return createFlightPlan(300, 9000,
        list(
            startPt, 
            speedUp,
            slowDown,
            turnAround,
            endPt
        ),
        kscEast,
        dessertNorth
    ).
}