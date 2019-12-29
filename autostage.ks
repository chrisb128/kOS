local autoStager is lexicon("enabled", false, "lastStage", time:seconds).

global function enableAutoStager {
    if (autoStager:enabled) {
        return.
    }

    set autoStager to lexicon(
        "enabled", true,
        "lastStage", time:seconds
    ).

    on stageFlameout() {
        if (autoStager:enabled) {
            if (time:seconds > autoStager:lastStage + 2) {
                set autoStager:lastStage to time:seconds.
                stage.
                wait 1.
            }

            preserve.
        }
    }
}

global function disableAutoStager {
    set autoStager:enabled to false.
}

local function stageFlameout {
    if not autoStager:enabled {
        return true.
    }

    local lastStage is 0.
    list engines in engineList.
    
    for en in engineList {
        if en:stage > lastStage {
            set lastStage to en:stage.
        }
    }

    for en in engineList {
        if en:stage = lastStage {
            if en:flameout {
                return true.
            }
        }
    }
}.