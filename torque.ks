
global function torqueProvidedByPartsTagged {
    parameter tag.
    local t is V(0,0,0).
    for elevator in ship:partsTagged(tag) {
        for moduleName in elevator:modules {
            local mod is elevator:getmodule(moduleName).
            if (mod:hasTorque) {
                local modTorque is mod:torque:availableTorque.
                set t:x to t:x + ((abs(modTorque[0]:x) + abs(modTorque[1]:x)) / 2).
                set t:y to t:y + ((abs(modTorque[0]:y) + abs(modTorque[1]:y)) / 2).
                set t:z to t:z + ((abs(modTorque[0]:z) + abs(modTorque[1]:z)) / 2).
            }
        }
    }
    return t.
}

local function vMax {
    parameter v1, v2.

    local v is V(0,0,0).
    set v:x to max(abs(v1:x), abs(v2:x)).
    set v:y to max(abs(v1:y), abs(v2:y)).
    set v:z to max(abs(v1:z), abs(v2:z)).

    return v.
}

local startTime is time:seconds.



local logHeadList is list("t").
local logItemIndex is 0.
for provider in ship:torque:allProviders {
    logHeadList:add(logItemIndex + "-posX").
    logHeadList:add(logItemIndex + "-posY").
    logHeadList:add(logItemIndex + "-posZ").
    logHeadList:add(logItemIndex + "-negX").
    logHeadList:add(logItemIndex + "-negY").
    logHeadList:add(logItemIndex + "-negZ").

    set logItemIndex to logItemIndex + 1.
}

logHeadList:add("total-posX").
logHeadList:add("total-posY").
logHeadList:add("total-posZ").
logHeadList:add("total-negX").
logHeadList:add("total-negY").
logHeadList:add("total-negZ").

logHeadList:add("finalX").
logHeadList:add("finalY").
logHeadList:add("finalZ").

initLog("AvailableTorque.csv").
log joinString(logHeadList, ",") to logFileName("AvailableTorque.csv").

local minTorque is 0.00001.
global function getAvailableTorque {
    local torque is V(0,0,0).

    local posTorque is V(0,0,0).
    local negTorque is V(0,0,0).

    local logList is list().
    logList:add((time:seconds - startTime) + "").

    for provider in ship:torque:allProviders {
        local moduleTorques is provider:availableTorque.

        if (moduleTorques[0] = moduleTorques[1]) {
            set moduleTorques[1] to -moduleTorques[1].
        }

        if (moduleTorques[0]:z < 0) {
            set moduleTorques[0]:z to -moduleTorques[0]:z.
            set moduleTorques[1]:z to -moduleTorques[1]:z.
        }
        
        logList:add(moduleTorques[0]:x).
        logList:add(moduleTorques[0]:y).
        logList:add(moduleTorques[0]:z).
        logList:add(moduleTorques[1]:x).
        logList:add(moduleTorques[1]:y).
        logList:add(moduleTorques[1]:z).

        set posTorque to posTorque + moduleTorques[0].
        set negTorque to negTorque + moduleTorques[1].
    }

    logList:add(posTorque:x).
    logList:add(posTorque:y).
    logList:add(posTorque:z).
    logList:add(negTorque:x).
    logList:add(negTorque:y).
    logList:add(negTorque:z).

    set torque to vMax(posTorque, negTorque).

    logList:add(torque:x).
    logList:add(torque:y).
    logList:add(torque:z).

    log joinString(logList, ",") to logFileName("AvailableTorque.csv").
    
    if (torque:x < minTorque) { set torque:x to 0. }
    if (torque:y < minTorque) { set torque:y to 0. }
    if (torque:z < minTorque) { set torque:z to 0. }
    
    return torque.
}

global function momentOfInertia {
    return ship:moi.
}