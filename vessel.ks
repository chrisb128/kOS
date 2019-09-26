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

global function getResourceFillRatio {
    parameter resName.

    for res in stage:resources {
        if res:name = resName {
            return res:amount / res:capacity.
        }
    }

    return 0.
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