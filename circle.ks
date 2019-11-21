global function headingTo {
    parameter source is ship:geoposition.
    parameter dest is latlng(0,0).

    local dLng is dest:lng - source:lng.

    local bearing is arctan2(sin(dLng)*cos(dest:lat),(cos(source:lat)*sin(dest:lat))-(sin(source:lat) * cos(dest:lat) * cos(dLng))).

    return mod(360+bearing, 360).
}

global function distanceBetween {
    parameter start.
    parameter finish.
    parameter r.

    local A is sin((start:lat-finish:lat)/2)^2 + cos(start:lat)*cos(finish:lat)*sin((start:lng-finish:lng)/2)^2.

    return r*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}

global function locationAfterDistanceAtHeading {
    parameter start.
    parameter heading.
    parameter distance.
    parameter r is ship:body:radius.

    local lat is arcsin(sin(start:lat)*cos((distance*180)/(r*constant():pi))+cos(start:lat)*sin((distance*180)/(r*constant():pi))*cos(heading)).
    local lng is 0.
    if abs(Lat) <> 90 {
        set lng to start:lng+arctan2(sin(heading)*sin((distance*180)/(r*constant():pi))*cos(start:lat),cos((distance*180)/(r*constant():pi))-sin(start:lat)*sin(lat)).
    }

    return latlng(lat,lng).
}

global function computeWaypoints {
    parameter start.
    parameter finish.
    parameter altitude.
    parameter separation.

    local waypoints is list().
    local current is start.
    local radius is ship:body:radius + altitude.
    waypoints:add(current).

    until distanceBetween(current, finish, radius) < separation {
        set current to locationAfterDistanceAtHeading(current, headingTo(current, finish), separation, radius).
        waypoints:add(current).
    }

    waypoints:add(finish).

    return waypoints.
}

global function distanceTo {
    parameter target is latlng(0,0).

    return target:altitudePosition(ship:altitude):mag.
}

global function getShipHeading {
    local east to vcrs(up:vector, north:vector). //Reference heading
    local traveling to srfprograde:vector.
    local x to vdot(north:vector, traveling).
    local y to vdot(east, traveling).
    return mod((arctan2(y, x)+360),360).
}

global function headingError {
    parameter currentHeading.
    parameter targetHeading.

    local headingErr is currentHeading - targetHeading.
    if abs((currentHeading + 360) - targetHeading) < abs(headingErr) {
        set headingErr to (currentHeading + 360) - targetHeading.
    }

    if abs(headingErr) > 180 {
        set headingErr to -headingErr.
    }

    return headingErr.
}