declare function addCircularizeNodeAtAp {
    
    local body to ship:orbit:body.

    local r to ship:orbit:apoapsis + ship:orbit:body:radius.
    local initV to sqrt( body:mu * ( (2/r) - (1/ship:orbit:semimajoraxis) ) ).
    local finalV to sqrt( body:mu * ( (2/r) - (1/r) ) ).

    local n is node(time:seconds + eta:apoapsis, 0, 0, finalV - initV).
    add n.
    return n.
}

declare function addCircularizeNodeAtPe {
    
    local body to ship:orbit:body.

    local r to ship:orbit:periapsis + ship:orbit:body:radius.
    local initV to sqrt( body:mu * ( (2/r) - (1/ship:orbit:semimajoraxis) ) ).
    local finalV to sqrt( body:mu * ( (2/r) - (1/r) ) ).

    local n is node(time:seconds + eta:periapsis, 0, 0, finalV - initV).
    add n.
    return n.
}
