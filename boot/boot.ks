set config:ipu to 2000.
clearscreen.
print "===  Warming up  ===".
wait 2.

switch to 1.
run "0:/common.ks".
print "===  Done ===".

run once mission.

if (exists("1:/mission.json")) {
    local plan is mission(list()).
    plan:deserialize("1:/mission.json").

    print "Found mission: " + plan:name.
    print "Executing in 3 ...".
    wait 1.
    print "Executing in 2 ...".
    wait 1.
    print "Executing in 1 ...".
    wait 1.

    clearscreen.
    
    local options is missionExecuteOptions().
    set options:afterStep to {
        plan:serialize("1:/mission.json").
        
        plan:serialize("0:/"+ship:name+"/mission.json").
    }.

    plan:execute(options).
} else {
    print "No mission found.".
}
