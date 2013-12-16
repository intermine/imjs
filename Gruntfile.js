module.exports = function (grunt) {
  'use strict';

  var path = require('path');
  var fs = require('fs');
  var banner = '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                  '<%= grunt.template.today("yyyy-mm-dd") %> */\n' +
                  grunt.file.read('LICENCE');

  function processBuildFile (src, filepath) {
    if (filepath === 'build/version.js') { // please tell me there is a saner way to do this.
      return grunt.template.process(src);
    } else {
      return src;
    }
  }

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    uglify: {
      /*
      latest: {
        files: {
          'js/im.min.js': ['js/im.js']
        }
      },
      */
      bundle: {
        files: {
          'dist/im.min.js': ['dist/im.js']
        }
      } /*,
      version: {
        src: 'js/<%= pkg.version %>/im.js',
        dest: 'js/<%= pkg.version %>/im.min.js'
      } */
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
      cdnlinks: {
        src: ['<%= CDN %>/js/intermine/imjs/latest', '<%= CDN %>/js/intermine/imjs/<%= pkg.version.replace(/\\d+$/, "x") %>'],
        options: {force: true}
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
          'dist/im.js': ['build/service.js']
        },
        options: {
          alias: ['build/http-browser.js:./http'],
          ignore: ['xmldom'],
          noParse: ['node_modules/httpinvoke/httpinvoke-commonjs.js'],
          standalone: 'imjs',
          postBundleCB: bundled,
        }
      },
      tests: {
        files: {
          'test/browser/mocha-test.js': ['test/mocha/*.coffee'],
        },
        options: {
          transform: ['coffeeify', 'envify'],
          alias: [
            'build/http-browser.js:./http',
            'test/mocha/lib/utils.coffee:./lib/utils',
            'test/mocha/lib/fixture.coffee:./lib/fixture',
            'test/mocha/lib/fixture.coffee:./fixture',
            'node_modules/should/should.js:should'
          ],
          ignore: ['xmldom'],
          noParse: [
            'node_modules/httpinvoke/httpinvoke-commonjs.js',
            'node_modules/should/should.js',
            'js/im.js'
          ]
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
    try {
      var bundleBanner = grunt.template.process(banner)
      var shiv = grunt.file.read("build/shiv.js")
      var openIFE = "(function (intermine) {";
      var closeIFE ='})(window.intermine);';
      var expose = grunt.file.read('build/export.js');
      next(null, [bundleBanner, shiv, openIFE, src, expose, closeIFE].join("\n"))
    } catch (e) {
      next(e)
    }
  }

  function injectVersion(file) {
    var src, dest, temp, output;
    src = dest = 'build/version.js';
    temp = grunt.file.read(src);
    output = grunt.template.process(temp);
    grunt.file.write(dest, output, {encoding: 'utf8'});
    grunt.log.writeln("Injected version");
  }

  grunt.loadNpmTasks("grunt-jscoverage")
  grunt.loadNpmTasks('grunt-bump')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-jshint')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-simple-mocha')
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
    var path = getVar('path', 'intermine-test');
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

  grunt.registerTask('docs', 'Generate API documentation', function () {
    var done = this.async()
    var cmd = './node_modules/codo/bin/codo'
    var args = ['-n', 'imjs', 'src']
    var child = require('child_process').spawn(cmd, args, {stdio: 'inherit'})
    child.on('exit', function (code) {
      done(code === 0);
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

  grunt.registerTask('test-node', 'Run tests in the nodejs VM', function () {
    var grep = grunt.option('grep')
    var reporter = grunt.option('reporter')
    if (grep) {
      grunt.config('simplemocha.all.options.grep', grep)
    }
    if (reporter) {
      grunt.config('simplemocha.all.options.reporter', reporter)
    }
    grunt.task.run('simplemocha:all')
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

  grunt.registerTask('cdn', ['default', '-checkcdn', 'copy:cdn', 'clean:cdnlinks', 'symlink'])
  grunt.registerTask('bmp', ['bump-only', 'default', 'bump-commit'])
  grunt.registerTask('build', [
    'clean:build',
    'compile',
    '-inject-version',
    'browserify',
    'uglify',
    'copy:dist',
    'copy:version',
    'browser-indices'
  ])
  grunt.registerTask('demo', ['build', 'browser-indices'])
  grunt.registerTask('justtest',['build', '-load-test-globals', '-testglob'])
  grunt.registerTask('test', ['build', 'test-node', 'phantomjs'])
  grunt.registerTask('default', ['jshint', 'coffeelint', 'test'])

}
