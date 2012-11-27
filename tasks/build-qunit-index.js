/**
 * A Task for generating the html files consumed
 * by the QUnit testing framework.
 *
 * The user supplies a list of files and a template that has the
 * appropriate keys, and either a single html file or a list of separate ones are
 * generated
 */
module.exports = function (grunt) {
    'use strict';

    var fs = require('fs')
      , _  = require('underscore')._

    function writeUnified (data, conf, done) {
        var compiled = grunt.template.process(data, conf)
          , dest = grunt.template.process(conf.dest, {idx: 0, file: 'all'})
          , written = grunt.file.write(dest, compiled);
        if (written) {
            grunt.log.ok("Wrote " + dest);
        } else {
            grunt.log.error("Failed to write " + dest);
        }
        done(written);
    }

    function writeSeparate (data, conf, done) {
        _.each(conf.testFiles, function (tf, idx) {
            var ctx = _.defaults({}, {testFiles: [tf]}, conf)
                , compiled = grunt.template.process(data, ctx)
                , file = _.last(tf.split('/'))
                , dest = grunt.template.process(conf.dest, {idx: idx, file: file});
            grunt.verbose.writeln("Writing to " + dest);
            return grunt.file.write(dest, compiled);
        });
        grunt.log.ok("Wrote " + conf.testFiles.length + " files");
        done(true);
    }

    function getHandler (conf, done) {
        var write = conf.unified ? writeUnified : writeSeparate;

        return function (err, data) {
            if (err) {
                grunt.log.error('Could not read template file: ' + (err.stack || err));
                done(false);
            } else {
                write(data, conf, done);
            }
        };
    }
    
    grunt.registerTask('buildqunit', 'Build the QUnit index file', function () {
        var template
          , log = grunt.log
          , done = this.async()
          , conf = grunt.config('buildqunit')
        
        //this.requiresConfig('template', 'tests', 'tested');

        conf.setup = (conf.setup || '');
        conf.dest = (conf.dest || 'qunit-index.html');
        conf.targets = grunt.file.expandFileURLs(conf.tested);
        conf.setupFiles = grunt.file.expandFileURLs(conf.setup);
        conf.testFiles = _.difference(grunt.file.expandFileURLs(conf.tests), conf.setupFiles);

        fs.readFile(conf.template, 'utf8', getHandler(conf, done));
    });
};
