run once circle.
run once airplane.


global function createFlightPlan {
    parameter cruiseSpeed.
    parameter cruiseAltitude.
    parameter waypoints.
    parameter destination.
    parameter climbSpeed.
    parameter climbRatio.
    parameter throttleRatio.

    return lexicon(
        "cruiseSpeed", cruiseSpeed,
        "cruiseAltitude", cruiseAltitude,
        "waypoints", waypoints,
        "destination", destination,
        "climbSpeed", climbSpeed,
        "climbRatio", climbRatio,
        "throttleRatio", throttleRatio
    ).
}

global function createWaypoint {
    parameter speed.
    parameter altitude.
    parameter location.

    return lexicon(
        "speed", speed,
        "altitude", altitude,
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

    return lexicon(
        "plan", (plan),
        "autopilot", initAutopilot(),
        "target", ship:geoposition,
        "currentWaypoint", (-1),
        "waypointDistance", (-1),
        "mode", "idle",
        "speed", 0,
        "heading", 0,
        "altitude", ship:altitude,
        "startPoint", ship:geoposition,
        "liftPoint", ship:geoposition
    ).
}

local function closeTo {
    parameter target.
    local closeDistance is 1000.
    return distanceTo(target) < closeDistance.
}

global function navigatorSetWaypoint {
    parameter nav.

    local plan is nav:plan.
    if (nav:mode = "cruise") {
        if  (nav:currentWaypoint < 0) {
            set nav:currentWaypoint to 0.
            set nav:target to plan:waypoints[nav:currentWaypoint]:location.
        } else if (nav:currentWaypoint < plan:waypoints:length and distanceTo(nav:target) > nav:waypointDistance) {
            set nav:currentWaypoint to nav:currentWaypoint + 1.

            if (nav:currentWaypoint < plan:waypoints:length) {
                set nav:target to plan:waypoints[nav:currentWaypoint]:location.
            } else {
                set nav:target to plan:destination:approach.
            }
        }
    } else if (nav:mode = "approach") {
        if (nav:currentWaypoint = plan:waypoints:length) {
            set nav:target to plan:destination:approach.
        }

        if (distanceTo(nav:target) > nav:waypointDistance and nav:currentWaypoint = plan:waypoints:length) {
            set nav:target to plan:destination:start.
            set nav:currentWaypoint to -1.
        }
    }

    if (nav:currentWaypoint >= 0) {
        set nav:waypointDistance to distanceTo(nav:target).
}
}

global function navigatorUpdateFlightMode {
    parameter nav.

    local plan is nav:plan.


    if (nav:mode = "ascend"
        and abs(plan:cruiseAltitude - ship:altitude) < 10) {
        set nav:mode to "cruise".
    }

    if (nav:mode = "cruise"
        and nav:currentWaypoint = plan:waypoints:length
        and closeTo(plan:destination:approach)) {
        set nav:mode to "approach".
    } else if (nav:mode = "approach") {
        if (distanceTo(plan:destination:start) < 500) {
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

global function navigatorSetAutopilotParams {
    parameter nav.
    local plan is nav:plan.

    if (nav:mode = "ascend") {
        if (ship:bounds:bottomaltradar < 1) {
            nav:autopilot:pitchPid:reset().
            nav:autopilot:pitchRotPid:reset().
            nav:autopilot:pitchCtlPid:reset().
        }

        setAutopilotPitchRange(nav:autopilot,
            max(-20.0, min(7, 7-(ship:bounds:bottomaltradar / 20))),
            min(20.0, max(7, ship:bounds:bottomaltradar / 20))).

    } else if (nav:mode = "cruise") {
        setAutopilotPitchRange(nav:autopilot, -20, 20).

    } else if (nav:mode = "approach") {

        setAutopilotPitchRange(nav:autopilot,
            max(-20.0, min(1, 1-(ship:bounds:bottomaltradar / 20))),
            min(20.0, max(4, ship:bounds:bottomaltradar / 20))).

    } else if (nav:mode = "land") {
        if (ship:bounds:bottomaltradar < 1) {
            setAutopilotPitchRange(nav:autopilot, 0, 0).
        }
    }
}

global function navigatorSetTargets {
    parameter nav.
    local plan is nav:plan.

    if (nav:mode = "ascend") {
        if (nav:heading = 0) {
            set nav:heading to getShipHeading().
        }
        if (ship:bounds:bottomaltradar < 1) {
            set nav:liftPoint to ship:geoposition.
        }

        set nav:speed to max(20, min(plan:climbSpeed, log10(1.4 + distanceTo(nav:startPoint) / plan:throttleRatio) * plan:climbSpeed)).
        set nav:altitude to max(nav:liftPoint:terrainHeight, min(plan:cruiseAltitude, (distanceTo(nav:liftPoint) / plan:climbRatio) + nav:liftPoint:terrainHeight)).
    }
    else if (nav:mode = "cruise") {
        local waypoint is plan:destination:approach.
        if (nav:currentWaypoint < plan:waypoints:length)
            set waypoint to plan:waypoints[nav:currentWaypoint].

        set nav:heading to waypoint:location:heading.
        set nav:speed to waypoint:speed.
        set nav:altitude to waypoint:altitude.
    }
    else if (nav:mode = "approach") {
        set nav:heading to nav:target:heading.
        set nav:altitude to min(plan:cruiseAltitude, max(plan:destination:start:terrainheight, plan:destination:start:terrainheight + distanceTo(plan:destination:start) / 10)).
        set nav:speed to max(50, min(plan:cruiseSpeed, 50 + distanceTo(plan:destination:start) / 60)).

        if (not closeTo(plan:destination:start)) {
            local correction is (plan:destination:end:heading - plan:destination:start:heading) * -10.
            set nav:heading to nav:heading + correction.
        }

        if (distanceTo(plan:destination:start) < 500) {
            set nav:target to plan:destination:end.
            set nav:altitude to plan:destination:start:terrainheight.
        }
    } else if (nav:mode = "land") {
        set nav:altitude to plan:destination:end:terrainheight.
        set nav:heading to plan:destination:end:heading.
        set nav:speed to min(nav:speed, max(50, ship:bounds:bottomaltradar)).

    } else if (nav:mode = "break") {
        set nav:altitude to plan:destination:end:terrainheight.
        set nav:heading to plan:destination:end:heading.
        set nav:speed to 0.
    }
}

global function navigatorSetShipControls {
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