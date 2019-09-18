global function autoDock {
    parameter targetDock.
    parameter debug is false.
        
    rcs on.
    sas off.

    set target to targetDock.
    local tgt is target:ship.
    local shipDock is ship:controlpart.

    local tgtBounds is tgt:bounds.

    unlock steering.
    local shipTgtDir is lookDirUp(V(0,0,0)-targetDock:portFacing:forevector, targetDock:portFacing:upVector).

    if (debug) {
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

        local shipTgtDirVec is vecDraw(
            shipDock:nodePosition,
            shipTgtDir:forevector,
            RGB(0, 0, 1), "", 3.0, true, 0.1, true, true
        ).
        set shipTgtDirVec:startupdater to { return shipDock:nodePosition. }.
        set shipTgtDirVec:vecupdater to { return shipTgtDir:forevector. }.
    }

    // 10m standoff
    lock targetPos to (targetDock:portFacing:forevector * 10) + targetDock:nodePosition.

    if abs(vAng(shipTgtDir:forevector, targetPos)) > 90 {
        logStatus("!!!! ON WRONG SIDE !!!").

        if (targetPos:mag < tgtBounds:extents:mag + 50) {
            // face station
            local stationDir is lookDirUp(tgt:position, body:position).
            lock steering to stationDir.
            
            wait until vAng(ship:facing:forevector, stationDir:forevector) < 0.1.
            // backup until distance to ship is extents + 50

            until targetPos:mag > tgtBounds:extents:mag + 50 {
                local sf is ship:facing.
                local relVel is tgt:velocity:orbit - ship:velocity:orbit.
                local foreVel is vDot(relVel, sf:foreVector).
                local setForeVel is -1.

                rcsCtl(list(0, setForeVel - foreVel, 0)).
            }

            // stop
            until (tgt:velocity:orbit - ship:velocity:orbit):mag < 0.25 {
                local relVel is tgt:velocity:orbit - ship:velocity:orbit.
                local sf is ship:facing.
                local upVel is vDot(relVel, sf:upVector).
                local foreVel is vDot(relVel, sf:foreVector).
                local starVel is vDot(relVel, sf:starVector).
                rcsCtl(list(upVel,foreVel,starVel)).
            }
        }   
        // face port
        lock steering to shipTgtDir.
        
        logInfo("Aligning with docking port axis").
        wait until vAng(ship:facing:forevector, shipTgtDir:forevector) < 0.1.
        logInfo("Steering locked").
        
        // backup until distance to dock plane is > 50        
        local vtDock is (targetDock:nodePosition - shipDock:nodePosition).
        local dda to vCrs(shipTgtDir:forevector, vtDock):mag.        
        local ddp to sqrt(abs(vtDock:mag^2 - dda^2)).

        until ddp > 50 and abs(vAng(shipTgtDir:forevector, targetPos)) < 90 {
            set vtDock to (targetDock:nodePosition - shipDock:nodePosition).
            set dda to vCrs(shipTgtDir:forevector, vtDock):mag.        
            set ddp to sqrt(abs(vtDock:mag^2 - dda^2)).

            local sf is ship:facing.
            local relVel is tgt:velocity:orbit - ship:velocity:orbit.
            local foreVel is vDot(relVel, sf:foreVector).
            local setForeVel is 1.

            rcsCtl(list(0, foreVel - setForeVel, 0)).
            wait 0.
        }

        // stop
        until (tgt:velocity:orbit - ship:velocity:orbit):mag < 0.25 {
            local relVel is tgt:velocity:orbit - ship:velocity:orbit.
            local sf is ship:facing.
            local upVel is vDot(relVel, sf:upVector).
            local foreVel is vDot(relVel, sf:foreVector).
            local starVel is vDot(relVel, sf:starVector).
            rcsCtl(list(upVel,foreVel,starVel)).
        }
    }

    unlock targetPos.

    local distanceToDockAxis is 0.
    local distanceToDock is 0.
    local steerLock is ship:facing.
    unlock steering.
    lock steering to steerLock.


    until (targetDock:state <> "Ready" and targetDock:state <> "PreAttached") {

        local vecToTgtDock is (targetDock:nodePosition - shipDock:nodePosition).
        set distanceToDockAxis to vCrs(shipTgtDir:forevector, vecToTgtDock):mag.
        
        set distanceToDockPlane to sqrt(vecToTgtDock:mag^2 - distanceToDockAxis^2).
        set steerLock to lookDirUp(shipTgtDir:forevector, targetDock:portFacing:upVector).
            
        local vecToDockPlane is shipTgtDir:forevector:vec.
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
        
        rcsCtl(list(upVel - setUpVel, foreVel - setForeVel, starVel - setStarVel)).

        wait 0.
    }.
}

local function rcsCtl {
    parameter velErr is list(0,0,0).
    parameter p is list(5, 5, 5).
    
    local upVelErr is velErr[0].
    if (abs(upVelErr) > 0.02) {
        set ship:control:top to max(min(upVelErr * p[0], 1), -1).
    } else { 
        set ship:control:top to 0.
    }
    
    local foreVelErr is velErr[1].
    if (abs(foreVelErr) > 0.02) {
        set ship:control:fore to max(min(foreVelErr * p[1], 1), -1).
    } else { 
        set ship:control:fore to 0.
    }
            
    local starVelErr is velErr[2].
    if (abs(starVelErr) > 0.02) {
        set ship:control:starboard to max(min(starVelErr * p[2], 1), -1).
    } else { 
        set ship:control:starboard to 0.
    }
}

local function changeSides {
    parameter targetDock.

    local tgt is targetDock:ship.
    local shipDock is ship:controlpart.
}