run once airplane.
run once circle.

brakes on.

local autopilot is initAutopilot().

local targetAltitude is 1000. // m
local targetSpeed is 300.     // m/s
local targetHeading is 90.    // deg

local islandRunway is latlng(-1.54083, -71.90972).
local kscRunwayStart is latlng(-0.0485997, -74.724375).
local kscRunwayEnd is latlng(-0.0502119, -74.489998).
local ksc270ApproachStart is latlng(-0.06, -72.5).


countdown(3).

clearscreen.

until ship:maxThrust > 0 {
    stage.
}

brakes off.

on (ship:bounds:bottomaltradar > 10) {
    gear off.
}

local ascending is true.
local targetLatLng is latlng(0,0).

// flight plan
on (abs(targetAltitude - ship:altitude) < 10) { // once we reach altitude
    set targetLatLng to islandRunway.
    set ascending to false.

    on (islandRunway:distance < 2000) {
        set targetLatLng to ksc270ApproachStart.

        on (ksc270ApproachStart:distance < 5000) {
            set targetLatLng to kscRunwayEnd.
        }
    }

}


sas on.

unlock steering.
unlock throttle.

sas off.
until false {
    logInfo("Target Pos: " + targetLatLng, 20).
    logInfo("Target Dist: " + targetLatLng:distance, 21).

    local targetHeading is 90.
    if not ascending {
        set targetHeading to targetLatLng:heading.
    }

    if (ship:altitude < 200) {
        setAutopilotPitchRange(autopilot, min(15.0, ship:altitude / 10)).
    }

    autopilotLoop(autopilot, targetSpeed, targetAltitude, targetHeading).
    wait 0.
}