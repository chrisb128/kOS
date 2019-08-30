local fieldWidth is 50.

declare function logMission {
    parameter message.
    print message:padright(fieldWidth) AT (0, 0).
}

declare function logStatus {
    parameter message.
    print message:padright(fieldWidth) AT (0, 1).
}

declare function logInfo {
    parameter message.
    parameter fieldNumber is 1.
    local infoFieldsStart is 1.
    set fieldNumber to fieldNumber + infoFieldsStart.

    print message:padright(fieldWidth) AT (0, fieldNumber).
}

declare function formatVec {
    parameter v.
    parameter r is 0.

    return "V(" + round(v:x, r) + ", " + round(v:y, r) + ", " + round(v:z, r) + ")".
}