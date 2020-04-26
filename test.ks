run once navigator.
run once energy.
run once runways.
run once attitude.
run once airplane.
run once flight_plan.
run once "0:/flight_paths/med_loop.ks".

print "Press any key to start".
terminal:input:getchar().
clearscreen.

if (ship:maxthrust <= 0) {
    stage.
}

local cfg is lexicon(
    "rollRange", 30,
    "rollResponse", 1.0,
    "pitchRange", 30,
    "ascentMinPitch", 8,
    "headEase", 15, 
    "speedEase", 5,
    "altEase", 150,
    "attitudeResponse", 1,
    "stoppingTime", 2
).

local startPt is createWaypoint(450, 7000, latlng(0,0)).
local climbOne is createWaypoint(900, 8000, latlng(0,0)).
local climbTwo is createWaypoint(1200, 15000, latlng(0,0)).
local levelOut is createWaypoint(1200, 17000, latlng(0,0)).
local speedUp is createWaypoint(1400, 19000, latlng(0,0)).


local pilot is initAutopilot(med_loop_plan(), cfg).
pilot:initLogs().

ON AG9 {  
    
    set pilot:attitude:axis:x to 0.
    set pilot:attitude:axis:y to 0.
    set pilot:attitude:axis:z to 0.

    preserve. 
}.

ON AG8 { 
    set pilot:attitude:axis:x to 1.
    set pilot:attitude:axis:y to 1.
    set pilot:attitude:axis:z to 1.

    preserve. 
}.

lock throttle to pilot:throttle.

local quit is false.

on AG7 { set quit to true. }.


until quit {
    
    // // custom waypoint execution - only pay attention to altitude/speed
    // if (pilot:nav:mode = "cruise" and pilot:nav:currentWaypoint > 0) {
    //     local currentWaypoint is plan:waypoints[pilot:nav:currentWaypoint].        
    //     set currentWaypoint:location to locationAfterDistanceAtHeading(ship:geoposition, 90, 10000).
    // }

    pilot:drive().
    
    // // custom waypoint execution - only pay attention to altitude/speed
    // if (pilot:nav:mode = "cruise" and pilot:nav:currentWaypoint > 0) {
    //     local currentWaypoint is plan:waypoints[pilot:nav:currentWaypoint].
    //     local shipSpeed is ship:velocity:surface:mag.
    //     local shipAlt is ship:altitude.

    //     if (pilot:nav:currentWaypoint < plan:waypoints:length
    //         and (shipAlt > currentWaypoint:tgtAlt)) {
    //         set pilot:nav:currentWaypoint to max(plan:waypoints:length - 1, pilot:nav:currentWaypoint + 1).
    //     }
    // }

    wait 0.
}
