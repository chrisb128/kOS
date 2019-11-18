global function bearingTo {
    parameter source is ship:geoposition.
    parameter dest is latlng(0,0).

    local dLng is dest:lng - source:lng.

    local bearing is arctan2(sin(dLng)*cos(dest:lat),(cos(source:lat)*sin(dest:lat))-(sin(source:lat) * cos(dest:lat) * cos(dLng))).

    return mod(360+bearing, 360).
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