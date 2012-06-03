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

exports.fold = (xs) -> (init) -> (f) -> xs.reduce f, init

exports.take = (n) -> (xs) -> exports.fold(xs)([]) (a, x) ->
    if (n? and a.length >= n) then a else a.concat [x]

