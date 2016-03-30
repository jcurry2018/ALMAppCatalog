module.exports = function(grunt) {
    var rab = require('rally-app-builder');
    var path = require('path');
    var async = require('async');

    function verifyAppManifest(appPath, callback) {
        grunt.log.writeln('Verifying manifest for ' + appPath + '...');
        grunt.util.spawn({
            grunt: true,
            args: ['shell:appmanifest', '--app=' + appPath]
        }, function(err) {
            if (err) {
                callback(err);
            } else {
                var configJsonPath = path.join(appPath, 'config.json');
                var appFiles = grunt.file.readJSON(path.join('temp', appPath, 'appManifest'));
                var configJsonAppFiles = grunt.file.readJSON(configJsonPath).javascript;
                if(appFiles.join(',') !== configJsonAppFiles.join(',')) {
                    grunt.log.error('');
                    grunt.log.error('Required file mismatch detected in ' + configJsonPath + '!');
                    grunt.log.error('\nExpected files:');
                    grunt.log.writeln('[\n    "' + appFiles.join('",\n    "') + '"\n]');
                    grunt.log.error('');
                    grunt.log.error('\nActual files:');
                    grunt.log.writeln('[\n    "' + configJsonAppFiles.join('",\n    "') + '"\n]');
                    grunt.log.error('');
                    grunt.log.error('\n\nFix ' + path.join(appPath, 'config.json') + ' and try again...');
                    callback(appPath + ': Required file mismatch detected!');
                } else {
                    callback();
                }
            }
        });
    }

    function buildApp(appPath, callback) {
        grunt.log.writeln('');
        grunt.log.writeln('Building ' + appPath + '...');
        rab.build({ path: appPath }, function(error) {
            if(error) {
                grunt.log.error(error);
                grunt.fail.warn('Aborting!');
            } else {
                callback();
            }
        });
    }

    function processApp(appPath, callback) {
        verifyAppManifest(appPath, function(err) {
            if(err) {
                grunt.fail.warn('Aborting!');
            } else {
                buildApp(appPath, callback);
            }
        });
    }

    grunt.registerTask('assemble', 'Assemble app sources into customizable html files', function() {
        var done = this.async();
        var options = grunt.config.get('assemble').options;
        var apps = grunt.file.expand(options.apps);
        var app = grunt.option('app');
        if(app) {
            processApp(app, done);
        } else {
            async.eachLimit(apps, 10, function(app, callback) {
                verifyAppManifest(path.dirname(app), callback);
            }, function(err) {
                if(err) {
                    grunt.fail.warn('Aborting!');
                } else {
                    async.eachSeries(apps, function(app, callback) {
                        buildApp(path.dirname(app), callback);
                    }, done);
                }
            });
        }
    });
};
