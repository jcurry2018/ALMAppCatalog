module.exports = function(grunt) {
    grunt.registerMultiTask('sencha', 'Execute sencha cmd with a specified set of arguments', function() {
        var done = this.async(),
            options = this.options(),
            cmd = options.cmd,
            args = options.args;
        if (!args || !args.length) {
            grunt.fail.warn('sencha task needs `args` defined');
        }
        grunt.util.spawn({
            cmd: cmd,
            args: args.join(' ').split(' '),
            opts: {
                stdio: 'inherit'
            }
        }, function(err, stdout, stderr) {
            if (err) {
                grunt.fail.warn(err);
            }
            done();
        });
    });
};

