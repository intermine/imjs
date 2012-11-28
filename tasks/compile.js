/**
 * Compile coffeescript source files.
 */
module.exports = function (grunt) {
    'use strict';

    var fs = require('fs')
      , path = require('path')
      , coffee = require('coffee-script')
    

    var compile = function (src, dest, cb) {
        var files = grunt.file.expandFiles([src])
          , fileCount = files.length
          , successes = 0
          , error = false

        if (fileCount < 1) {
            return cb(new Error("No files matched '" + src + "'"));
        }
        var reportIfDone = function () {
            if (error || successes >= fileCount) {
                cb(error);
            }
        };

        grunt.file.mkdir(dest);

        files.forEach(function (file) {
            if (file.match(/\.coffee$/)) {
                fs.readFile(file, 'utf8', function (err, data) {
                    if (err) {
                        grunt.log.error("Could not read " + file);
                        error = err;
                    } else {
                        var compiled
                        , baseName = path.basename(file, path.extname(file))
                        , newName = path.join(dest, baseName + '.js')
                        try {
                            compiled = coffee.compile(data);
                        } catch (e) {
                            grunt.log.error("Could not compile " + file);
                            error = e;
                            return reportIfDone();
                        }

                        fs.writeFile(newName, compiled, function (err) {
                            if (err) {
                                grunt.log.error("Could not write " + newName);
                                error = err;
                            } else {
                                grunt.verbose.ok("Wrote " + newName);
                                successes++;
                            }
                            reportIfDone();
                        });
                    }
                    reportIfDone();
                });
            } else {
                successes++;
            }
            reportIfDone();
        });
    };
    
    /**
     * Compile a directory of source files to an output directory.
     */
    grunt.registerMultiTask('compile', 'Compile source files to js', function() {
        var opts
          , log   = grunt.log
          , done  = this.async()
          , src   = this.data.src
          , dest  = this.data.dest

        if (src && dest) {

            compile(src, dest, function (err) {
                if (err) {
                    log.error("Compilation failed: " + (err.stack || err));
                    done(false);
                } else {
                    log.ok('done: compiled coffee-script files in ' + src + ' to ' + dest + '.');
                    done(true);
                }
            });

        } else {
            log.error("No source directory specified");
            done(false);
        }
    });
};
