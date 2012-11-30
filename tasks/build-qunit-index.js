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
      var html, dest, written = false;
      try {
        compiled = template.process(data, conf);
        dest     = template.process(conf.dest, {idx: 0, file: 'all'})
        written  = grunt.file.write(dest, compiled);
        grunt.log.ok("Wrote " + dest);
      } catch (e) {
        grunt.log.error("Failed to write html");
      }
      done(written);
    }

    function writeSeparate (data, conf, done) {
      var tf, idx, uri, fileName, destFile, html;
      var files = conf.testFiles;
      var filesL = files.length;
      var fileName, destFile, html;
      for (idx = 0; idx < filesL; idx++) {
        uri      = files[idx];
        fileName = path.basename(uri);
        destFile = template.process(conf.dest, {idx: idx, file: fileName});
        html     = template.process(data, _.defaults({testFiles: [uri]}, conf));
        try {
          grunt.file.write(destFile, html);
          grunt.verbose.writeln("Wrote " + destFile);
        } catch (e) {
          grunt.log.error('Failed to write ' + destFile);
          return done(false);
        }
      }
      grunt.log.ok("Wrote " + filesL + " html files");
      return done(true);
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
      conf.dest       = (conf.dest  || 'qunit-index.html');
      conf.targets    = expandFileURLs(conf.tested);
      conf.setupFiles = expandFileURLs(conf.setup);
      conf.testFiles  =
        _.difference(expandFileURLs(conf.tests), conf.setupFiles);

      fs.readFile(conf.template, 'utf8', getHandler(conf, done));
    });
};
