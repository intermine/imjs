describe('Acceptance', function() {

  'use strict';
  // Expects service_args to be defined.

  // Handy helpers for dealing with summing rows in different ways.
  Array.prototype.mapSum = function(f) {
    return this.reduce(function(acc, e) { return acc + f(e); }, 0);
  };
  var get = function (prop) {
    return function (obj) { return obj[prop] };
  };
  var invoke = function(name) {
    var args = [].slice.call(arguments, 1);
    return function(obj) {
      return obj[name].apply(obj, args);
    }
  };

  // Running against a unwarmed-up db, or doing list operations
  // can cause things to be slower than desired. That has nothing to
  // do with this library.
  this.slow(3000);
  this.timeout(10000);

  var Service = intermine.Service;

  describe('Overriding existing intermine', function () {
    it('should not have overridden the existing intermine reference', function () {
      expect(intermine.DO_NOT_OVERWRITE).to.eql('OK');
    });
  });

  describe('Instantiate service', function() {
    it('Should be able to create a service', function() {
      expect(new Service(service_args)).to.be.ok();
    });
  });

  describe('Static Resources', function() {

    var service = new Service(service_args);

    it('Should be able to get a sensible version', function(done) {
      service.fetchVersion().done(function(v) {
        expect(v).to.be.above(8);
        done();
      }, done);
    });

    describe('Data Model', function() {
      var modelResp = service.fetchModel();

      it('should be a model', function(done) {
        var test = function(model) {
          expect(model).to.be.an(intermine.Model);
          done();
        };
        modelResp.then(test, done);
      });

      it('should answer modelly questions', function(done) {
        var test = function(model) {
          expect(model.getSubclassesOf('Manager')).to.contain('CEO');
          done();
        };
        modelResp.then(test, done);
      });
    });

  });

  describe('Data Requests', function() {

    var service = new Service(service_args);
    this.beforeAll(function (done) {
      var isDone = function () { done(); };
      var deleting = service.fetchLists().then(deleteTempLists);

      deleting.then(isDone, isDone);

      function deleteTempLists(lists) {
        lists.forEach(deleteIfTemp);
      }
      function deleteIfTemp(list) {
        if (l.hasTag('temp') || /temp/.test(l.name)) {
          l.del() 
        }
      }
    });

    it('Should be able to count the employees', function(done) {
      service.count({select: ['id'], from: 'Employee'}).done(function(c) {
        expect(c).to.eql(132);
        done();
      }, done);
    });

    it('Should find lists with brenda in them', function(done) {
      var onDone = function(lists) {
        expect(lists.length).to.eql(2);
        done();
      };
      service.fetchListsContaining({type: 'Employee', publicId: 'Brenda'})
             .then(onDone)
             .then(null, done);
    });


    it('Should find the ages of the 46 employees over 50 add up to 2688', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(rows) {
        expect(rows.length).to.equal(46);
        expect(rows.mapSum(get(0))).to.equal(2688);
        done();
      };
      service.rows(oldies).then(test, done);
    });

    it('Should be able to fetch results as pojos', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(employees) {
        expect(employees.length).to.equal(46);
        expect(employees.mapSum(get('age'))).to.equal(2688);
        done();
      };
      service.records(oldies).then(test, done);
    });

    it('Should be able to fetch table rows', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(rows) {
        expect(rows.length).to.equal(46);
        expect(rows.mapSum(function(row) { return row[0].value; })).to.equal(2688);
        rows.forEach(function(row) {
          expect(row.map(get('column'))).to.contain('Employee.age');
        });
        done();
      };
      service.tableRows(oldies).then(test, done);
    });
      

    it('Should be able to summarise a numeric path', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(data) {
        var summary = data.results;
        var stats = data.stats;
        expect(summary.length).to.be.below(21);
        expect(summary.mapSum(get('count'))).to.equal(46);
        expect(stats.min).to.be.above(49);
        expect(stats.max).to.be.below(100);
        expect(stats.uniqueValues).to.be.above(summary.length);
        done();
      };
      service.query(oldies).then(invoke('summarise', 'age')).done(test, done);
    });

    it('Should be able to summarise a string path', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(data) {
        var summary = data.results;
        var stats = data.stats;
        expect(summary.map(get('item'))).to.contain('Wernham-Hogg');
        expect(stats.uniqueValues).to.equal(6);
        done();
      };
      service.query(oldies).then(invoke('summarise', 'department.company.name')).done(test, done);
    });

    it('should be able to fetch widgets', function(done) {
      var test = function(widgets) {
        expect(widgets).to.be.ok();
        expect(widgets.length).to.be.above(1);
        expect(widgets.filter(function(w) { return w.name === 'contractor_enrichment' }).length).to.equal(1);
        done();
      };
      service.fetchWidgets().done(test, done);
    });

    it('should be able to fetch widget mapping', function(done) {
      var test = function(widgets) {
        expect(widgets).to.be.ok();
        expect(widgets.contractor_enrichment).to.be.ok();
        expect(widgets.contractor_enrichment.widgetType).to.equal('enrichment');
        done();
      };
      service.fetchWidgetMap().done(test, done);
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
      service.enrichment(args).done(test, done);
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
      var test = function(done) {
        return function (results) {
          expect(results.map(get('name'))).to.eql(expected);
          done();
        };
      };

      it('Should support paging forwards via Query#next', function(done) {
        var query = {select: ['Employee.name'], where: { age: { gt: 50 } }, limit: 10, start: 0 };
        service.query(query).then(invoke('next')).then(invoke('records')).done(test(done), done);
      });

      it('Should support paging backwards via Query#previous', function(done) {
        var query = {select: ['Employee.name'], where: { age: { gt: 50 } }, limit: 10, start: 20 };
        service.query(query).then(invoke('previous')).then(invoke('records')).done(test(done), done);
      });
    });
  });

  describe('ID Resolution', function() {
    var service = new Service(service_args);

    it('can resolve some ids', function(done) {
      var polls      = 0
      var expected   = 3
      var request = { type: 'Employee', identifiers: ['anne', 'brenda', 'carol'] };

      Q.all([service.fetchVersion(), service.resolveIds(request)]).done(testJob, done);
      
      function testJob (args) {
        var v = args[0];
        var job = args[1];
        var poll = job.poll();
        
        poll.then(check(v), done).done(job.del, job.del);
      }

      function check (version) {
        console.log("Testing ID resolution service @" + version);
        return function(results) {
          if (version >= 16) {
            var keys = Object.keys(results);
            expect(keys).to.have.length(4);
            expect(results).to.have.keys('matches', 'stats', 'unresolved', 'type');
            expect(results.stats.objects.matches).to.equal(3);
            expect(results.stats.objects.issues).to.equal(0);
          } else {
            expect(Object.keys(results)).to.have.length(3);
          }

          done();
        };
      }
    });
  });

  describe('List Life-Cycle', function() {
    var service = new Service(service_args);

    var clearUp = function(done) {
      service.fetchLists().then(function(lists) {
        var gonners = lists.filter(function(l) { return l.hasTag('test') || l.hasTag('imjs') });
        var promises = gonners.map(function(l) { return l.del() });
        Q.all(promises).then(function() { done();}, done);
      }, done);
    };
    this.beforeAll(clearUp);
    this.afterAll(clearUp);

    describe('Create List via Identifier Upload', function() {

      var TEST_NAME = 'test-list-from-idents';

      this.beforeAll(function(done) {
        var ok = function () { done() };
        service.fetchList(TEST_NAME).then(function(l) {
          return l.del();
        }).then(ok, ok);
      });

      it('should have the right name, size, tags', function(done) {
        var opts = {
          name: TEST_NAME,
          type: 'Employee',
          description: 'A list created to test the upload mechanism',
          tags: [ 'temp', 'imjs', 'browser', 'test' ]
        };
        var idents = [
          'anne, "brenda"',
          'carol',
          '"David Brent" Edgar',
          'rubbishy identifiers',
          'Fatou'
        ].join("\n");
        var test = function(list) {
          expect(list).to.be.ok();
          expect(list.name).to.equal(TEST_NAME);
          expect(list.size).to.equal(5);
          opts.tags.forEach(function(t) {
            expect(list.hasTag(t)).to.be.ok();
          });
          done();
        };
        service.createList(opts, idents).done(test, done);
      });

    });

    describe('Combine through Intersection', function() {

      var TEST_NAME = 'intersection-test';

      it('should have the right name, size, tags, member', function(done) {
        var options = {
          name: TEST_NAME,
          description: 'A list created to test out the intersection operation',
          lists: ['My-Favourite-Employees', 'some favs-some unknowns-some umlauts'],
          tags: ['test', 'imjs', 'browser', 'intersect']
        };

        var test = function(list) {
          expect(list).to.be.ok();
          expect(list.name).to.equal(TEST_NAME);
          expect(list.size).to.equal(2);
          options.tags.forEach(function(t) {
            expect(list.hasTag(t)).to.be.ok();
          });
          list.contents().then(function(members) {
            expect(members.map(function(m) { return m.name })).to.contain('David Brent');
          }).then(function() {done()}, done);
        };

        service.intersect(options).done(test, done);
      });

    });


  });

});
