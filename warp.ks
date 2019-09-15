declare function autoWarp {
    parameter targetTime.

    set kUniverse:timewarp:mode to "RAILS".

    set targetTime to targetTime - time:seconds.
    if targetTime > 10000000 {
        set kUniverse:timewarp:warp to 9. // 10000000x
    }
    else if targetTime > 1000000 {
        set kUniverse:timewarp:warp to 8. // 1000000x
    }
    else if targetTime > 100000 {
        set kUniverse:timewarp:warp to 7. // 100000x
    }
    else if targetTime > 10000 {
        set kUniverse:timewarp:warp to 6. // 10000x
    }
    else if targetTime > 1000 {
        set kUniverse:timewarp:warp to 5. // 1000x
    }
    else if targetTime > 100 {
        set kUniverse:timewarp:warp to 4. // 100x
    }
    else if targetTime > 50 {
        set kUniverse:timewarp:warp to 3. // 50x
    }
    else if targetTime > 10 {
        set kUniverse:timewarp:warp to 2. // 10x
    }
    else if targetTime > 2 {
        set kUniverse:timewarp:warp to 1. // 5x
    }
    else {
        set kUniverse:timewarp:warp to 0. // 1x
    }
}