run once circle.
run once airplane.


global function createFlightPlan {
    parameter cruiseSpeed.
    parameter cruiseAltitude.
    parameter waypoints.
    parameter origin.
    parameter destination.
    parameter climbSpeed.
    parameter climbRatio.
    parameter throttleRatio.

    return lexicon(
        "cruiseSpeed", cruiseSpeed,
        "cruiseAltitude", cruiseAltitude,
        "waypoints", waypoints,
        "origin", origin,
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

local function newVelocityEase {
    parameter velocityToEase.
    
    local this is lexicon(
        "velToEase", velocityToEase,
        "targetValue", 0,
        "targetSetTime", 0,
        "startValue", 0
    ).

    local getCurrentValue is {
        parameter _this.

        if _this:targetSetTime = 0 {
            return 0.
        }

        local currentVal is _this:velToEase * (time:seconds - _this:targetSetTime).

        if (_this:targetValue > _this:startValue) {
            return min(_this:targetValue, _this:startValue + currentVal).
        } else {
            return max(_this:targetValue, _this:startValue - currentVal).
        }
    }.
    set this["getCurrentValue"] to getCurrentValue:bind(this).

    local setTargetValue is {
        parameter _this.
        parameter targetValue.
        parameter currentValue.

        set _this:targetValue to targetValue.
        set _this:startValue to currentValue.
        set _this:targetSetTime to time:seconds.
    }.
    set this["setTargetValue"] to setTargetValue:bind(this).
    
    return this.
}

global function initNavigator {
    parameter plan.

    local this is lexicon(
        "plan", (plan),
        "autopilot", newAutopilot(),
        "target", ship:geoposition,
        "currentWaypoint", (-1),
        "waypointDistance", (-1),
        "mode", "idle",
        "speed", newVelocityEase(10),
        "heading", newVelocityEase(1),
        "altitude", newVelocityEase(50),
        "startPoint", ship:geoposition,
        "liftPoint", ship:geoposition
    ).

    local setSpeed is {
        parameter _this.
        parameter speed.
        
        if (_this:speed:targetValue <> speed) {
            _this:speed:setTargetValue(speed, ship:velocity:surface:mag).
        }
    }.

    set this["setSpeed"] to setSpeed:bind(this).

    local setHeading is {
        parameter _this.
        parameter heading.

        if (_this:heading:targetValue <> heading) {
            // _this:heading:setTargetValue(heading, getShipHeading()). 
            // TODO: implement momentum based velocity easer
            _this:heading:setTargetValue(heading, heading).
        }
    }.
    set this["setHeading"] to setHeading:bind(this).

    local setAltitude is {
        parameter _this.
        parameter altitude.

        if (_this:altitude:targetValue <> altitude) {
            _this:altitude:setTargetValue(altitude, ship:altitude).
        }
    }.
    set this["setAltitude"] to setAltitude:bind(this).

    return this.
}

local function closeTo {
    parameter target.
    local closeDistance is 1000.
    return distanceTo(target) < closeDistance.
}

global function navigatorSetWaypoint {
    parameter nav.

    local plan is nav:plan.
    if (nav:mode = "ascend") {
        set nav:target to plan:origin:end.

        if (ship:bounds:bottomaltradar > 10) {
            set nav:target to locationAfterDistanceAtHeading(plan:origin:end, plan:origin:end:heading, 5000).

            if (nav:waypointDistance = -1) {
                set nav:waypointDistance to distanceTo(plan:waypoints[0]:location).
            }

            if (distanceTo(plan:waypoints[0]:location) > nav:waypointDistance) {
                set nav:mode to "cruise".
            } else {
                set nav:waypointDistance to distanceTo(plan:waypoints[0]:location).
            }
        }
    }
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
            nav:autopilot:pitchRotPid:reset().
            nav:autopilot:pitchCtlPid:reset().
        }

        local pitchFloor is 15.
        setAutopilotPitchRange(nav:autopilot,
            max(-20.0, min(pitchFloor, pitchFloor-(ship:bounds:bottomaltradar / 20))),
            min(20.0, max(pitchFloor, ship:bounds:bottomaltradar / 20))).

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
        if nav:heading:getCurrentValue() = 0 {
            nav:setHeading(plan:origin:end:heading).
        }

        if (ship:bounds:bottomaltradar < 1) {
            set nav:liftPoint to ship:geoposition.
        }

        nav:setSpeed(plan:climbSpeed).
        nav:setAltitude(plan:cruiseAltitude).
    }
    else if (nav:mode = "cruise") {
        local waypoint is plan:destination:approach.
        if (nav:currentWaypoint < plan:waypoints:length) {
            set waypoint to plan:waypoints[nav:currentWaypoint].
        }

        nav:setHeading(waypoint:location:heading).
        nav:setSpeed(waypoint:speed).
        nav:setAltitude(waypoint:altitude).
    }
    else if (nav:mode = "approach") {
        nav:setHeading(nav:target:heading).
        nav:setAltitude(min(plan:cruiseAltitude, max(plan:destination:start:terrainheight, plan:destination:start:terrainheight + distanceTo(plan:destination:start) / 10))).
        nav:setSpeed(max(50, min(plan:cruiseSpeed, 50 + distanceTo(plan:destination:start) / 60))).

        if (not closeTo(plan:destination:start)) {
            local correction is (plan:destination:end:heading - plan:destination:start:heading) * -10.
            nav:setHeading(nav:target:heading + correction).
        }

        if (distanceTo(plan:destination:start) < 500) {
            set nav:target to plan:destination:end.
            nav:setAltitude(plan:destination:start:terrainheight).
        }
    } else if (nav:mode = "land") {
        nav:setAltitude(plan:destination:end:terrainheight).
        nav:setHeading(plan:destination:end:heading).
        nav:setSpeed(min(nav:speed, max(50, ship:bounds:bottomaltradar))).

    } else if (nav:mode = "break") {
        nav:setAltitude(plan:destination:end:terrainheight).
        nav:setHeading(plan:destination:end:heading).
        nav:setSpeed(0).
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