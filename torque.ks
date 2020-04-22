
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

local minTorque is 0.00001.
global function getAvailableTorque {
    local torque is V(0,0,0).
    for provider in ship:torque:allProviders {
        local moduleTorques is provider:availableTorque.
        set torque:x to torque:x + ((abs(moduleTorques[0]:x) + abs(moduleTorques[1]:x)) / 2).
        set torque:y to torque:y + ((abs(moduleTorques[0]:y) + abs(moduleTorques[1]:y)) / 2).
        set torque:z to torque:z + ((abs(moduleTorques[0]:z) + abs(moduleTorques[1]:z)) / 2).   
    }
    

    if (torque:x < minTorque) { set mean:x to 0. }
    if (torque:y < minTorque) { set mean:y to 0. }
    if (torque:z < minTorque) { set mean:z to 0. }
    
    return torque.
}

global function momentOfInertia {
    return ship:moi.
}