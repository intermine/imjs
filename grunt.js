module.exports = function (grunt) {
    grunt.initConfig({
        pkg: '<json:package.json>',
        lint: {
            tests: ['test/qunit/t/*.js'],
            grunt: ['grunt.js']
        },
        coffeelint: {
            source: ['src/*.coffee']
        },
        coffeelintOptions: '<json:coffeelint.json>',
        jshint: {
            options: {
                laxcomma: true,
                asi: true,
                curly: true,
                maxparams: 5
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
            index: ['test/qunit/index.html']
        }
    });

    grunt.loadNpmTasks('grunt-coffeelint');

    grunt.registerTask('default', 'lint coffeelint qunit');
};

