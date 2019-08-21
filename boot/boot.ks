clearscreen.
print "===  Warming up  ===".
local parameter count is 5.
from {local c is count.} until c = 0 step {set c to c - 1.} do {
    print "... " + c at(0, 1).
    wait 1.
}

switch to 1.
run "0:/common.ks".
print "===  Done ===".

print "=== CURRENT MISSION: MINMUS ===".
copypath("0:/minmus.ks", "").

run minmus.