/**
 * Compile coffeescript source files.
 */
module.exports = function (grunt) {
  'use strict';

  var fs = require('fs');
  var path = require('path');
  var coffee = require('coffee-script');

  var writeJS = function (dest, file, js, reportError) {
    var baseName = path.basename(file, path.extname(file));
    var newName = path.join(dest, baseName + '.js');
    fs.writeFile(newName, js, function (e) {
      if (e) {
        grunt.log.error('Failed to write ' + newName);
      } else {
        grunt.verbose.ok('Wrote ' + newName);
      }
      return reportError(e);
    });
  };

  var compileFile = function (dest, file, reportError) {
    fs.readFile(file, 'utf8', function (err, data) {
      var compiled;
      if (err) {
        grunt.log.error("Could not read " + file);
        return reportError(err);
      } else {
        try {
          compiled = coffee.compile(data);
        } catch (e) {
          grunt.log.error("Could not compile " + file);
          return reportError(e);
        }

        writeJS(dest, file, compiled, reportError);
      }
    });
  };

  var compile = function (files, dest, cb) {
    var fileCount = files.length, successes = 0, i = 0, file;

    if (fileCount < 1) {
      return cb(new Error("No source files found."));
    }

    // Ensure that the destination exists.
    grunt.file.mkdir(dest);

    for (i = 0; i < files.length; i++) {
      file = files[i];
      if (file.match(/\.coffee$/)) {
        compileFile(dest, file, finishedWithFile);
      } else {
        finishedWithFile()
      }
    }

    function finishedWithFile (error) {
      successes += 1;
      if (error || successes >= fileCount) {
        cb(error);
      }
    }
  };
  
  /**
   * Compile a directory of source files to an output directory.
   */
  grunt.registerMultiTask('compile', 'Compile source files to js', function () {
    var opts;
    var log     = grunt.log;
    var done    = this.async();
    var sources = this.filesSrc;
    var dest    = this.data.dest;

    if (sources && dest) {
      compile(sources, dest, function (err) {
        if (err) {
          log.error("Compilation failed: " + (err.stack || err));
          done(false);
        } else {
          log.ok('done: compiled ' + sources.length + ' coffee-script files to ' + dest + '.');
          done(true);
        }
      });
    } else {
      log.error("No source directory specified");
      done(false);
    }
  });
};
