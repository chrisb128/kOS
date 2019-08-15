declare function filter {
    local parameter lst.
    local parameter predicate.

    local newList is list().

    for item in lst {
        if predicate(item) {
            newList:add(item).
        }
    }

    return newList.
}

declare function sum {
    local parameter lst.
    local parameter selector.

    local total is 0.

    for item in lst {
        set total to total + selector(item).
    }

    return total.
}
