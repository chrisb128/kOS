run once moving_average.
run once pidloop2.

global function newTorquePI {
  local pid is pidLoop2(0,0,0).

  local this is lexicon(
    "pid", pid,
    "i", 0,
    "tr", 0.0,
    "ts", 0.0
  ).

  local setTr is {parameter _this, tr. torquePISetTr(_this, tr).}.
  set this:setTr to setTr:bind(this).

  local setTs is {parameter _this, ts. torquePISetTs(_this, ts).}.
  set this:setTs to setTs:bind(this).

  local update is {parameter _this, input, setPoint, moi, maxOutput. return torquePIUpdate(_this, input, setPoint, moi, maxOutput).}.
  set this:update to update:bind(this).

  local resetI is {parameter _this. torquePIResetI(_this).}.
  set this:resetI to resetI:bind(this).

  this:setTs(4.0).

  return this.
}

local function torquePIResetI {
  parameter this.

  this:pid:reset().
}

local function torquePIUpdate {
  parameter this, input, setPoint, moi, maxOutput.

  set this:i to moi.

  this:pid:setKi(moi * (4 / this:ts)).
  this:pid:setKp(2 * (sqrt(moi * this:pid:ki))).

  return this:pid:update(time:seconds, input, setPoint, maxOutput).
}

local function torquePISetTr {
  parameter this.
  parameter tr.

  set this["tr"] to tr.
  set this["ts"] to 4.0 * tr / 2.76.
}

local function torquePISetTs {
  parameter this.
  parameter ts.

  set this["ts"] to ts.
  set this["tr"] to 2.76 * ts / 4.
}

