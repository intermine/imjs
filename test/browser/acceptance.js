(function($) {
describe('Acceptance', function() {

  // Running against a unwarmed-up db, or doing list operations
  // can cause things to be slower than desired. That has nothing to
  // do with this library.
  this.slow(3000);

  var invoke = function(name) {
    var args = [].slice.call(arguments, 1);
    return function(obj) {
      return obj[name].apply(obj, args);
    }
  };
  var Service = intermine.Service;

  describe('Instantiate service', function() {
    it('Should be able to create a service', function() {
      expect(new Service(service_args)).to.exist;
    });
  });

  describe('Static Resources', function() {

    var service = new Service(service_args);

    it('Should be able to get a sensible version', function(done) {
      service.fetchVersion().fail(done).done(function(v) {
        expect(v).to.be.above(8);
        done();
      });
    });

    describe('Data Model', function() {
      var modelResp = service.fetchModel();

      it('should be a model', function(done) {
        var test = function(model) {
          expect(model).to.be.an.instanceOf(intermine.Model);
          done();
        };
        modelResp.then(test, done);
      });

      it('should answer modelly questions', function(done) {
        var test = function(model) {
          expect(model.getSubclassesOf('Manager')).to.include('CEO');
          done();
        };
        modelResp.then(test, done);
      });
    });

  });

  describe('Data Requests', function() {

    var service = new Service(service_args);

    it('Should be able to count the employees', function(done) {
      service.count({select: ['id'], from: 'Employee'}).fail(done).done(function(c) {
        expect(c).to.eql(132);
        done();
      });
    });

    it('Should find lists with brenda in them', function(done) {
      var onDone = function(lists) {
        expect(lists.length).to.eql(2);
        done();
      };
      service.fetchListsContaining({type: 'Employee', publicId: 'Brenda'})
                       .then(onDone, done);
    });

    // Handy helpers for dealing with summing rows in different ways.
    Array.prototype.mapSum = function(f) {
      return this.reduce(function(acc, e) { return acc + f(e); }, 0);
    };
    var get = function (prop) {
      return function (obj) { return obj[prop] };
    };

    it('Should find the ages of the 46 employees over 50 add up to 2688', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(rows) {
        expect(rows.length).to.equal(46);
        expect(rows.mapSum(get(0))).to.eql(2688);
        done();
      };
      service.rows(oldies).then(test, done);
    });

    it('Should be able to fetch results as pojos', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(employees) {
        expect(employees.length).to.equal(46);
        expect(employees.mapSum(get('age'))).to.eql(2688);
        done();
      };
      service.records(oldies).then(test, done);
    });

    it('Should be able to fetch table rows', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(rows) {
        expect(rows.length).to.equal(46);
        expect(rows.mapSum(function(row) { return row[0].value; })).to.eql(2688);
        rows.forEach(function(row) {
          expect(row.map(get('column'))).to.include('Employee.age');
        });
        done();
      };
      service.tableRows(oldies).then(test, done);
    });
      

    it('Should be able to summarise a numeric path', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(summary, stats) {
        expect(summary.length).to.be.below(21);
        expect(summary.mapSum(get('count'))).to.equal(46);
        expect(stats.min).to.be.above(49);
        expect(stats.max).to.be.below(100);
        expect(stats.uniqueValues).to.be.above(summary.length);
        done();
      };
      service.query(oldies).then(invoke('summarise', 'age')).then(test, done);
    });

    it('Should be able to summarise a string path', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(summary, stats) {
        expect(summary.map(get('item'))).to.include('Wernham-Hogg');
        expect(stats.uniqueValues).to.equal(6);
        done();
      };
      service.query(oldies).then(invoke('summarise', 'department.company.name')).then(test, done);
    });

    it('should be able to fetch widgets', function(done) {
      var test = function(widgets) {
        expect(widgets).to.exist;
        expect(widgets.length).to.be.above(1);
        expect(widgets.filter(function(w) { return w.name === 'contractor_enrichment' }).length).to.equal(1);
        done();
      };
      service.fetchWidgets().then(test, done);
    });

    it('should be able to fetch widget mapping', function(done) {
      var test = function(widgets) {
        expect(widgets).to.exist;
        expect(widgets.contractor_enrichment).to.exist;
        expect(widgets.contractor_enrichment.widgetType).to.equal('enrichment');
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
        expect(results.length).to.equal(1);
        expect(results[0].identifier).to.equal('Vikram');
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
          expect(results.map(function(x) { return x.name })).to.eql(expected);
          done();
        };
        service.query(query).then(invoke('next')).then(invoke('records')).then(test, done);
      });

      it('Should support paging backwards via Query#previous', function(done) {
        var query = {select: ['Employee.name'], where: { age: { gt: 50 } }, limit: 10, start: 20 };
        var test = function(results) {
          expect(results.map(function(x) { return x.name })).to.eql(expected);
          done();
        };
        service.query(query).then(invoke('previous')).then(invoke('records')).then(test, done);
      });
    });
  });

  describe('ID Resolution', function() {
    var service = new Service(service_args);

    it('can resolve some ids', function(done) {
      var polls      = 0
      var expected   = 3
      var onProgress = function () { polls++ }
      var check  = function(results) {
        expect(polls).to.be.above(0);
        expect(Object.keys(results)).to.have.length(3);
        done();
      };
      var request = {
        identifiers: ['anne', 'brenda', 'carol'],
        type: 'Employee'
      };
      service.resolveIds(request).then(function(job) {
        var poll = job.poll();
        
        poll.progress(onProgress);
        poll.done(check);
        poll.fail(done);
        poll.always(job.del);
      });

    });
  });

  describe('List Life-Cycle', function() {
    var service = new Service(service_args);

    var clearUp = function(done) {
      service.fetchLists().then(function(lists) {
        var gonners = lists.filter(function(l) { return l.hasTag('test') || l.hasTag('imjs') });
        var promises = gonners.map(function(l) { return l.del() });
        $.when.apply($, promises).fail(done).done(function() { done() });
      });
    };
    this.beforeAll(clearUp);
    this.afterAll(clearUp);
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
          expect(list).to.exist;
          expect(list.name).to.equal(TEST_NAME);
          expect(list.size).to.equal(5);
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
          expect(list).to.exist;
          expect(list.name).to.equal(TEST_NAME);
          expect(list.size).to.equal(2);
          options.tags.forEach(function(t) {
            expect(t).to.satisfy(list.hasTag);
          });
          list.contents().then(function(members) {
            expect(members.map(function(m) { return m.name })).to.include('David Brent');
          }).then(function() {done()}, done);
        };

        service.intersect(options).then(test, done);
      });

    });


  });

});
}).call(this, jQuery);
