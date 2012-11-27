module.exports = function (grunt) {
    'use strict';

    grunt.initConfig({
        pkg: '<json:package.json>',
        meta: {
            banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                    '<%= grunt.template.today("yyyy-mm-dd") %> */'
        },
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
                src: 'src',
                dest: 'build'
            }
        },
        coffeelintOptions: '<json:coffeelint.json>',
        jshint: {
            options: {
                laxcomma: true,
                asi: true,
                curly: true,
                maxparams: 5
            },
            grunt: {
                options: {
                    laxcomma: true,
                    asi: true,
                    curly: true,
                    node: true
                }
            },
            tests: {
                options: {
                    laxcomma: true,
                    asi: true,
                    curly: true,
                    maxparams: 5,
                    indent: 4,
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
        qunit: {
            index: ['test/qunit/build/*-qunit.html']
        },
        buildqunit: {
            unified: true,
            template: "test/qunit/templates/index.html",
            dest: "test/qunit/build/<%= idx %>-<%= file %>-qunit.html",
            tests: ["test/qunit/t/*.js"],
            setup: ["test/qunit/t/index.js"],
            tested: ["js/*.js"]
        },
        clean: {
            qunit: 'test/qunit/build',
            build: 'build'
        },
        simplemocha: {
            all: {
                src: 'test/mocha/*',
                options: {
                    globals: ['should'],
                    compiler: "coffee:coffee-script",
                    timeout: 3000,
                    ignoreLeaks: false,
                    ui: 'bdd',
                    reporter: 'dot'
                }
            }
        }
    });

    grunt.loadTasks('tasks');
    grunt.loadNpmTasks('grunt-coffeelint');
    grunt.loadNpmTasks('grunt-simple-mocha');
    grunt.loadNpmTasks('grunt-clean');

    grunt.registerTask('-load-test-globals', function () { global.should = require('should') });

    grunt.registerTask('run-qunit-tests', 'compile concat clean:qunit buildqunit qunit');
    grunt.registerTask('node-test', 'compile -load-test-globals simplemocha');
    grunt.registerTask('default', 'lint coffeelint node-test run-qunit-tests min');

};

