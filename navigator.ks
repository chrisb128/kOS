run once ease.
run once circle.

global function initNavigator {
    parameter plan, cfg.

    local this is lexicon(
        "plan", (plan),
        "cfg", (cfg),
        "target", ship:geoposition,
        "currentWaypoint", (-1),
        "waypointDistance", (-1),
        "mode", "idle",
        "speed", 0,
        "heading", 0,
        "altitude", 0,
        "startPoint", ship:geoposition,
        "initialHead", -1,
        "liftPoint", ship:geoposition
    ).

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
    
    local closeDistance is ((ship:velocity:surface:mag - 100) / 0.2) + 1000.

    return distanceTo(target) < closeDistance.
}

local function navigatorSetWaypoint {
    parameter nav.

    local plan is nav:plan.
    local closeToTarget is closeTo(nav:target).
    local targetDistance is distanceTo(nav:target).

    if (nav:mode = "ascend") {
        set nav:target to plan:origin:end.
        if (nav:initialHead = -1) {
            set nav:initialHead to plan:origin:end:heading.
        }

        if (ship:bounds:bottomaltradar > 10) {
            set nav:target to locationAfterDistanceAtHeading(plan:origin:end, nav:initialHead, 10000).
        }
    } else if (nav:mode = "cruise") {
        set nav:initialHead to -1.
        if  (nav:currentWaypoint < 0) {
            set nav:currentWaypoint to 0.
            set nav:target to plan:waypoints[nav:currentWaypoint]:location.
        } else if (nav:currentWaypoint < plan:waypoints:length and closeToTarget and targetDistance > nav:waypointDistance) {
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
    } else if (nav:mode = "fixed") {
        
        if (nav:initialHead = -1) {
            set nav:initialHead to getShipHeading().
        }

        if (ship:bounds:bottomaltradar > 10) {
            set nav:target to locationAfterDistanceAtHeading(ship:geoposition, nav:initialHead, 10000).
        }
    }

    if (nav:currentWaypoint >= 0) {
        set nav:waypointDistance to distanceTo(nav:target).
    }
}

local function navigatorUpdateFlightMode {
    parameter nav.

    local plan is nav:plan.

    if (nav:mode = "ascend"
        and abs(plan:cruiseAltitude - ship:altitude) < (0.05 * plan:cruiseAltitude)) {
        set nav:mode to "cruise".
    }

    if (nav:mode = "cruise"
        and nav:currentWaypoint = plan:waypoints:length 
        and closeTo(plan:destination:approach)) {
        set nav:mode to "approach".
    } else if (nav:mode = "approach") {
        local d is distanceTo(plan:destination:start).
        if (closeTo(plan:destination:start) and d > nav:waypointDistance) {
            set nav:mode to "land".
        } else {
            set nav:waypointDistance to d.
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
        if nav:heading = 0 {
            set nav:heading to plan:origin:end:heading.
        }

        if (ship:bounds:bottomaltradar < 1) {
            set nav:liftPoint to ship:geoposition.
        }

        set nav:speed to plan:cruiseSpeed.
        set nav:altitude to plan:cruiseAltitude.
    }
    else if (nav:mode = "cruise") {
        if (nav:currentWaypoint < plan:waypoints:length) {
            
            local waypoint to plan:waypoints[nav:currentWaypoint].
            
            local wSpd is waypoint:speed.
            local wAlt is waypoint:altitude.

            if (nav:currentWaypoint > 0) {
                local prevWaypoint is plan:waypoints[nav:currentWaypoint-1].
                local totalDist is distanceBetween(prevWaypoint:location, waypoint:location, ship:altitude + ship:body:radius).

                local dist is min(totalDist, distanceTo(prevWaypoint:location)).

                local distRatio is dist/totalDist.

                local startSpd is prevWaypoint:speed.
                local startAlt is prevWaypoint:altitude.

                set wSpd to startSpd + (distRatio * (wSpd - startSpd)).
                set wAlt to startAlt + (distRatio * (wAlt - startAlt)).
            }

            if (not closeTo(waypoint:location)) {
                set nav:heading to waypoint:location:heading.
            }

            set nav:speed to  wSpd.
            set nav:altitude to wAlt.
        } else {
            
            set nav:heading to plan:destination:approach:heading.
            set nav:speed to plan:cruiseSpeed.
            
            local terrainHeight is max(plan:destination:end:terrainheight, plan:destination:start:terrainheight) + 5.
            set nav:altitude to 1000 + terrainHeight.
        }
    }
    else if (nav:mode = "approach") {
        set nav:heading to nav:target:heading.
        local terrainHeight is max(plan:destination:end:terrainheight, plan:destination:start:terrainheight) + 5.
        local startDistance is distanceTo(plan:destination:start).

        set nav:altitude to min(1000 + terrainHeight, max(terrainHeight, terrainHeight + (startDistance - 500) / 20)).

        local minSpeed is 120.
        set nav:speed to min(plan:cruiseSpeed, max(minSpeed, minSpeed + startDistance / 400)).

        if (not closeTo(plan:destination:start)) {
            local correction is (plan:destination:end:heading - plan:destination:start:heading) * -5.
            set nav:heading to (nav:target:heading + correction).
        } else {
            set nav:target to plan:destination:end.
            set nav:altitude to terrainHeight.
            set nav:heading to nav:target:heading.
        }

    } else if (nav:mode = "land") {
        set nav:altitude to plan:destination:end:terrainheight.
        set nav:heading to plan:destination:end:heading.
        set nav:speed to 75.

    } else if (nav:mode = "break") {
        set nav:altitude to plan:destination:end:terrainheight.
        set nav:heading to plan:destination:end:heading.
        set nav:speed to 1.
    } else if (nav:mode = "fixed") {
        set nav:altitude to plan:cruiseAltitude.
        set nav:heading to nav:initialHead.
        set nav:speed to plan:cruiseSpeed.
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
}