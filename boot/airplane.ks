set config:ipu to 10000.
brakes on.
switch to 1.
copypath("0:/logging.ks", "").
copypath("0:/time.ks", "").
copypath("0:/ease.ks", "").
copypath("0:/moving_average.ks", "").
copypath("0:/torque.ks", "").
copypath("0:/torque_pi.ks", "").
copypath("0:/attitude.ks", "").
copypath("0:/circle.ks", "").
copypath("0:/runways.ks", "").
copypath("0:/energy.ks", "").
copypath("0:/airplane.ks", "").
copypath("0:/navigator.ks", "").
copypath("0:/pidloop2.ks", "").


run "0:/test.ks".