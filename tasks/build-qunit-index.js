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

    var fs = require('fs');
    var path = require('path');
    var _  = require('underscore')._;
    var template = grunt.template;

    function writeUnified (data, conf, done) {
        var compiled = template.process(data, conf);
        var dest = template.process(conf.dest, {idx: 0, file: 'all'})
        var written = grunt.file.write(dest, compiled);
        if (written) {
            grunt.log.ok("Wrote " + dest);
        } else {
            grunt.log.error("Failed to write " + dest);
        }
        done(written);
    }

    function writeSeparate (data, conf, done) {
        _.each(conf.testFiles, function handleFile(tf, idx) {
            var file     = path.basename(tf);
            var destCtx  = {idx: idx, file: file};
            var templCtx = _.defaults({}, {testFiles: [tf]}, conf);
            var dest     = template.process(conf.dest, destCtx);
            var compiled = template.process(data, templCtx);
            grunt.verbose.writeln("Writing " + dest);
            return grunt.file.write(dest, compiled);
        });
        grunt.log.ok("Wrote " + conf.testFiles.length + " files");
        done(true);
    }

    function getHandler (conf, done) {
        var write = conf.unified ? writeUnified : writeSeparate;

        return function handler(err, data) {
            if (err) {
                grunt.log.error('Could not read template file: ' + (err.stack || err));
                done(false);
            } else {
                write(data, conf, done);
            }
        };
    }
    
    grunt.registerTask(
            'buildqunit',
            'Build the QUnit index file',
            function buildqunit() {
        var done = this.async();
        var conf = grunt.config('buildqunit');
        var expandFileURLs = grunt.file.expandFileURLs;

        conf.setup      = (conf.setup || '');
        conf.dest       = (conf.dest || 'qunit-index.html');
        conf.targets    = expandFileURLs(conf.tested);
        conf.setupFiles = expandFileURLs(conf.setup);
        conf.testFiles  =
            _.difference(expandFileURLs(conf.tests), conf.setupFiles);

        fs.readFile(conf.template, 'utf8', getHandler(conf, done));
    });
};
