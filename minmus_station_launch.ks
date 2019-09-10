run once mission.

clearScreen.


if ship:status = "PRELAUNCH" {
    runStep(launchToOrbit(121000, true, true, true, true, 5)).
        
    kuniverse:quicksave().

    logStatus("Waiting for next module").
    wait 10.
}

transferToSatellite(lexicon("targetBody", minmus, "targetAp", 500000, "autoWarpToSoi", true)).

zeroInclination().