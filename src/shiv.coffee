unless Array::map?
    Array::map = (f) -> (f x for x in @)

unless Array::filter?
    Array::filter = (f) -> (x for x in @ when (f x))

unless Array::reduce?
    Array::reduce = (f, initValue) ->
        xs = @slice()
        ret = initValue ? xs.pop()
        ret = (f ret, x) for x in xs
        ret

root = exports ? this
unless exports?
    root._func_shiv = {}
    root = root._func_shiv

root.fold = (init, f) -> (xs) ->
    if xs.reduce? # arrays
        xs.reduce f, init
    else # objects
        ret = init
        for k, v of xs
           ret = if ret? then f(ret, k, v) else {k: v}
        ret

root.take = (n) -> (xs) -> if n? then xs[0 .. n - 1] else xs

# Until I can find a nicer name for this...
# Basically a mapping over an object, taking a
# function of the form (oldk, oldv) -> [newk, newv]
root.omap = (f) -> (o) ->
    domap = exports.fold {}, (a, k, v) ->
        [kk, vv] = f k, v
        a[kk] = vv
        a
    domap o

root.partition = (f) -> (xs) ->
    trues = []
    falses = []
    for x in xs
        if f x
            trues.push x
        else
            falses.push x
    [trues, falses]

root.concatMap = (f) -> (xs) ->
    ret = undefined
    for x in xs
        fx = f x
        ret = if ret is undefined
            fx
        else if typeof fx is 'string'
            ret + fx
        else if fx.slice?
            ret.concat(fx)
        else
            ret[k] = v for k, v of fx
            ret
    ret

root.AND = (a, b) -> a and b

root.OR = (a, b) -> a or b

root.NOT = (x) -> not x

root.id = (x) -> x

