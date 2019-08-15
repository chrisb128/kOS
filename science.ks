declare function runAllExperiments {
    
    local scienceModNames to list("ModuleScienceExperiment", "DMModuleScienceAnimate", "DMBathymetry").
    for modName in scienceModNames {
        for scienceMod in ship:modulesNamed(modName) {
            if not scienceMod:hasData and not scienceMod:inoperable {
                scienceMod:deploy().
            }
        }
    }
}

declare function collectAllScience {    
    local containerMod to ship:modulesNamed("ModuleScienceContainer")[0].
    containerMod:doAction("collect all", true).
}