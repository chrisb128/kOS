global function med_loop {

    local startPt is createWaypoint(200, 3000, locationAfterDistanceAtHeading(kscWest:end, 90, 20000)).
    local legAxis is locationAfterDistanceAtHeading(startPt:location, 90, 20000).
    local turnNorth is createWaypoint(1100, 14000, locationAfterDistanceAtHeading(legAxis, 0, 80000)).
    local turnBack is createWaypoint(200, 3000, locationAfterDistanceAtHeading(legAxis, 90, 10000)).

    global med_loop_path is list(
        startPt,
        turnNorth,
        turnBack
    ).

    return createFlightPlan(200, 1000,
        med_loop_path,
        kscWest,
        kscEast
    ).
}
