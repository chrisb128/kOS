run once ease.
run once circle.


global function createFlightPlan {
    parameter cruiseSpeed.
    parameter cruiseAltitude.
    parameter waypoints.
    parameter origin.
    parameter destination.

    return lexicon(
        "cruiseSpeed", cruiseSpeed,
        "cruiseAltitude", cruiseAltitude,
        "waypoints", waypoints,
        "origin", origin,
        "destination", destination
    ).
}

global function createWaypoint {
    parameter speed.
    parameter tgtAlt.
    parameter location.

    return lexicon(
        "speed", speed,
        "altitude", tgtAlt,
        "location", location).
}

global function getWaypointsBetween {
    parameter start.
    parameter finish.
    parameter separation is 1000.

    local waypointLocations is computeWaypoints(start:location, finish:location, start:altitude, separation).

    local waypoints is list().
    local altitudeChange is finish:altitude - start:altitude.
    local speedChange is finish:speed - start:speed.
    from { local i is 0. }
    until (i >= waypointLocations:length)
    step { set i to i + 1. } do {
        local currentAlt is i * (altitudeChange / waypoints:length) + start:altitude.
        local currentSpeed is i * (speedChange / waypoints:length) + start:speed.

        waypoints:add(
            createWaypoint(currentSpeed, currentAlt, waypointLocations[i])
        ).
    }

    return waypoints.
}


global function initNavigator {
    parameter plan.

    local this is lexicon(
        "plan", (plan),
        "target", ship:geoposition,
        "currentWaypoint", (-1),
        "waypointDistance", (-1),
        "mode", "idle",
        "speed", newVelocityEase(1),
        "heading", newVelocityEase(1),
        "altitude", newVelocityEase(1),
        "startPoint", ship:geoposition,
        "liftPoint", ship:geoposition
    ).

    local setSpeed is {
        parameter _this.
        parameter speed.
        
        if (_this:speed:targetValue <> speed) {
            _this:speed:setTargetValue(speed, speed).
        }
    }.

    set this["setSpeed"] to setSpeed:bind(this).

    local setHeading is {
        parameter _this.
        parameter head.

        if (_this:heading:targetValue <> head) {
            // _this:heading:setTargetValue(heading, getShipHeading()). 
            // TODO: implement momentum based velocity easer
            _this:heading:setTargetValue(head, head).
        }
    }.
    set this["setHeading"] to setHeading:bind(this).

    local setAltitude is {
        parameter _this, tgtAlt, ease is true.

        if (_this:altitude:targetValue <> tgtAlt) {
            local curAlt is tgtAlt.
            if (ease) {
                set curAlt to ship:altitude.
            }
            _this:altitude:setTargetValue(tgtAlt, curAlt).
        }
    }.
    set this["setAltitude"] to setAltitude:bind(this).

    local setWaypoint is { parameter _this. navigatorSetWaypoint(_this).}.
    set this:setWaypoint to setWaypoint:bind(this).
    
    local updateFlightMode is { parameter _this. navigatorUpdateFlightMode(_this).}.
    set this:updateFlightMode to updateFlightMode:bind(this).

    local setTargets is { parameter _this. navigatorSetTargets(_this).}.
    set this:setTargets to setTargets:bind(this).

    local setShipControls is { parameter _this. navigatorSetShipControls(_this).}.
    set this:setShipControls to setShipControls:bind(this).

    return this.
}

local function closeTo {
    parameter target.
    local closeDistance is 1000.
    return distanceTo(target) < closeDistance.
}

local function navigatorSetWaypoint {
    parameter nav.

    local plan is nav:plan.
    if (nav:mode = "ascend") {
        set nav:target to plan:origin:end.

        if (ship:bounds:bottomaltradar > 10) {
            set nav:target to locationAfterDistanceAtHeading(plan:origin:end, plan:origin:end:heading, 10000).

            if (nav:waypointDistance = -1) {
                set nav:waypointDistance to distanceTo(nav:target).
            }

            if (distanceTo(nav:target) > nav:waypointDistance) {
                set nav:mode to "cruise".
            } else {
                set nav:waypointDistance to distanceTo(nav:target).
            }
        }
    }
    
    local targetDistance is distanceTo(nav:target).
    if (nav:mode = "cruise") {
        if  (nav:currentWaypoint < 0) {
            set nav:currentWaypoint to 0.
            set nav:target to plan:waypoints[nav:currentWaypoint]:location.
        } else if (nav:currentWaypoint < plan:waypoints:length and targetDistance < 1000 and targetDistance > nav:waypointDistance) {
            set nav:currentWaypoint to nav:currentWaypoint + 1.
            if (nav:currentWaypoint < plan:waypoints:length) {
                set nav:target to plan:waypoints[nav:currentWaypoint]:location.
            } else {
                set nav:currentWaypoint to plan:waypoints:length.
                set nav:target to plan:destination:approach.
            }
        }
    } else if (nav:mode = "approach") {
        set nav:target to plan:destination:start.
        set nav:waypointDistance to distanceTo(plan:destination:start).
    }

    if (nav:currentWaypoint >= 0) {
        set nav:waypointDistance to distanceTo(nav:target).
    }
}

local function navigatorUpdateFlightMode {
    parameter nav.

    local plan is nav:plan.

    if (nav:mode = "ascend"
        and abs(plan:cruiseAltitude - ship:altitude) < (0.01 * plan:cruiseAltitude)) {
        set nav:mode to "cruise".
    }

    if (nav:mode = "cruise"
        and nav:currentWaypoint = plan:waypoints:length 
        and closeTo(plan:destination:approach)) {
        set nav:mode to "approach".
    } else if (nav:mode = "approach") {
        local d is distanceTo(plan:destination:start).
        if (d < 1000 and d > nav:waypointDistance) {
            set nav:mode to "land".
        }
    } else if (nav:mode = "land") {
        if (ship:bounds:bottomaltradar < 1) {
            set nav:mode to "break".
        }
    } else if (nav:mode = "break") {
        if (ship:velocity:surface:mag < 0.1) {
            set nav:mode to "idle".
        }
    }
}

local function navigatorSetTargets {
    parameter nav.
    local plan is nav:plan.

    if (nav:mode = "ascend") {
        if nav:heading:getCurrentValue() = 0 {
            nav:setHeading(plan:origin:end:heading).
        }

        if (ship:bounds:bottomaltradar < 1) {
            set nav:liftPoint to ship:geoposition.
        }

        nav:setSpeed(plan:cruiseSpeed).
        nav:setAltitude(plan:cruiseAltitude).
    }
    else if (nav:mode = "cruise") {
        if (nav:currentWaypoint < plan:waypoints:length) {
            local waypoint to plan:waypoints[nav:currentWaypoint].
            
            nav:setHeading(waypoint:location:heading).
            nav:setSpeed(waypoint:speed).
            nav:setAltitude(waypoint:altitude).
        } else {
            
            nav:setHeading(plan:destination:approach:heading).
            nav:setSpeed(plan:cruiseSpeed).
            nav:setAltitude(1000).
        }
    }
    else if (nav:mode = "approach") {
        nav:setHeading(nav:target:heading).
        local terrainHeight is plan:destination:end:terrainheight + 1.
        local startDistance is distanceTo(plan:destination:start).

        nav:setAltitude(min(1000, max(terrainHeight, terrainHeight + startDistance / 20)), false).

        local minSpeed is 120.
        nav:setSpeed(min(plan:cruiseSpeed, max(minSpeed, minSpeed + startDistance / 400))).

        if (not closeTo(plan:destination:start)) {
            local correction is (plan:destination:end:heading - plan:destination:start:heading) * -10.
            nav:setHeading(nav:target:heading + correction).
        } else {
            set nav:target to plan:destination:end.
            nav:setAltitude(terrainHeight).
            nav:setHeading(nav:target:heading).
        }

    } else if (nav:mode = "land") {
        nav:setAltitude(plan:destination:end:terrainheight, false).
        nav:setHeading(plan:destination:end:heading).
        nav:setSpeed(min(75, ship:velocity:surface:mag)).

    } else if (nav:mode = "break") {
        nav:setAltitude(plan:destination:end:terrainheight, false).
        nav:setHeading(plan:destination:end:heading).
        nav:setSpeed(0.1).
    }
}

local function navigatorSetShipControls {
    parameter nav.

    if (nav:mode = "ascend") {
        brakes off.
        sas off.
        if (ship:bounds:bottomaltradar > 10) {
            gear off.
        }
    }
    if (nav:mode = "approach") {
        if (distanceTo(nav:plan:destination:start) < 500) {
            gear on.
        }
        if (distanceTo(nav:plan:destination:start) < 5000) {
            brakes on.
        }
    }
    if (nav:mode = "land") {
        gear on.
    }
    if (nav:mode = "break") {
        brakes on.
        sas on.
        unlock all.
    }
    if (nav:mode = "idle") {
    }
}