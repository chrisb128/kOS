// copied from https://github.com/dewiniaid/ksp-kos-scripts/blob/master/lib_util.ks
LOCAL K_E IS constant:e.  // Shorter!
// Divide to convert degrees to radians, multiply to convert radians to degrees.
LOCAL K_DEGREES IS constant:degtorad.

// Return t if c else f.
LOCAL FUNCTION IIF { PARAMETER c. PARAMETER t. PARAMETER f. IF c { RETURN t. } RETURN f. }

GLOBAL FUNCTION SINH { PARAMETER x. SET x TO x/K_DEGREES. RETURN (K_E^x - K_E^(-x))/2. }
GLOBAL FUNCTION COSH { PARAMETER x. SET x TO x/K_DEGREES. RETURN (K_E^x + K_E^(-x))/2. }
GLOBAL FUNCTION ASINH { PARAMETER x. PARAMETER y IS 0. RETURN IIF(y<0,-1,1)*K_DEGREES*LN(x+SQRT(x^2+1)). }
GLOBAL FUNCTION ACOSH { PARAMETER x. PARAMETER y IS 0. RETURN IIF(y<0,-1,1)*K_DEGREES*LN(x+SQRT(x^2-1)). }

// FOUND https://developer.download.nvidia.com/cg/tanh.html
GLOBAL FUNCTION TANH { 
  PARAMETER X. 
  SET X TO K_E^(2*X).
  return (X - 1) / (X + 1).
}

// FOUND http://mathworld.wolfram.com/InverseHyperbolicTangent.html
GLOBAL FUNCTION ATANH {
    PARAMETER X.
    return 0.5 * (ln(1+X) - ln(1-X)).
}