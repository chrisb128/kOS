

global function newMovingAverage {
    parameter count is 5.

    local this is lexicon(
        "items", list(),
        "count", count
    ).

    local update is { parameter _this, item. movingAverageUpdate(_this, item).}.
    set this:update to update:bind(this).

    local mn is { parameter _this. return movingAverageMean(_this).}.
    set this:mean to mn:bind(this).

    return this.
}

global function movingAverageUpdate {
    parameter ma.
    parameter item.

    if (ma:items:length >= ma:count) {
        ma:items:remove(0).
    }

    ma:items:add(item).
}

global function movingAverageMean {
  parameter ma.
  local avg is 0.
  for i in ma:items {
    set avg to avg + i.
  }

  set avg to avg / ma:items:length.
  return avg.
}

global function movingAverageVecMean {
    parameter ma.
    
    local avg is V(0,0,0).

    for i in ma:items {
        set avg:x to avg:x + i:x.
        set avg:y to avg:y + i:y.
        set avg:z to avg:z + i:z.
    }

    set avg:x to avg:x / ma:items:length.
    set avg:y to avg:y / ma:items:length.
    set avg:z to avg:z / ma:items:length.

    return avg.
}
