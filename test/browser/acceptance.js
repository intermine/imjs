(function($) {
describe('Acceptance', function() {

  var invoke = function(name) {
    var args = [].slice.call(arguments, 1);
    return function(obj) {
      return obj[name].apply(obj, args);
    }
  };
  var Service = intermine.Service;
  var args = {
    root: "bc:8081/intermine-test-dev",
    token: "test-user-token"
  };

  describe('Instantiate service', function() {
    it('Should be able to create a service', function() {
      should.exist(new Service(args));
    });

  });

  describe('Static Resources', function() {

    var service = new Service(args);

    it('Should be able to get a sensible version', function(done) {
      service.fetchVersion().fail(done).done(function(v) {
        v.should.be.above(8);
        done();
      });
    });

    describe('Data Model', function() {
      var modelResp = service.fetchModel();

      it('should be a model', function(done) {
        var test = function(model) {
          model.should.be.an.instanceOf(intermine.Model);
          done();
        };
        modelResp.then(test, done);
      });

      it('should answer modelly questions', function(done) {
        var test = function(model) {
          model.getSubclassesOf('Manager').should.include('CEO');
          done();
        };
        modelResp.then(test, done);
      });
    });

  });

  describe('Data Requests', function() {

    var service = new Service(args);

    it('Should be able to count the employees', function(done) {
      service.count({select: ['id'], from: 'Employee'}).fail(done).done(function(c) {
        c.should.eql(132);
        done();
      });
    });

    it('Should find lists with brenda in them', function(done) {
      var onDone = function(lists) {
        lists.length.should.eql(2);
        done();
      };
      service.fetchListsContaining({type: 'Employee', publicId: 'Brenda'})
                       .then(onDone, done);
    });

    it('Should find the ages of the 46 employees over 50 add up to 2688', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(rows) {
        rows.length.should.equal(46);
        rows.reduce(function(acc, row) { return acc + row[0] }, 0).should.eql(2688);
        done();
      };
      service.rows(oldies).then(test, done);
    });

    it('Should be able to fetch results as pojos', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(employees) {
        employees.length.should.equal(46);
        employees.reduce(function(acc, emp) { return acc + emp.age }, 0).should.eql(2688);
        done();
      };
      service.records(oldies).then(test, done);
    });

    it('Should be able to summarise a numeric path', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(summary, stats) {
        summary.length.should.be.below(21);
        summary.reduce(function(sum, x) { return sum + x.count }, 0).should.equal(46);
        stats.min.should.be.above(49);
        stats.max.should.be.below(100);
        stats.uniqueValues.should.be.above(summary.length);
        done();
      };
      service.query(oldies).then(invoke('summarise', 'age')).then(test, done);
    });

    it('Should be able to summarise a string path', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(summary, stats) {
        summary.map(function(x) { return x.item }).should.include('Wernham-Hogg');
        stats.uniqueValues.should.equal(6);
        done();
      };
      service.query(oldies).then(invoke('summarise', 'department.company.name')).then(test, done);
    });

    it('should be able to fetch widgets', function(done) {
      var test = function(widgets) {
        should.exist(widgets);
        widgets.length.should.be.above(1);
        widgets.filter(function(w) { return w.name === 'contractor_enrichment' }).length.should.equal(1);
        done();
      };
      service.fetchWidgets().then(test, done);
    });

    it('should be able to fetch widget mapping', function(done) {
      var test = function(widgets) {
        should.exist(widgets);
        should.exist(widgets.contractor_enrichment);
        widgets.contractor_enrichment.widgetType.should.equal('enrichment');
        done();
      };
      service.fetchWidgetMap().then(test, done);
    });

    it('should be able to perform an enrichment calculation', function(done) {
      var args = {
        widget: 'contractor_enrichment',
        list: 'My-Favourite-Employees',
        maxp: 1
      };
      var test = function(results) {
        results.length.should.equal(1);
        results[0].identifier.should.equal('Vikram');
        done();
      };
      service.enrichment(args).then(test, done);
    });

    describe('Paging', function() {
      var expected = [
        "Tatjana Berkel",
        "Jennifer Schirrmann",
        "Herr Fritsche",
        "Lars Lehnhoff",
        "Josef M\u00FCller",
        "Nyota N'ynagasongwa",
        "Herr Grahms",
        "Frank Montenbruck",
        "Andreas Hermann",
        "Jochen Sch\u00FCler"
      ];
      it('Should support paging forwards via Query#next', function(done) {
        var query = {select: ['Employee.name'], where: { age: { gt: 50 } }, limit: 10, start: 0 };
        var test = function(results) {
          results.map(function(x) { return x.name }).should.eql(expected);
          done();
        };
        service.query(query).then(invoke('next')).then(invoke('records')).then(test, done);
      });

      it('Should support paging backwards via Query#previous', function(done) {
        var query = {select: ['Employee.name'], where: { age: { gt: 50 } }, limit: 10, start: 20 };
        var test = function(results) {
          results.map(function(x) { return x.name }).should.eql(expected);
          done();
        };
        service.query(query).then(invoke('previous')).then(invoke('records')).then(test, done);
      });
    });
  });

  describe('List Life-Cycle', function() {
    var service = new Service(args);

    var clearUp = function(done) {
      service.fetchLists().then(function(lists) {
        var gonners = lists.filter(function(l) { return l.hasTag('test') || l.hasTag('imjs') });
        var promises = gonners.map(function(l) { return l.del() });
        $.when.apply($, promises).fail(done).done(function() { done() });
      });
    };
    this.beforeAll(clearUp);
    this.afterAll(clearUp);
    this.slow(250);
    describe('Create List via Identifier Upload', function() {

      var TEST_NAME = 'test-list-from-idents';

      this.beforeAll(function(done) {
        service.fetchList(TEST_NAME).then(function(l) {
          return l.del();
        }).always(function() {
          done();
        });
      });

      this.afterAll(function(done) {
        service.fetchList(TEST_NAME).then(function(l) {
          return l.del();
        }).always(function() {
          done();
        });
      });

      it('should have the right name, size, tags', function(done) {
        var opts = {
          name: TEST_NAME,
          type: 'Employee',
          description: 'A list created to test the upload mechanism',
          tags: [ 'temp', 'imjs', 'browser' ]
        };
        var idents = [
          'anne, "brenda"',
          'carol',
          '"David Brent" Edgar',
          'rubbishy identifiers',
          'Fatou'
        ].join("\n");
        var test = function(list) {
          should.exist(list);
          list.name.should.equal(TEST_NAME);
          list.size.should.equal(5);
          opts.tags.forEach(function(t) {
            expect(t).to.satisfy(list.hasTag);
          });
          done();
        };
        service.createList(opts, idents).then(test, done);
      });

    });

    describe('Combine through Intersection', function() {

      var TEST_NAME = 'intersection-test';

      this.beforeAll(function(done) {
        service.fetchList(TEST_NAME).then(function(l) {
          return l.del();
        }).always(function() {
          done();
        });
      });

      it('should have the right name, size, tags, member', function(done) {
        var options = {
          name: TEST_NAME,
          description: 'A list created to test out the intersection operation',
          lists: ['My-Favourite-Employees', 'some favs-some unknowns-some umlauts'],
          tags: ['test', 'imjs', 'browser', 'intersect']
        };

        var test = function(list) {
          should.exist(list);
          list.name.should.equal(TEST_NAME);
          list.size.should.equal(2);
          options.tags.forEach(function(t) {
            expect(t).to.satisfy(list.hasTag);
          });
          list.contents().then(function(members) {
            members.map(function(m) { return m.name }).should.include('David Brent');
          }).then(function() {done()}, done);
        };

        service.intersect(options).then(test, done);
      });

    });


  });

});
}).call(this, jQuery);
