print "===  Booting up  ===".
switch to 1.
run "0:/common.ks".
print "===  Done ===".

print "=== CURRENT MISSION: MINMUS ===".
copypath("0:/minmus.ks", "").

run minmus.