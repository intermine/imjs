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
    concat: {
      options: {
        banner: banner,
        nonull: true,
        process: processBuildFile
      },
      latest: {
        src: grunt.file.readJSON('build-order.json'),
        dest: 'js/im.js',
      },
      "in-version-dir": {
        src: grunt.file.readJSON('build-order.json'),
        dest: 'js/<%= pkg.version %>/im.js'
      }
    },
    uglify: {
      latest: {
        files: {
          'js/im.min.js': ['js/im.js']
        }
      },
      version: {
        src: 'js/<%= pkg.version %>/im.js',
        dest: 'js/<%= pkg.version %>/im.min.js'
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
          src: ['test/browser/*.js']
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
      all: ['test/browser/index.html']
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

  grunt.loadNpmTasks('grunt-bump');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-simple-mocha')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-mocha-phantomjs');
  grunt.loadNpmTasks('grunt-contrib-symlink');
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
    var processed = grunt.template.process(templ.toString(), {data: obj});
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
    var processed = grunt.template.process(templ.toString(), {data: obj});
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

  grunt.registerTask('phantomjs', ['build-acceptance-index', 'mocha_phantomjs']);

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
    var cdn = grunt.config('CDN');
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

  grunt.registerTask('cdn', ['default', '-checkcdn', 'copy:cdn', 'clean:cdnlinks', 'symlink']);
  grunt.registerTask('bmp', ['bump-only', 'default', 'bump-commit']);
  grunt.registerTask('build', ['clean:build', 'compile', 'concat', 'uglify'])
  grunt.registerTask('justtest',['build', '-load-test-globals', '-testglob']);
  grunt.registerTask('test', ['build', 'test-node', 'phantomjs']);
  grunt.registerTask('default', ['jshint', 'coffeelint', 'test'])

}
