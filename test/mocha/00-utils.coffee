should = require 'should'
  
even = (n) -> n % 2 is 0
add = (a, b) -> a + b
lengthOf = (x) -> x.length

describe 'utils', ->

  {utils} = require './lib/fixture'

  describe 'Type Checking', ->

    {isFunction, isArray} = utils

    describe 'A function', ->

      f = (x) -> x * x

      it 'should be a function', ->
        isFunction(f).should.be.true

      it 'should not be an array', ->
        isArray(f).should.not.be.true

    describe 'An object', ->

      o = {}

      it 'should not be a function', ->
        isFunction(o).should.not.be.true
      it 'should not be an array', ->
        isArray(o).should.not.be.true

    describe 'An array', ->

      a = []

      it 'should not be a function', ->
        isFunction(a).should.not.be.true
      it 'should be an array', ->
        isArray(a).should.be.true

    describe 'A regex', ->
       
      r = /foo/

      it 'should not be a function', ->
        isFunction(r).should.not.be.true
      it 'should not be an array', ->
        isArray(r).should.not.be.true

    describe 'A date', ->

      d = new Date

      it 'should not be a function', ->
        isFunction(d).should.not.be.true
      it 'should not be an array', ->
        isArray(d).should.not.be.true

    describe 'A string', ->

      s = "foo"

      it 'should not be a function', ->
        isFunction(s).should.not.be.true
      it 'should not be an array', ->
        isArray(s).should.not.be.true

    describe 'A number', ->

      n = 100

      it 'should not be a function', ->
        isFunction(n).should.not.be.true
      it 'should not be an array', ->
        isArray(n).should.not.be.true

    describe 'A boolean', ->

      b = true

      it 'should not be a function', ->
        isFunction(b).should.not.be.true
      it 'should not be an array', ->
        isArray(b).should.not.be.true

    describe 'null', ->

      it 'should not be a function', ->
        isFunction(null).should.not.be.true
      it 'should not be an array', ->
        isArray(null).should.not.be.true

  describe 'isArray', ->

    {isArray} = utils

    it 'should agree that [] is an array', ->
      isArray([]).should.be.true

    it 'should agree that [1, 2, 3] is an array', ->
      isArray([1, 2, 3]).should.be.true

  describe 'querystring', ->

    {querystring} = utils

    describe 'from pairs', ->

      it 'should make "foo=bar" from [["foo", "bar"]]', ->
        querystring([['foo', 'bar']]).should.eql "foo=bar"

      it 'should make "" from [["foo", null]]', ->
        querystring([['foo', null]]).should.eql ""

      it 'should make "a=b&c=d" from [["a", "b"], ["c", "d"]]', ->
        querystring([["a", "b"], ["c", "d"]]).should.eql "a=b&c=d"

      it 'should make "a=1&a=2" from [["a", 1],["a",2]]', ->
        querystring([['a', 1],['a', 2]]).should.eql "a=1&a=2"

      it 'should make "key=some%20value" from [["key", "some value"]]', ->
        querystring([['key', 'some value']]).should.eql "key=some%20value"

    describe 'from object', ->

      it 'should make "foo=bar" from {"foo": "bar"}', ->
        querystring(foo: 'bar').should.eql "foo=bar"

      it 'should make "" from {"foo": undefined}', ->
        querystring(foo: undefined).should.eql ""

      it 'should make "a=b&c=d" from {"a": "b", "c": "d"}', ->
        # This could be fragile, depending on the key iteration order.
        querystring(a: "b", c: "d").should.eql "a=b&c=d"

      it 'should make "a=1&a=2" from {"a": [1, 2]}', ->
        querystring(a: [1, 2]).should.eql "a=1&a=2"

      it 'should make "key=some%20value" from {"key": "some value"}', ->
        querystring(key: 'some value').should.eql "key=some%20value"

  describe 'curry', ->

    {curry} = utils

    plusTwo = curry add, 2
    getFour = curry add, 2, 2

    it 'can produce a partially applied function', ->
      plusTwo(2).should.eql 4

    it 'can partially apply all arguments', ->
      getFour().should.eql 4

  describe 'error', ->
    
    {error} = utils

    e = error "Sth. bad happened"

    it 'should be a failed promise', (done) ->
      shouldHaveFailed = (args...) -> done "Expected failure, got #{ args }"
      e.then shouldHaveFailed, (-> done())

  describe 'success', ->
     
    {success} = utils

    s = success "Sth. good happened"

    it 'should be a resolved promise', (done) ->
      s.then (-> done()), (-> done "Failed")

  describe 'defer', ->

    {defer} = utils

    describe 'resolution', ->

      {promise, resolve} = defer()
      resolve "FOO"

      it 'should be a thenable', ->
        should.exist promise.then

      it 'should have a "done" method', ->
        should.exist promise.done

      it 'should have been resolved', (done) ->
        promise.then( (res) -> res.should.equal 'FOO' )
               .then( (-> done()), done )
      
    describe 'rejection', ->

      {promise, reject} = defer()
      reject "BAR"

      it 'should be a thenable', ->
        should.exist promise.then

      it 'should have a "done" method', ->
        should.exist promise.done

      it 'should have been rejected', (done) ->
        promise.then(
          ((res) -> done new Error("Expected failure, got #{ res }")),
          ((err) ->
            err.should.equal 'BAR'
            done()))

  describe 'the result of thenning a rejected promise', ->

    {defer} = utils

    {promise, reject} = defer()
    child = promise.then (x) -> x * 2
    reject 'FOO'

    it 'should be a thenable', ->
      should.exist child.then

    it 'should have a "done" method', ->
      should.exist child.done

    it 'should have been rejected', (done) ->
      child.then ((res) -> done new Error("Expected failure, got #{ res }")),
                 ((err) ->
                   err.should.equal 'FOO'
                   done())

  describe 'fold', ->

    {fold} = utils
    add = (a, b) -> a + b
    sum = fold add

    describe 'the sum of an empty list with an initial state.', ->
      n = sum 0, []
      it 'should equal 0', ->
        n.should.eql 0

    describe 'the sum of a non-empty list with an initial state.', ->
      n = sum 100, [1, 2, 3]
      it 'should equal 106', ->
        n.should.eql 106

    describe 'the attempt to call sum with no arguments', ->
      attempt = -> sum()
      it 'should throw an error', ->
        attempt.should.throw /null/

    describe 'the sum of a non-empty list', ->
      n = sum [1, 2, 3]
      it 'should equal 6', ->
        n.should.equal 6
      
    describe 'the sum of an empty list with no init', ->
      n = sum []
      it 'should be undefined', ->
        n.should.be.undefined

  describe 'take', ->

    {take} = utils

    describe 'take 2', ->
      takeTwo = take 2

      it 'should retrieve the first 2 items from an array', ->
        takeTwo([1, 2, 3]).should.eql [1, 2]

      it 'should retrieve as many items as possible', ->
        takeTwo([1]).should.eql [1]

      it 'should not alter the input', ->
        input = [1, 2, 3]
        firstTwo = takeTwo input
        firstTwo.should.not.equal input

  describe 'filter', ->

    {filter} = utils

    evens = filter even

    describe 'the first 5 even numbers', ->
      xs = [1 .. 10]
      firstFive = evens xs
      it 'should contain 5 items', ->
        firstFive.should.have.lengthOf 5
      it 'should be [2, 4, 6, 8, 10]', ->
        firstFive.should.eql [2, 4, 6, 8, 10]

  describe 'uniqBy', ->

    {uniqBy} = utils

    describe 'using a hashable key', ->

      uniqByLength = uniqBy lengthOf
      input = ["foo", "bar", "quux"]

      it 'should get only one string of each length', ->
        uniqByLength(input).should.eql ['foo', 'quux']

    describe 'using a non-hashable-key', ->
      a = {}
      b = {}
      c = {}
      xs = [{key: a}, {key: a}, {key: b}, {key: b}, {key: b}, {key: c}]
      uniqByKey = uniqBy (x) -> x.key

      it 'should reduce the list to three items', ->
        uniqByKey(xs).should.have.lengthOf 3

      it 'should have unique keys', ->
        (x.key for x in uniqByKey(xs)).should.eql [a, b, c]

    describe 'calling uniqBy with both arguments', ->

      oneEvenOneOdd = uniqBy ((x) -> x % 2), [1 .. 10]

      it 'should work as it would if curried', ->
        oneEvenOneOdd.should.eql [1, 2]

  describe 'any', ->

    {any} = utils

    describe 'The first ten numbers', ->

      firstTen = [1 .. 10]

      it 'should contain a truthy value', ->
        any(firstTen).should.be.true

      it 'should contain an even number', ->
        any(firstTen, even).should.be.true

      it 'should not contain a number above ten', ->
        aboveTen = (x) -> x > 10
        any(firstTen, aboveTen).should.be.false

  describe 'Searching in', ->

    {find} = utils

    describe 'The first ten numbers', ->

      firstTen = [1 .. 10]

      describe 'for even numbers', ->

        findEven = find even

        it 'should find two', ->
          findEven(firstTen).should.equal 2

      describe 'for numbers above ten', ->

        findAboveTen = find (x) -> x > 10

        it 'should not find anything', ->
          should.not.exist findAboveTen firstTen

  describe 'escape', ->

    {escape} = utils

    describe 'escaping "foo"', ->

      escaped = escape "foo"

      it 'should not have changed anything', ->
        escaped.should.eql "foo"

    describe 'escaping "foo said "bar\'s dumb", & walked off >.<"', ->

      escaped = escape 'foo said "bar\'s dumb", & walked off >.<'

      it 'should have escaped all the XML entities', ->
        escaped.should.eql 'foo said &quot;bar&#x27;s dumb&quot;, &amp; walked off &gt;.&lt;'


  describe 'omap', ->

    {omap} = utils

    describe 'an inverter', ->

      invert = omap (k, v) -> [v, k]

      it 'should invert objects', ->
        invert(a: 'b', c: 'd').should.eql d: 'c', b: 'a'

  describe 'copy', ->

    {copy} = utils
    original = a: 'b', c: 'd'

    describe 'a copy of an object', ->

      clone = copy original

      it 'should be equal to its source', ->
        clone.should.eql original

    describe 'an altered clone', ->

      clone = copy original
      clone.e = 'f'

      it 'should not be connected', ->
        clone.should.not.eql original

  describe 'partitioning', ->

    {partition} = utils

    describe 'the first ten numbers into evens and odds', ->

      firstTen = [1 .. 10]
      intoEvensAndOdds = partition even
      evensAndOdds = intoEvensAndOdds firstTen

      it 'should produce a collection of evens, and one of odds', ->
        evensAndOdds.should.eql [ [2,4,6,8,10], [1,3,5,7,9] ]

  describe 'id', ->

    {id} = utils

    it 'should be a function', ->
      utils.isFunction(id).should.be.true

    it 'should return its input', ->
      for x in [true, false, 1, 3.14, "foo", {a: 'b'}, [1, 2, 3]]
        id(x).should.equal x
      should.not.exist id null


  describe 'concatMap', ->

    {concatMap} = utils

    describe 'Getting the first three powers of the first three numbers', ->
      xs = [1 .. 3]
      f = (x) -> (Math.pow x, y for y in [1 .. 3])
      powers = concatMap f

      it 'should return [1, 1, 1, 2, 4, 8, 3, 9, 27]', ->
        powers(xs).should.eql [1, 1, 1, 2, 4, 8, 3, 9, 27]

    describe 'Building an object from a list', ->
      xs = ['a', 'b', 'c']
      f = (c) ->
        o = {}
        o[c] = c.charCodeAt 0
        o
      charMapper = concatMap f

      it 'should build {a: 97, b: 98, c: 99} from ["a", "b", "c"]', ->
        charMapper(xs).should.eql {a: 97, b: 98, c: 99}

    describe 'Summing a list', ->
      xs = [1 .. 10]
      sum = concatMap utils.id

      it 'should sum the numbers', ->
        sum(xs).should.eql 55

    describe 'Building a string', ->
      xs = [97, 98, 99]
      f = String.fromCharCode
      buildString = concatMap f

      it 'should build "abc" from [97, 98, 99]', ->
        buildString([97, 98, 99]).should.eql "abc"

  describe 'difference', ->
    {difference} = utils

    it 'should be say that [4,5,6] is the difference of [1,2,3,4,5,6] and [1,2,3]', ->
      difference([1 .. 6], [1 .. 3]).should.eql [4 .. 6]

  describe 'invoke', ->
    {invoke} = utils

    describe 'attempting to invoke a method on a null object', ->
      invokeMethod = invoke 'method'
      attempt = -> invokeMethod null

      it 'should throw a helpful error', ->
        attempt.should.throw /method.*of null/

    describe 'the invocation of a method without arguments', ->
      o = state: 10, method: -> @state * 2
      invokeMethod = invoke 'method'

      it 'should call the method, in the context of the object', ->
        invokeMethod(o).should.eql 20

    describe 'the invocation of a method with an argument', ->
      o = state: 10, method: (x) -> @state * x
      invokeMethod = invoke 'method', 10

      it 'should be called in the context of that object', ->
        invokeMethod(o).should.eql 100

    describe 'the invocation of a method with several arguments', ->
      o = state: 10, method: (a, b) -> @state * (a + b)
      invokeMethod = invoke 'method', 2, 3

      it 'should be called in the context of that object', ->
        invokeMethod(o).should.eql 50

    describe 'attempting to call a non-existent method', ->
      o = method: -> 'foo'
      invokeMethod = invoke 'notMethod'
      attempt = -> invokeMethod o

      it 'shoud throw a helpful error', ->
        attempt.should.throw /notMethod/

  describe 'invokeWith', ->
    {invokeWith} = utils

    describe 'attempting to invoke a method on a null object', ->
      invokeMethod = invokeWith 'method'
      attempt = -> invokeMethod null

      it 'should throw a helpful error', ->
        attempt.should.throw /method.*of null/

    describe 'the invocation of a method without arguments', ->
      o = state: 10, method: -> @state * 2
      invokeMethod = invokeWith 'method'

      it 'should call the method, in the context of the object', ->
        invokeMethod(o).should.eql 20

      it 'should be identical to the equivalent function constructed with "invoke"', ->
        invokeMethod(o).should.eql (utils.invoke 'method') o

    describe 'invoking a method with an explicit this binding', ->
      o = method: -> @state * 2
      ctx = state: 7
      invokeMethod = invokeWith 'method', [], ctx

      it 'should call our method on the correct binding of this', ->
        invokeMethod(o).should.eql 14

    describe 'the invocation of a method with arguments', ->
      o = state: 10, method: (x) -> @state * x
      invokeMethod = invokeWith 'method', [10]

      it 'should be called in the context of that object', ->
        invokeMethod(o).should.eql 100

    describe 'the invocation of a method with several arguments', ->
      o = state: 10, method: (a, b) -> @state * (a + b)
      invokeMethod = invokeWith 'method', [2, 3]

      it 'should be called in the context of that object', ->
        invokeMethod(o).should.eql 50

    describe 'attempting to call a non-existent method', ->
      o = method: -> 'foo'
      invokeMethod = invokeWith 'notMethod'
      attempt = -> invokeMethod o

      it 'shoud throw a helpful error', ->
        attempt.should.throw /notMethod/

