# ALM has trouble deploying wars, unlike Russia
module.exports = (grunt) ->
  serverPort = grunt.option('port') || 8892
  inlinePort = grunt.option('port') || 8893

  path = require 'path'

  grunt.loadNpmTasks 'grunt-rick'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-nexus-artifact'
  grunt.loadNpmTasks 'grunt-regex-check'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.loadNpmTasks 'grunt-express'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-webdriver-jasmine-runner'
  grunt.loadNpmTasks 'grunt-parallel-spec-runner'
  grunt.loadNpmTasks 'grunt-text-replace'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-curl'
  grunt.loadNpmTasks 'grunt-bump'
  grunt.loadNpmTasks 'grunt-npm'

  grunt.loadTasks 'grunt/tasks'

  grunt.registerTask 'default', ['build']
  grunt.registerTask 'sanity', ['check', 'jshint']
  grunt.registerTask 'css', ['less', 'copy:images', 'replace:imagepaths']
  grunt.registerTask 'build', 'Builds the catalog', ['clean:build', 'shell:link-npm-modules', 'coffee', 'sanity', 'css', 'shell:buildapps', 'assemble', 'copy:apphtml']

  grunt.registerTask 'nexus:__createartifact__', 'Internal task to create and publish the nexus artifact', ['version', 'nexus:push:publish', 'clean:target']
  grunt.registerTask 'nexus:deploy', 'Deploys to nexus', ['build', 'nexus:__createartifact__']
  grunt.registerTask 'nexus:verify', 'Fetches the last build and verifies its integrity', ['clean:nexus', 'version', 'nexus:push:verify']

  grunt.registerTask 'npm:publish', 'Publish to our private npm registry', ['bump:patch', 'npm-publish']

  grunt.registerTask 'check', 'Run convention tests on all files', ['regex-check']
  grunt.registerTask 'ci', 'Does a full build, runs tests and deploys to nexus', ['build', 'test:ci', 'nexus:__createartifact__']

  grunt.registerTask 'test:__buildjasmineconf__', 'Internal task to build and alter the jasmine conf', ['jasmine:apps:build', 'replace:jasmine']
  grunt.registerTask 'test:fast', 'Just configs and runs the tests. Does not do any compiling. grunt && grunt watch should be running.', ['test:__buildjasmineconf__', 'express:inline', 'curl-dir:downloadfiles', 'webdriver_jasmine_runner:chrome']
  grunt.registerTask 'test:faster', 'Run jasmine test in parallel', ['express:inline', 'curl-dir:downloadfiles', 'parallel_spec_runner:appsp:chrome']
  grunt.registerTask 'test:faster:firefox', 'Run jasmine test in parallel', ['express:inline', 'curl-dir:downloadfiles', 'parallel_spec_runner:appsp:firefox']

  grunt.registerTask 'test:fast:firefox', 'Just configs and runs the tests in firefox. Does not do any compiling. grunt && grunt watch should be running.', ['test:__buildjasmineconf__', 'express:inline', 'curl-dir:downloadfiles', 'webdriver_jasmine_runner:firefox']
  grunt.registerTask 'test:conf', 'Fetches the deps, compiles coffee and css files, runs jshint and builds the jasmine test config', ['shell:link-npm-modules', 'clean:test', 'coffee', 'css', 'test:__buildjasmineconf__']
  grunt.registerTask 'test:fastconf', 'Just builds the jasmine test config', ['test:__buildjasmineconf__']
  grunt.registerTask 'test', 'Sets up and runs the tests in the default browser. Use --browser=<other> to run in a different browser, and --port=<port> for a different port.', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'webdriver_jasmine_runner:apps']
  grunt.registerTask 'test:chrome', 'Sets up and runs the tests in Chrome', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'webdriver_jasmine_runner:chrome']
  grunt.registerTask 'test:firefox', 'Sets up and runs the tests in Firefox', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'webdriver_jasmine_runner:firefox']
  grunt.registerTask 'test:chrome:faster', 'Sets up and runs the tests in Chrome', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'parallel_spec_runner:appsp:chrome']
  grunt.registerTask 'test:firefox:faster', 'Sets up and runs the tests in Firefox', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'parallel_spec_runner:appsp:firefox']
  grunt.registerTask 'test:server', "Starts a Jasmine server at localhost:#{serverPort}, specify a different port with --port=<port>", ['express:server', 'express-keepalive']
  grunt.registerTask 'test:ci', 'Runs the tests in both firefox and chrome', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'webdriver_jasmine_runner:chrome', 'webdriver_jasmine_runner:firefox']
  grunt.registerTask 'test:ci:faster', 'Runs the tests in both firefox and chrome', ['sanity', 'test:conf', 'express:inline', 'curl-dir:downloadfiles', 'parallel_spec_runner:appsp:chrome', 'parallel_spec_runner:appsp:firefox']
  grunt.registerTask 'nexus:deps', 'place holder until almci is updated', []

  _ = grunt.util._
  spec = (grunt.option('spec') || grunt.option('jsspec') || '*').replace(/(Spec|Test)$/, '')
  debug = grunt.option 'verbose' || false
  version = grunt.option 'version' || 'dev'
  maps = grunt.option 'maps' || false

  appsdk_path = 'lib/sdk'
  ext_path = 'lib/ext/4.2.2'
  served_paths = [path.resolve(__dirname)]
  if process.env.APPSDK_PATH
    appsdk_path = path.join process.env.APPSDK_PATH, 'rui'
    served_paths.unshift path.join(appsdk_path, '../..')

  if spec != '*' and grunt.file.expand("test/**/#{spec}+(Spec|Test).+(js|coffee)").length == 0
    grunt.warn 'The specified spec or jsspec option does not match any test.'

  appFiles = 'src/apps/**/*.js'
  specFiles = 'test/spec/**/*Spec.coffee'
  cssFiles = 'src/apps/**/*.{css,less}'

  seleniumMajorVersion = '2.45'
  seleniumMinorVersion = '0-rally'
#  seleniumUrl = "http://selenium-release.storage.googleapis.com"
#  seleniumVersionUrl = "#{seleniumUrl}/#{seleniumMajorVersion}"
  seleniumUrl = "http://repo-depot.f4tech.com/artifactory/junkyard-local/com/rallydev"
  seleniumVersionUrl = "#{seleniumUrl}/selenium"
  grunt.option('selenium-jar-path',"lib/selenium-server-standalone-#{seleniumMajorVersion}.#{seleniumMinorVersion}.jar")

  senchaCmd = "#{if process.platform is 'darwin' then 'mac' else 'linux'}/sencha"

  specFileArray = [
    "test/gen/**/#{spec}Spec.js"
  ]

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    buildVersion: version

    bump:
      options:
        commitFiles: ['package.json']
        commitMessage: '[ci npm:publish autobump v%VERSION%]',
        push: true
        pushTo: 'origin master'

    'npm-publish':
      options:
        # the CI will be producing version files and what-not. they can be safely ignored.
        abortIfDirty: false

    clean:
      build: ['build/', 'src/apps/**/*.html', 'temp/']
      test: ['test/gen', '_SpecRunner*.html', '.webdriver']
      dependencies: ['lib/', 'bin/sencha/']
      target: ['target/']
      nexus: ['tmp']

    jshint:
      options:
        bitwise: true
        curly: true
        eqeqeq: true
        forin: true
        immed: true
        latedef: true
        noarg: true
        noempty: true
        nonew: true
        trailing: true
        browser: true
        unused: 'vars'
        es3: true
        laxbreak: true
      tasks:
        files:
          src: ['grunt/**/*.js']
      apps:
        files:
          src: ['src/apps/**/*.js']

    "regex-check":
      x4:
        src: [appFiles, specFiles, cssFiles]
        options:
          pattern: /x4-/g
      almglobals:
        src: [appFiles, specFiles]
        options:
          pattern: /Rally\.context|Rally\.getScope|Rally\.alm|Rally\.getContextPath/g
      sandboxing:
        src: [appFiles, specFiles]
        options:
          pattern: /Ext4\./g
      consolelogs:
        src: [appFiles, specFiles]
        options:
          pattern: /console\.log/g
      debugger:
        src: [appFiles, specFiles]
        options:
          pattern: /debugger/g

    express:
      options:
        bases: served_paths
        server: path.resolve(__dirname, 'test', 'server.js')
        debug: debug
      server:
        options:
          port: serverPort
      inline:
        options:
          port: inlinePort

    webdriver_jasmine_runner:
      options:
        seleniumJar: process.env.SELENIUM_JAR_PATH ? grunt.option('selenium-jar-path')
        seleniumServerArgs: ['-Xmx256M']
        testServerPort: inlinePort
      apps: {}
      appsp:
        options:
        #browser: 'phantom'
        #seleniumServerHost: 'localhost'
        #seleniumServerPort: 5445
          testFile: '<%= grunt.task.current.args[0] %>'
      chrome:
        options:
          browser: 'chrome'
      firefox:
        options:
          browser: 'firefox'

    'curl-dir':
      downloadfiles:
        src: (->
          jarName = "selenium-server-standalone-#{seleniumMajorVersion}.#{seleniumMinorVersion}.jar";
          if grunt.file.exists("lib/" + jarName) then [] else ["#{seleniumVersionUrl}/" + jarName]
        )()
        dest: 'lib'

    parallel_spec_runner:
      options:
        browser: "chrome"
        specs: specFileArray,
        # The following specs are excluded because they do not run in isolation in either firefox or chrome,
        # or they are very flaky in one of these browser
        # these need to be fixed then they can be removed from the exclude list
        # test grunt test:fast --spec='YourSpec' --keepalive and
        # refresh the browser many times to ensure the spec passes before removing these
        excludedSpecs: [],
        isolatedSpecs: []
      appsp:
        chrome:
          options:
            browser: "chrome"
        firefox:
          options:
            browser: "firefox"

    jasmine:
      options:
        specs: [
          "test/gen/**/#{spec}Spec.js"
        ]
        helpers: [
          "#{appsdk_path}/test/javascripts/helpers/**/*.js"
        ]
        vendor: (->
          if process.env.APPSDK_PATH?
            vendorPaths = [
              "lib/ext/4.2.2/ext-all-debug.js"
              "#{appsdk_path}/builds/sdk-dependencies.js"
              "#{appsdk_path}/src/Ext-more.js"
            ]
          else
            vendorPaths = ["#{appsdk_path}/builds/sdk.js"]

          vendorPaths.concat [
            "#{appsdk_path}/builds/lib/analytics/analytics-all.js"
            "#{appsdk_path}/builds/lib/closure/closure-all.js"

            # Enable Ext Loader
            'test/support/ExtLoader.js'

            # 3rd party libraries & customizations
            "#{appsdk_path}/test/support/sinon/sinon-1.10.2.js"
            "#{appsdk_path}/test/support/sinon/jasmine-sinon.js"
            "#{appsdk_path}/test/support/sinon/rally-sinon-config.js"
            "node_modules/immutable/dist/immutable.js"

            # Setup
            'lib/webdriver/webdriver.js'
            "#{appsdk_path}/test/support/webdriver/error.js"

            # Asserts
            "#{appsdk_path}/test/support/helpers/asserts/rally-asserts.js"
            "#{appsdk_path}/test/support/helpers/asserts/rally-custom-asserts.js"

            # Mocks and helpers
            "#{appsdk_path}/test/support/helpers/helpers.js"
            "#{appsdk_path}/test/support/helpers/ext4-mocking.js"
            "#{appsdk_path}/test/support/helpers/ext4-sinon.js"
            "#{appsdk_path}/test/javascripts/support/helpers/**/*.js"
            "#{appsdk_path}/test/javascripts/support/mock/**/*.js"
            "#{appsdk_path}/test/support/data/types/**/*.js"

            # 'btid' CSS classes for Testing
            "#{appsdk_path}/browsertest/Test.js"
            "#{appsdk_path}/browsertest/Overrides.js"

            # Jasmine overrides
            "#{appsdk_path}/test/support/jasmine/jasmine-html-overrides.js"

            # Deft overrides
            "#{appsdk_path}/test/support/deft/deft-overrides.js"
          ]
        )()
        styles: [
          "#{appsdk_path}/test/support/jasmine/rally-jasmine.css"
          "#{appsdk_path}/builds/rui/resources/css/rui-all.css"
          "#{appsdk_path}/builds/rui/resources/css/rui-fonts.css"
          "#{appsdk_path}/builds/rui/resources/css/closure-all.css"
          'build/resources/css/catalog-all.css'
        ]
        host: "http://127.0.0.1:#{inlinePort}/"
      apps:  {}
      appsp:
        options:
          specs: '<%= grunt.task.current.args[2] %>'
          outfile: '<%= grunt.task.current.args[1] %>'

    replace:
      jasmine:
        src: ['_SpecRunner*.html']
        overwrite: true
        replacements: [
          from: '<script src=".grunt/grunt-contrib-jasmine/reporter.js"></script>'
          to: '<!--script src=".grunt/grunt-contrib-jasmine/reporter.js"></script> removed because its slow and not used-->'
        ]
      imagepaths:
        src: ['build/resources/css/catalog-all.css']
        overwrite: true
        replacements: [
          from: 'url(\''
          to: 'url(\'../images/'
        ]

    less:
      options:
        yuicompress: true
        modifyVars:
          prefix: 'x4-'
      build:
        files:
          'build/resources/css/catalog-all.css': [cssFiles]

    copy:
      images:
        files: [
          { expand: true, src: ['src/apps/**/*.png', 'src/apps/**/*.gif', 'src/apps/**/*.jpg'], flatten: true, dest: 'build/resources/images/' }
        ]
      apphtml:
        files: [
          { expand: true, src: ['apps/**/deploy/*.html'], cwd: 'src', dest: 'build/html/', rename: (dest, src) -> "#{dest}#{src.replace('deploy/', '').replace('apps/', '')}" }
          { expand: true, src: ['src/legacy/*.html', 'src/legacy/*.mp3'], dest: 'build/html/legacy/', flatten: true }
        ]

    coffee:
      test:
        expand: true
        cwd: 'test/spec'
        src: ['**/*.coffee']
        dest: 'test/gen'
        ext: '.js'
        options:
          sourceMap: maps

    watch:
      test:
        files: 'test/spec/**/*.coffee'
        tasks: ['coffee:test']
        options:
          spawn: false
      apps:
        files: 'src/apps/**/*.js'
        tasks: ['jshint:apps']
        options:
          spawn: false
      legacyApps:
        files: 'src/legacy/**/*'
        tasks: ['copy:apphtml']
      tasks:
        files: 'grunt/tasks/**/*.js'
        tasks: ['jshint:tasks']
        options:
          spawn: false
      styles:
        files: cssFiles
        tasks: ['css']

    nexus:
      options:
        url: 'http://alm-build.f4tech.com:8080'
        repository: 'thirdparty'
      push:
        files: [
          { expand: true, src: ['build/**/*'] }
          { expand: true, src: ['src/apps/**/*'] }
        ]
        options:
          publish: [{ id: 'com.rallydev.js:app-catalog:tgz', version: '<%= buildVersion %>', path: 'target/' }]
          verify: [
            { id: 'com.rallydev.js:app-catalog:tgz', version: '<%= buildVersion %>', path: 'tmp/' }
          ]

    sencha:
      options:
        cmd: "./bin/sencha/#{if process.platform is 'darwin' then 'mac' else 'linux'}/sencha"
      buildapps:
        options:
          args: [
            if debug then '-d' else ''
            "-s #{ext_path}"
            'compile'
            "-classpath=#{appsdk_path}/builds/sdk-dependencies-debug.js,#{appsdk_path}/src,src/apps"
            'exclude -all and'
            'include -file src/apps and'
            'concat build/catalog-all-debug.js and'
            'concat -compress build/catalog-all.js'
          ]
      appmanifest:
        options:
          args:[
            "-s #{ext_path}"
            'compile'
            "-classpath=#{appsdk_path}/builds/sdk-dependencies-debug.js,#{appsdk_path}/src,src/apps"
            'exclude -all and'
            "union -r -file #{grunt.option('app')}/ and"
            "exclude -file #{appsdk_path}/builds/sdk-dependencies-debug.js and"
            "exclude -file #{appsdk_path}/src and"
            'exclude -namespace Ext and'
            "metadata -f -t {0} -o temp/#{grunt.option('app')}/appManifest -json -b #{grunt.option('app')}"
          ]

    assemble:
      options:
        apps: 'src/apps/**/config.json'

    rick:
      'app-catalog':
        url: 'almci/job/app-catalog-jobs'
        job: 'app-catalog'
      alm:
        url: 'almci/job/alm-jobs'
        job: 'alm'

    shell:
      options:
        stdout: true
        stderr: true
        failOnError: true

      'buildapps':
        command: [
          "bin/sencha/#{senchaCmd}"
          if debug then '-d' else ''
          "-s #{ext_path}"
          'compile'
          "-classpath=#{appsdk_path}/builds/sdk-dependencies-debug.js,#{appsdk_path}/src,src/apps"
          'exclude -all and'
          'include -file src/apps and'
          'concat build/catalog-all-debug.js and'
          'concat -compress build/catalog-all.js'
        ].join(" ")

      'appmanifest':
        command:[
          "bin/sencha/#{senchaCmd}"
          "-s #{ext_path}"
          'compile'
          "-classpath=#{appsdk_path}/builds/sdk-dependencies-debug.js,#{appsdk_path}/src,src/apps"
          'exclude -all and'
          "union -r -file #{grunt.option('app')}/ and"
          "exclude -file #{appsdk_path}/builds/sdk-dependencies-debug.js and"
          "exclude -file #{appsdk_path}/src and"
          'exclude -namespace Ext and'
          "metadata -f -t {0} -o temp/#{grunt.option('app')}/appManifest -json -b #{grunt.option('app')}"
        ].join(" ")

      'link-npm-modules':
        options:
          execOptions:
            cwd: '.'
        command: "./npm_link_appcatalog_deps.sh"

  # Only recompile changed coffee files
  changedFiles = {}

  onChange = _.debounce ->
    specFiles = []
    taskFiles = []
    appsFiles = []

    _.each changedFiles, (action, filepath) ->
      specFiles.push(filepath) if _.contains(filepath, 'spec')
      taskFiles.push(filepath) if _.contains(filepath, 'tasks')
      appsFiles.push(filepath) if _.contains(filepath, 'apps')

    grunt.config 'coffee.test.src', _.map specFiles, (path) -> path.replace('test/spec/', '')
    grunt.config 'jshint.tasks.files.src', taskFiles
    grunt.config 'jshint.apps.files.src', appsFiles

    changedFiles = {}
  , 200

  grunt.event.on 'watch', (action, filepath) ->
    changedFiles[filepath] = action
    onChange()
