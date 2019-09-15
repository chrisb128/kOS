global function autoDock {
    parameter targetDock.
        
    rcs on.
    sas off.

    set target to targetDock.
    local tgt is target:ship.
    local shipDock is ship:controlpart.

    local vecToPort is vecDraw(
        shipDock:nodePosition, 
        targetDock:nodePosition,
        RGB(0.5, 0.5, 0.5), "", 1.0, true, 0.1, true, true
    ).

    set vecToPort:startupdater to { return shipDock:nodePosition. }.
    set vecToPort:vecupdater to { return targetDock:nodePosition. }.

    local shipDockVec is vecDraw(
        shipDock:nodePosition,
        shipDock:portFacing:forevector,
        RGB(1, 0, 0), "", 3.0, true, 0.1, true, true
    ).
    set shipDockVec:startupdater to { return shipDock:nodePosition. }.
    set shipDockVec:vecupdater to { return shipDock:portFacing:forevector. }.

    local targetDockVec is vecDraw(
        targetDock:nodePosition,
        targetDock:portFacing:forevector,
        RGB(0, 0, 1), "", 3.0, true, 0.1, true, true
    ).
    set targetDockVec:startupdater to { return targetDock:nodePosition. }.
    set targetDockVec:vecupdater to { return targetDock:portFacing:forevector. }.

    unlock steering.
    local shipTgtDir is V(0,0,0)-targetDock:portFacing:forevector.
    lock steering to lookDirUp(shipTgtDir, targetDock:portFacing:upVector).

    local shipTgtDirVec is vecDraw(
        shipDock:nodePosition,
        shipTgtDir,
        RGB(0, 0, 1), "", 3.0, true, 0.1, true, true
    ).
    set shipTgtDirVec:startupdater to { return shipDock:nodePosition. }.
    set shipTgtDirVec:vecupdater to { return shipTgtDir. }.


    logInfo("Aligning with docking port axis").
    wait until vAng(ship:facing:forevector, shipTgtDir) < 0.1.
    logInfo("Steering locked").


    if vDot(shipTgtDir, targetDock:nodePosition) < 0 {
        logStatus("!!!! ON WRONG SIDE !!!").
    }

    local distanceToDockAxis is 0.
    local distanceToDock is 0.
    local steerLock is ship:facing.
    unlock steering.
    lock steering to steerLock.


    until (targetDock:state <> "Ready" and targetDock:state <> "PreAttached") {

        local vecToTgtDock is (targetDock:nodePosition - shipDock:nodePosition).
        set distanceToDockAxis to vCrs(shipTgtDir, vecToTgtDock):mag.
        
        set distanceToDockPlane to sqrt(vecToTgtDock:mag^2 - distanceToDockAxis^2).
        set steerLock to lookDirUp(shipTgtDir, targetDock:portFacing:upVector).
            
        local vecToDockPlane is shipTgtDir:vec.
        set vecToDockPlane:mag to distanceToDock.
        local vecToDockAxis is (vecToTgtDock - vecToDockPlane).

        logInfo("Distance to dock axis: " + round(distanceToDockAxis, 2), 2).
        logInfo("Distance to dock plane: " + round(distanceToDockPlane, 2), 3).

        local relVel is tgt:velocity:orbit - ship:velocity:orbit.
        logInfo("Rel velocity: " + round(relVel:mag, 2) + "m/s", 4).

        local sf is ship:facing.
        local upVel is vDot(relVel, sf:upVector).
        local foreVel is vDot(relVel, sf:foreVector).
        local starVel is vDot(relVel, sf:starVector).

        local upToDockAxis is -vDot(vecToDockAxis, sf:upVector).
        local starToDockAxis is -vDot(vecToDockAxis, sf:starVector).
        logInfo("       Up to dock axis dist: " + round(upToDockAxis), 9).
        logInfo("Starboard to dock axis dist: " + round(starToDockAxis), 10).

        logInfo("  Rel Up velocity: " + round(upVel, 2) + "m/s", 5).
        logInfo("Rel Fore velocity: " + round(foreVel, 2) + "m/s", 6).
        logInfo("Rel Star velocity: " + round(starVel, 2) + "m/s", 7).


        local setUpVel is 0.
        local setStarVel is 0.
        local setForeVel is 0.

        set setUpVel to max(min(upToDockAxis / 10, 1), -1).
        set setStarVel to max(min(starToDockAxis / 10, 1), -1).

        if (distanceToDockAxis > 0.2) {
            logStatus("Translating to dock axis").
        } else {
            logStatus("Approaching dock").

            set setForeVel to max(min(-distanceToDockPlane / 10, 1), -1).
        }
        
        logInfo("  Target Up Vel: " + round(setUpVel, 2) + "m/s", 11).
        logInfo("Target Star Vel: " + round(setStarVel, 2) + "m/s", 12).
        logInfo("Target Fore Vel: " + round(setForeVel, 2) + "m/s", 13).

        local upVelErr is setUpVel - upVel.
        if (abs(upVelErr) > 0.02) {
            set ship:control:top to max(min(-upVelErr * 5, 1), -1).
        } else { 
            set ship:control:top to 0.
        }
        
        local foreVelErr is foreVel - setForeVel.
        if (abs(foreVelErr) > 0.02) {
            set ship:control:fore to max(min(foreVelErr * 5, 1), -1).
        } else { 
            set ship:control:fore to 0.
        }
                
        local starVelErr is starVel - setStarVel.
        if (abs(starVelErr) > 0.02) {
            set ship:control:starboard to max(min(starVelErr * 5, 1), -1).
        } else { 
            set ship:control:starboard to 0.
        }

        logInfo("  Error Up Vel: " + round(upVelErr, 2) + "m/s", 14).
        logInfo("Error Star Vel: " + round(starVelErr, 2) + "m/s", 15).
        logInfo("Error Fore Vel: " + round(foreVelErr, 2) + "m/s", 16).

        wait 0.
    }.
}