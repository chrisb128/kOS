global function getResourceFillRatio {
    parameter resName.
    parameter partTag is "".

    if partTag = "" {
        for res in stage:resources {
            if res:name = resName {
                return res:amount / res:capacity.
            }
        }
    } else {
        local cap is 0.
        local amt is 0.

        for p in ship:partsTagged(partTag) {
            for res in p:resources {
                if res:name = resName {
                    set cap to cap + res:capacity.
                    set amt to amt + res:amount.
                }
            }
        }

        if cap = 0 { return 0. }
        return amt / cap.
    }

    return 0.
}