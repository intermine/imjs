module.exports = function (grunt) {
  'use strict';

  var path = require('path');
  var fs = require('fs');

  var banner = '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
               '<%= grunt.template.today("yyyy-mm-dd") %> */'

  grunt.initConfig({
    pkg: '<json:package.json>',
    meta: { banner: banner },
    concat: {
      latest: {
        src: '<json:build-order.json>',
        dest: 'js/im.js'
      },
      "in-version-dir": {
        src: '<json:build-order.json>',
        dest: 'js/<%= pkg.version %>/im.js'
      }
    },
    min: {
      latest: {
        src: 'js/im.js',
        dest: 'js/im.min.js'
      },
      version: {
        src: 'js/<%= pkg.version %>/im.js',
        dest: 'js/<%= pkg.version %>/im.min.js'
      }
    },
    lint: {
      tests: ['test/qunit/t/*.js'],
      grunt: ['tasks/*.js', 'grunt.js']
    },
    coffeelint: {
      source: ['src/*.coffee'],
      mocha: ['test/mocha/*.coffee']
    },
    compile: {
      source: {
        src: 'src/*',
        dest: 'build'
      }
    },
    coffeelintOptions: '<json:coffeelint.json>',
    jshint: {
      // Follow github's style guidelines and Crockford's where those are not sufficient
      // * https://github.com/styleguide/javascript
      // * http://javascript.crockford.com/code.html
      options: {
        laxcomma: true,
        asi: true,
        curly: true,
        maxparams: 5
      },
      grunt: {
        options: {
          asi: true,
          curly: true,
          maxparams: 5,
          indent: 2,
          node: true
        }
      },
      tests: {
        options: {
          asi: true,
          curly: true,
          maxparams: 5,
          indent: 2,
          browser: true,
          devel: true,
          jquery: true
        },
        globals: {
          TestCase: true,
          _: true,
          test: true,
          asyncTest: true,
          start: true,
          ok: true,
          equal: true,
          notEqual: true,
          module: true,
          deepEqual: true,
          intermine: true
        }
      }
    },
    clean: {
      qunit: 'test/qunit/build',
      build: 'build'
    },
    simplemocha: {
      all: {
        src: 'test/mocha/*.coffee',
        options: '<json:mocha-opts.json>'
      }
    },
    copy: {
      cdn: {
        files: {
          '<%= process.env.CDN %>/js/intermine/imjs/<%= pkg.version %>/': 'js/<%= pkg.version %>/*.js',
          '<%= process.env.CDN %>/js/intermine/imjs/latest/': 'js/<%= pkg.version %>/*.js'
        }
      }
    }
  })

  grunt.loadNpmTasks('grunt-bump');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-simple-mocha')
  grunt.loadNpmTasks('grunt-clean')
  grunt.loadTasks('tasks')

  grunt.registerTask('-load-test-globals', function () {
    global.should = require('should')
  });

  grunt.registerTask(
    'build-acceptance-index',
    'Build a index.html page to run acceptance tests', function () {
    var templ = grunt.file.read('test/browser/template.html', 'utf8');
    var outf = 'test/browser/index.html';
    var root = process.env.TESTMODEL_URL ||
      grunt.option('root') ||
      "http://localhost:8080/intermine-test";
    var obj = {
      mocha: {
        css: "../../components/mocha/mocha.css",
        js: "../../components/mocha/mocha.js"
      },
      args: {
        root: root,
        token: "test-user-token"
      },
      expect: "../../components/expect/expect.js",
      jquery: "../../components/jquery/jquery.js",
      underscore: "../../components/underscore/underscore.js",
      imjs: "../../js/im.js"
    };
    var processed = grunt.template.process(templ.toString(), obj);
    grunt.file.write(outf, processed);
    grunt.log.writeln('Wrote ' + outf);
  });

  grunt.registerTask(
    'build-static-acceptance-index',
    'Build a index.html page to run acceptance tests', function () {
    var templ = grunt.file.read('test/browser/template.html', 'utf8');
    var outf = 'test/browser/acceptance.html';
    var root = process.env.TESTMODEL_URL ||
      grunt.option('root') ||
      "http://localhost:8080/intermine-test";
    var obj = {
      mocha: {
        css: "http://cdn.intermine.org/js/mocha/1.8.1/mocha.css",
        js: "http://cdn.intermine.org/js/mocha/1.8.1/mocha.js"
      },
      args: {
        root: root,
        token: grunt.option('token') || "test-user-token"
      },
      expect: "http://cdn.intermine.org/js/expect/latest/expect.js",
      jquery: "http://code.jquery.com/jquery-1.9.1.min.js",
      underscore: "http://cdn.intermine.org/js/underscore.js/1.3.3/underscore-min.js",
      imjs: "http://ci.intermine.org/job/imjs/lastSuccessfulBuild/artifact/js/im.js"
    };
    var processed = grunt.template.process(templ.toString(), obj);
    grunt.file.write(outf, processed);
    grunt.log.writeln('Wrote ' + outf);
  });

  grunt.registerTask('docs', 'Generate API documentation', function () {
    var done = this.async();
    var cmd = './node_modules/codo/bin/codo';
    var args = ['-n', 'imjs', 'src'];
    var child = require('child_process').spawn(cmd, args, {stdio: 'inherit'});
    child.on('exit', function (code) {
      done(code === 0);
    });
  });

  grunt.registerTask('mocha-phantomjs', 'build-acceptance-index -mocha-phantomjs');
  grunt.registerTask('-mocha-phantomjs', 'Run tests in phantomjs', function () {
    var done = this.async();
    var cmd = './node_modules/mocha-phantomjs/bin/mocha-phantomjs';
    var args = ['test/browser/index.html'];
    var reporter = grunt.option('reporter');
    if (reporter) {
      args.push('-R');
      args.push(reporter);
    }
    var child = require('child_process').spawn(cmd, args, {stdio: 'inherit'});
    child.on('exit', function (code) {
      done(code === 0);
    });
  });

  grunt.registerTask('test-node', 'Run tests in the nodejs VM', function () {
    var grep = grunt.option('grep');
    var reporter = grunt.option('reporter');
    if (grep) {
      grunt.config('simplemocha.all.options.grep', grep);
    }
    if (reporter) {
      grunt.config('simplemocha.all.options.reporter', reporter);
    }
    grunt.task.run('simplemocha:all');
  });

  grunt.registerTask('-checkcdn', 'Check that the CDN is initialised', function () {
    var done = this.async();
    var cdn = process.env.CDN;
    if (!cdn) {
      grunt.log.error("No CDN location provided. Please set the CDN environment variable");
      done(false);
    }
    fs.stat(cdn, function (err, stats) {
      if (err) {
        grunt.log.error("Problem with CDN location: " + err);
        done(false);
      } else if (!stats.isDirectory()) {
        grunt.log.error("CDN location is not a directory");
        done(false);
      } else {
        grunt.log.writeln("CDN configured as: " + cdn);
        done();
      }
    });
  });

  grunt.registerTask('cdn', 'default -checkcdn copy:cdn');
  grunt.registerTask('build', 'clean:build compile concat min')
  grunt.registerTask('justtest', 'build -load-test-globals -testglob');
  grunt.registerTask('test', 'build test-node mocha-phantomjs');
  grunt.registerTask('default', 'lint coffeelint test')

}
