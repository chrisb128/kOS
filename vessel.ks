global function extendRadiators {
    
    for radiator in ship:modulesNamed("ModuleDeployableRadiator") {
        radiator:doAction("extend radiator", true).
    }
}

global function retractRadiators {
    
    for radiator in ship:modulesNamed("ModuleDeployableRadiator") {
        radiator:doAction("retract radiator", true).
    }
}

global function deployDrills {
    
    for drill in ship:partsnamed("RadialDrill") {
        local dAnim is drill:getmodule("ModuleAnimationGroup").
        dAnim:doAction("deploy drill", true).
    }
}

global function retractDrills {
    for drill in ship:partsnamed("RadialDrill") {
        local dAnim is drill:getmodule("ModuleAnimationGroup").
        dAnim:doAction("retract drill", true).
    }
}

global function startSurfaceHarvesters {
    
    for drill in ship:partsnamed("RadialDrill") {
        local dHarvester is drill:getmodule("ModuleResourceHarvester").
        dHarvester:doAction("start surface harvester", true).
    }
}

global function stopSurfaceHarvesters {
    
    for drill in ship:partsnamed("RadialDrill") {
        local dHarvester is drill:getmodule("ModuleResourceHarvester").
        dHarvester:doAction("stop surface harvester", true).
    }
}


global function deployFairings {
    for fairing in ship:modulesNamed("ModuleProceduralFairing") {
        fairing:doEvent("deploy").
    }
}

global function deployAntennas {
    for antenna in ship:modulesNamed("ModuleRTAntenna") {
        if antenna:hasEvent("activate") {
            antenna:doEvent("activate").
        }
    }

    for antenna in ship:modulesNamed("ModuleDeployableAntenna") {
        if antenna:hasEvent("extend antenna") {
            antenna:doEvent("extend antenna").
        }
    }
}

global function deploySolarPanels {
    for panel in ship:modulesNamed("ModuleDeployableSolarPanel") {
        if panel:hasEvent("extend solar panel") {
            panel:doEvent("extend solar panel").
        }
    }
}

global function startIsru {
    parameter mode.

    for isru in ship:modulesNamed("ModuleResourceConverter") {
        for f in isru:allfieldnames {
            if f = mode {
                isru:doAction("start isru [" + mode + "]", true).

                break.
            }
        }
    }
}


global function stopIsru {
    parameter mode is "lf+ox".

    for isru in ship:modulesNamed("ModuleResourceConverter") {
        for f in isru:allfieldnames {
            if f = mode {
                isru:doAction("stop isru [" + mode + "]", true).

                break.
            }
        }
    }
}