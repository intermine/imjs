module.exports = function (grunt) {
    'use strict';

    var fs = require('fs')
      , _    = require('underscore')._

    function writeIndex (conf, html, done) {
        fs.writeFile(conf.dest, html, function (err) {
            if (err) {
                grunt.log.error("Could not write the compiled template: " + (err.stack || err));
                done(false);
            } else {
                grunt.log.ok("Wrote QUnit index file to " + conf.dest);
                done(true);
            }
        });
    }

    function readTemplate (conf, done) {
        fs.readFile(conf.template, 'utf8', function(err, data) {
            var compiled
              , files = conf.testFiles
            
            if (err) {
                grunt.log.error('Could not read template file: ' + (err.stack || err));
                done(false);
            } else {
                if (conf.unified) {
                    compiled = grunt.template.process(data, conf);
                    writeIndex(conf, compiled, done);
                } else {
                    _.each(files, function (tf, idx) {
                        var ctx = _.defaults({}, {testFiles: [tf]}, conf)
                          , compiled = grunt.template.process(data, ctx)
                          , file = _.last(tf.split('/'))
                          , dest = grunt.template.process(conf.dest, {idx: idx, file: file});
                        grunt.verbose.writeln("Writing to " + dest);
                        return grunt.file.write(dest, compiled);
                    });
                    grunt.log.ok("Wrote " + files.length + " files");
                    done(true);
                }
            }
        });
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

        readTemplate(conf, done);
        
    });
};
