module.exports = function (grunt) {
    'use strict';
    var exec = require('child_process').exec
      , COFFEE = 'coffee'
      , COMPILE = ['--compile', '--output']

    grunt.registerHelper('exec', function(opts, done) {
        var command = opts.cmd + ' ' + opts.args.join(' ');
        grunt.verbose.writeln("Running: " + command);
        exec(command, opts.opts, function (code, stdout, stderr) {
            if (!done) {
                return;
            }
            if (code === 0) {
                done(null, stdout, code);
            } else {
                done(code, stderr, code);
            }
        });
    });
    
    grunt.registerMultiTask('compile', 'Compile source files to js', function() {
        var opts
          , log   = grunt.log
          , done  = this.async()
          , src   = this.data.src
          , dest  = this.data.dest

        if (src) {

            if (!dest) {
                dest = src;
            }
            opts = {
              cmd: COFFEE
              , args: COMPILE.concat([dest, src])
            };

            grunt.helper('exec', opts, function(err, fd, code) {
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
