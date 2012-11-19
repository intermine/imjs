(function() {
    module("service root", TestCase);

    test('Add default elements when missing', function() {
        equal(this.s.root, "http://squirrel/intermine-test/service/");
    });

    test('Leaves URLs that look basically OK alone, but adds a final slash', function() {
        equal(this.flymine.root, "http://www.flymine.org/query/service/");
    });
})();
