run once logging.

global function countdown {
    local parameter count is 10.
    from {local c is count.} until c = 0 step {set c to c - 1.} do {
        logInfo("..." + c).
        wait 1.
    }
}
