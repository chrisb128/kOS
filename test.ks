run once airplane.
run once circle.

brakes on.

local autopilot is initAutopilot().

local cruiseAltitude is 10000.
local approachAltitude is 1000.
local cruiseSpeed is 660.

local targetAltitude is cruiseAltitude. // m
local targetSpeed is 300.     // m/s

local islandRunway is latlng(-1.54083, -71.90972).
local dessertRunway is latlng(-6.52, -144.03).


local kscRunwayStart is latlng(-0.0485997, -74.724375).
local kscRunwayEnd is latlng(-0.0502119, -74.489998).
local ksc270ApproachStart is latlng(-0.1, -72.5).


countdown(3).

clearscreen.

until ship:maxThrust > 0 {
    stage.
}

brakes off.
sas off.

on (ship:bounds:bottomaltradar > 10) {
    gear off.
}

local ascending is true.
local landing is false.
local onApproach is false.
local targetLatLng is latlng(0,0).

// flight plan
on (abs(targetAltitude - ship:altitude) < 10) { // once we reach altitude
    set autopilot:lockRoll to false.
    set targetLatLng to dessertRunway.
    set ascending to false.

    on (abs(getShipHeading() - targetLatLng:heading) < 1) {

        set targetSpeed to cruiseSpeed.
    }

    on (dessertRunway:distance < 5000) {
        set targetAltitude to approachAltitude.
        set targetSpeed to 100.

        on (ksc270ApproachStart:distance < 5000) {
            set onApproach to true.
            set targetLatLng to kscRunwayEnd.
            set targetSpeed to 100.

            //TODO: use distance left/right from runway axis to calc proper incoming heading
            on (kscRunwayEnd:distance < 300) {
                set onApproach to false.
                set targetLatLng to kscRunwayStart.
                gear on.
                set landing to true.

                kUniverse:pause().
            }
        }
    }

}

local touchdown is false.
local touchdownTime is 0.
until false {
    logInfo("Current Pos: " + formatLatLng(ship:geoposition), 20).
    logInfo("Target  Pos: " + formatLatLng(targetLatLng), 21).
    logInfo("Target Dist: " + targetLatLng:distance, 22).

    if (ascending) {
        logMission("Takeoff").
    } else if (not landing and not onApproach) {
        logMission("Cruising").
    } else if (onApproach and not landing) {
        logMission("On Approach").
    } else if (landing) {
        logMission("Landing").
    }

    if (touchdown) {
        logInfo("Touchdown " + round(time:seconds - touchdownTime) + "s ago", 22).
    } else if (not touchdown and touchdownTime > 0) {
        logInfo("Bounce", 22).
    }

    setAutopilotPitchRange(autopilot, 15).

    local targetHeading is targetLatLng:heading.
    if ascending {
        set targetHeading to getShipHeading().

        if (ship:altitude < 200) {
            setAutopilotPitchRange(autopilot, min(25.0, max(7, ship:bounds:bottomaltradar / 10))).
        }
    }


    if (onApproach) {
        // assume ksc landing

        if (abs(kscRunwayEnd:heading - kscRunwayStart:heading) > 0.1) {
            local bearingDiff is (kscRunwayStart:heading - kscRunwayEnd:heading) * -8.
            logInfo("Approach bearing adj: " + bearingDiff, 23).
            set targetHeading to targetHeading + bearingDiff.
        }

        if (kscRunwayEnd:distance < 8000) {
            set targetSpeed to 75.
            setAutopilotVertSpeedRange(autopilot, 30).
            set targetAltitude to 60 + targetLatLng:terrainheight.
        }
    }

    if (landing) {

        set targetSpeed to 0.
        brakes on.
        set targetAltitude to targetLatLng:terrainHeight - 1.
        setAutopilotVertSpeedRange(autopilot, 20).

        if ((ship:bounds:bottomaltradar) < 60) {
            setAutopilotVertSpeedRange(autopilot, 20).
        }

        if ((ship:bounds:bottomaltradar) < 30) {
            setAutopilotVertSpeedRange(autopilot, 0.5).
        }

        if (ship:bounds:bottomaltradar < 15) {
            // lock pitch to 20 until wheels touch down
            set autopilot:pitchPid:maxoutput to 18.
            set autopilot:pitchPid:minoutput to 18.

            set autopilot:vSpeedPid:maxoutput to 50.
            set autopilot:vSpeedPid:minoutput to 50.
        }

        if (ship:bounds:bottomaltradar < 1) {
            if touchdown and (time:seconds - touchdownTime) >= 2 {
                unlock all.
                sas on.
                break.
            } else if (not touchdown) {
                setAutopilotPitchRange(autopilot, 0).
                setAutopilotVertSpeedRange(autopilot, 0).

                set touchdown to true.
                set touchdownTime to time:seconds.
            }
        } else if (touchdown) {
            set touchdown to false.
            set touchdownTime to 0.
        }
    }

    autopilotLoop(autopilot, targetSpeed, targetAltitude, targetHeading).
    wait 0.
}

logMission("Breaking").

wait until (ship:velocity:surface:mag < 0.1).
logMission("FINISHED").
