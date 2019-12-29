set config:ipu to 2000.
clearscreen.
print "===  Warming up  ===".
wait 2.

switch to 1.
run "0:/common.ks".
print "===  Done ===".

run once mission.

if (exists("1:/mission.json")) {
    local mission is newMission(list()).
    mission:deserialize("1:/mission.json").

    print "Found mission: " + mission:name.
    print "Executing in 3 ...".
    wait 1.
    print "Executing in 2 ...".
    wait 1.
    print "Executing in 1 ...".
    wait 1.
    
    clearscreen.
    
    local options is newMissionExecuteOptions().
    set options:afterStep to {
        mission:serialize("1:/mission.json").
    }.

    mission:execute(options).
} else {
    print "No mission found.".
}