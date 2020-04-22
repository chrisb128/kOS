local fieldWidth is terminal:width.

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

declare function formatLatLng {
    parameter latLng.
    parameter r is 3.

    return "GEO(" + round(latLng:lat, r) + ", " + round(latLng:lng, r) + ")".
}

global function logFileName {
    parameter logName.

    return "0:/" + ship:name + "/" + logName.
}

global function initLog {
    parameter fileName.
    if exists(logFileName(fileName)) { deletePath(logFileName(fileName)). }
}

global function initPidLog {
    parameter fileName.
    initLog(fileName).
    log pidLogHeader() to logFileName(fileName).
}


global function pidLogHeader {
    return "Time,Kp,Ki,Kd,Input,SetPoint,Err,PTerm,ITerm,DTerm,Output".
}

global function joinString {
    parameter list, delim.

    local s is "".
    from { local i is 0. } until (i >= list:length) step { set i to i + 1. } do {
        if (i > 0) {
            set s to s + delim.
        }

        set s to s + list[i].
    }

    return s.
}

global function pidLogEntry {
    parameter pid.
    parameter startTime.

    return joinString(list(
        time:seconds - startTime,
        pid:kp,
        pid:ki,
        pid:kd,
        pid:input,
        pid:setpoint,
        pid:error,
        pid:pterm,
        pid:iterm,
        pid:dterm,
        pid:output), ",").
}
