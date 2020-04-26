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
        "speed", newVelocityEase(cfg:speedEase),
        "heading", newVelocityEase(cfg:headEase),
        "altitude", newVelocityEase(cfg:altEase),
        "startPoint", ship:geoposition,
        "initialHead", -1,
        "liftPoint", ship:geoposition
    ).

    local setSpeed is {
        parameter _this, speed, ease is true.
        
        if (_this:speed:targetValue <> speed) {
            local curSpeed is speed.
            if (ease) {
                set curSpeed to ship:velocity:surface:mag.
            }
            _this:speed:setTargetValue(speed, curSpeed).
        }
    }.

    set this["setSpeed"] to setSpeed:bind(this).

    local setHeading is {
        parameter _this, head, ease is true.

        if (_this:heading:targetValue <> head) {
            local curHead is head.
            if (ease) {
                set curHead to getShipHeading().
            }
            _this:heading:setTargetValue(head, curHead).
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
        } else if (nav:currentWaypoint < plan:waypoints:length and (targetDistance < 200 or (targetDistance < 1000 and targetDistance > nav:waypointDistance))) {
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
        if (d < 1000 and d > nav:waypointDistance) {
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
        if nav:heading:getCurrentValue() = 0 {
            nav:setHeading(plan:origin:end:heading).
        }

        if (ship:bounds:bottomaltradar < 1) {
            set nav:liftPoint to ship:geoposition.
        }

        nav:setSpeed(plan:cruiseSpeed, false).
        nav:setAltitude(plan:cruiseAltitude, false).
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

        nav:setAltitude(min(1000, max(terrainHeight, terrainHeight + (startDistance - 500) / 20)), false).

        local minSpeed is 120.
        nav:setSpeed(min(plan:cruiseSpeed, max(minSpeed, minSpeed + startDistance / 400)), false).

        if (not closeTo(plan:destination:start)) {
            local correction is (plan:destination:end:heading - plan:destination:start:heading) * -5.
            nav:setHeading(nav:target:heading + correction, false).
        } else {
            set nav:target to plan:destination:end.
            nav:setAltitude(terrainHeight, false).
            nav:setHeading(nav:target:heading, false).
        }

    } else if (nav:mode = "land") {
        nav:setAltitude(plan:destination:end:terrainheight, false).
        nav:setHeading(plan:destination:end:heading).
        nav:setSpeed(75, false).

    } else if (nav:mode = "break") {
        nav:setAltitude(plan:destination:end:terrainheight, false).
        nav:setHeading(plan:destination:end:heading).
        nav:setSpeed(1, false).
    } else if (nav:mode = "fixed") {
        nav:setAltitude(plan:cruiseAltitude, false).
        nav:setHeading(nav:initialHead).
        nav:setSpeed(plan:cruiseSpeed, false).     
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