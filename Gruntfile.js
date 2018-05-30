module.exports = function (grunt) {
  'use strict';

  var path = require('path');
  var derequire = require('derequire');
  var insertModuleGlobals = require('insert-module-globals');
  var fs = require('fs');
  var banner = '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                  '<%= grunt.template.today("yyyy-mm-dd") %> */\n' +
                  grunt.file.read('LICENCE');

  function insertVars (names) {
    return names.reduce(function (vars, name) {
      vars[name] = insertModuleGlobals.vars[name];
      return vars;
    }, {});
  }

  function processBuildFile (src, filepath) {
    if (filepath === 'build/version.js') { // please tell me there is a saner way to do this.
      return grunt.template.process(src);
    } else {
      return src;
    }
  }

  var shouldjs = require.resolve('should');

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    uglify: {
      bundle: {
        files: {
          'dist/im.min.js': ['dist/im.js']
        }
      }
    },
    coffeelint: {
      options: grunt.file.readJSON('coffeelint.json'),
      source: ['src/*.coffee'],
      mocha: ['test/mocha/*.coffee']
    },
    compile: {
      source: {
        src: 'src/*',
        dest: 'build'
      },
      shims: {
        src: 'src/shims/*',
        dest: 'build/shims'
      },
      tests: {
        src: 'test/mocha/*.coffee',
        dest: 'test/compiled'
      },
      testlib: { // This is ugly - should be one task.
        src: 'test/mocha/lib/*.coffee',
        dest: 'test/compiled/lib'
      }
    },
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
        },
        files: {
          src: ["Gruntfile.js", "tasks/*.js"]
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
        },
        files: {
          src: ['test/browser/acceptance.js']
        }
      }
    },
    clean: {
      qunit: ['test/qunit/build'],
      build: ['build'],
      tests: ['test/compiled'],
      cdnlinks: {
        src: ['<%= CDN %>/js/intermine/imjs/latest', '<%= CDN %>/js/intermine/imjs/<%= pkg.version.replace(/\\d+$/, "x") %>'],
        options: {force: true}
      }
    },
    mochaTest: {
      unit: {
        src: ['test/compiled/*.js'],
        options: grunt.file.readJSON('mocha-opts.json')
      }
    },
    simplemocha: {
      all: {
        src: 'test/mocha/*.coffee',
        options: grunt.file.readJSON('mocha-opts.json')
      }
    },
    mocha_phantomjs: {
      all: ['test/browser/index.html'],
      bundle: ['test/browser/bundle-index.html']
    },
    bump: {
      options: {
        files: ['package.json', 'bower.json'],
        commitFiles: ['-a'],
        updateConfigs: ['pkg'],
        pushTo: 'origin'
      }
    },
    CDN: process.env.CDN,
    copy: {
      dist: {
        files: [{
          expand: true,
          src: ['*.js'],
          cwd: 'dist',
          dest: 'js/',
          flatten: true,
          filter: 'isFile'
        }]
      },
      version: {
        files: [{
          expand: true,
          src: ['*.js'],
          cwd: 'dist',
          flatten: true,
          dest: 'js/<%= pkg.version %>/',
          filter: 'isFile'
        }]
      },
      cdn: {
        files: [{
          expand: true,
          cwd: 'js/<%= pkg.version %>',
          src: ['*.js'],
          filter: 'isFile',
          flatten: true,
          dest: '<%= CDN %>/js/intermine/imjs/<%= pkg.version %>/'
        }]
      }
    },
    browserify: {
      dist: {
        files: {
          'dist/im.js': ['build/export.js']
        },
        options: {
          browserifyOptions: {
            standalone: 'imjs',
            insertGlobalVars: insertVars(['process', 'global', '__filename', '__dirname'])
          },
          postBundleCB: bundled,
        }
      },
      tests: {
        files: {
          'test/browser/mocha-test.js': ['test/compiled/**/*.js'],
        },
        options: {
          transform: ['envify'],
          alias: [
            shouldjs + ':should'
          ],
          browserifyOptions: {
            insertGlobalVars: insertVars(['process', 'global', '__filename', '__dirname'])
          }
        }
      }
    },
    jscoverage: {
      options: {
        inputDirectory: 'build',
        outputDirectory: 'build-cov'
      }
    },
    symlink: {
      options: {
        overwrite: true,
        force: true
      },
      latest: {
        src: '<%= CDN %>/js/intermine/imjs/<%= pkg.version %>',
        dest: '<%= CDN %>/js/intermine/imjs/latest'
      },
      group: {
        src: '<%= CDN %>/js/intermine/imjs/<%= pkg.version %>',
        dest: '<%= CDN %>/js/intermine/imjs/<%= pkg.version.replace(/\\d+$/, "x") %>'
      }
    }
  })

  function bundled (error, src, next) {
    if (error) {
      return next(error);
    }
    try {
      var bundleBanner = grunt.template.process(banner)
      var openIFE = "(function (intermine) {";
      var closeIFE ='})(window.intermine);';
      next(null, derequire([bundleBanner, openIFE, src, closeIFE].join("\n")));
    } catch (e) {
      next(e)
    }
  }

  function injectVersion(file) {
    var src, dest, temp, output
    src = dest = 'build/version.js'
    temp = grunt.file.read(src)
    output = grunt.template.process(temp)
    grunt.file.write(dest, output, {encoding: 'utf8'})
    grunt.log.writeln("Injected version")
  }

  grunt.loadNpmTasks("grunt-jscoverage")
  grunt.loadNpmTasks('grunt-bump')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-jshint')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-mocha-test')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-mocha-phantomjs')
  grunt.loadNpmTasks('grunt-contrib-symlink')
  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadTasks('tasks')

  grunt.registerTask('-load-test-globals', function () {
    global.should = require('should')
  })

  function writeTestIndex(src, dest, options) {
    var templ = grunt.file.read(src, 'utf8')
    var outf = dest;
    var host = getVar('host', null);
    var port = getVar('port', null);
    var load = getVar('load', null);
    var path = getVar('path', 'intermine-demo');
    var tokn = getVar('token', 'test-user-token');
    var obj = {
      args: {
        host: host,
        path: path,
        port: port,
        token: tokn
      },
      load: load,
      mocha: {
        css: "../../bower_components/mocha/mocha.css",
        js: "../../bower_components/mocha/mocha.js"
      },
      expect: {
        js: "../../bower_components/expect/expect.js"
      },
      promise: {
        js: "../../bower_components/q/q.js"
      }
    }
    var processed = grunt.template.process(templ.toString(), {data: obj})
    grunt.file.write(outf, processed)
    grunt.log.writeln('Wrote ' + outf)

    function getVar(key, otherwise) {
      return process.env['TESTMODEL_' + key.toUpperCase()] ||
        grunt.option(key) ||
        options[key] ||
        otherwise;
    }
  }

  grunt.registerTask(
    '-inject-version',
    'Inject the current version number into the build',
    injectVersion
  )

  grunt.registerTask(
    'build-unit-test-suite',
    'build the test suite loaded by phantom js', function () {
    writeTestIndex('test/browser/bundle-template.html', 'test/browser/bundle-index.html', {
      host: 'localhost',
      port: '8080',
      load: 'mocha-test.js'
    })
  })

  grunt.registerTask(
    'build-acceptance-index',
    'Build a index.html page to run acceptance tests in the browser. Since by default this task generates an html file' +
    ' that connects to a test server on the same host and port as the current browser location, the primary function' +
    ' of this task is to generate a page that does not require cross-domain requests and enables ie8 to be tested.',
    function () {
    writeTestIndex('test/browser/template.html', 'test/browser/accept.html', {load: '../../js/im.js'})
  })

  grunt.registerTask(
    'build-phantom-acceptance-index',
    'Build a index.html page to run acceptance tests in phantomjs', function () {
    writeTestIndex('test/browser/template.html', 'test/browser/index.html', {
      host: 'localhost',
      port: '8080',
      load: '../../js/im.js'
    })
  })

  grunt.registerTask(
    'build-static-acceptance-index',
    'Build a index.html page to run acceptance tests as a static file', function () {
    writeTestIndex('test/browser/template.html', 'test/browser/acceptance.html', {
      host: 'demo.intermine.org',
      port: '80',
      path: 'testmine',
      load: '../../js/im.js'
    })
  })

  grunt.registerTask('phantomjs', [
    'build-phantom-acceptance-index',
    'build-unit-test-suite',
    'mocha_phantomjs'
  ])

  grunt.registerTask('browser-indices', [
    'build-acceptance-index',
    'build-static-acceptance-index'
  ])

  grunt.registerTask('mocha-node', 'Run tests in the nodejs VM', function () {
    grunt.task.run('-set-test-files')
    grunt.task.run('mochaTest:unit')
  })

  grunt.registerTask('-checkcdn', 'Check that the CDN is initialised', function () {
    var done = this.async()
    var cdn = grunt.config('CDN')
    if (!cdn) {
      grunt.log.error("No CDN location provided. Please set the CDN environment variable")
      done(false)
    }
    fs.stat(cdn, function (err, stats) {
      if (err) {
        grunt.log.error("Problem with CDN location: " + err)
        done(false)
      } else if (!stats.isDirectory()) {
        grunt.log.error("CDN location is not a directory")
        done(false)
      } else {
        grunt.log.writeln("CDN configured as: " + cdn);
        done();
      }
    })
  })
  grunt.registerTask(
      '-set-test-files',
      'Set the value of the browserify test files', function () {
    var grep = grunt.option('grep')
    var reporter = grunt.option('reporter')
    if (grep) {
      grunt.config('mochaTest.unit.options.grep', grep)
      grunt.config('browserify.tests.files', {
        'test/browser/mocha-test.js': ['test/compiled/*' + grep + '*.js']
      })
    }
    if (reporter) {
      grunt.config('mochaTest.unit.options.reporter', reporter)
    }
  })

  grunt.registerTask('cdn', ['default', '-checkcdn', 'copy:cdn', 'clean:cdnlinks', 'symlink'])
  grunt.registerTask('bmp', ['bump-only', 'default', 'bump-commit'])
  grunt.registerTask('build', [
    'clean:build',
    'clean:tests',
    'compile',
    '-inject-version',
    'browserify',
    'uglify',
    'copy:dist',
    'copy:version'
  ])
  grunt.registerTask('demo', ['build', 'browser-indices'])
  grunt.registerTask('lint', ['jshint', 'coffeelint'])
  grunt.registerTask('test', ['lint', 'build', 'mocha-node'])
  grunt.registerTask('test:node', ['compile', 'mocha-node'])
  // grunt.registerTask('test:browser', ['-set-test-files', 'build', 'browser-indices', 'phantomjs'])
  grunt.registerTask('default', ['test'])

}
