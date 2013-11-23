'use strict';

module.exports = function(grunt) {
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    cssmin: {
      combine: {
        options: {
          keepSpecialComments: 0
        },
        files: {
          'static/assets/findmjob.min.css': [
            'static/assets/src/bootstrap/css/bootstrap.css',
            'static/assets/src/font-awesome/css/font-awesome.css',
            'static/assets/src/css/findmjob.css'
          ]
        }
      }
    },
    coffee: {
      compile: {
        files: {
          'static/assets/src/js/facebook.js': 'static/assets/src/js/facebook.coffee'
        }
      },
      compileJoined: {
        options: {
          join: true
        },
        files: {
          'static/assets/src/js/findmjob.js': 'static/assets/src/js/coffee/*.coffee'
        }
      }
    },
    uglify: {
      build: {
        src: [
          'static/assets/src/js/jquery.min.js',
          'static/assets/src/js/jquery.timeago.js',
          'static/assets/src/js/findmjob.js',
          'static/assets/src/js/ga.js'
        ],
        dest: 'static/assets/findmjob.min.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.registerTask('default', ['cssmin', 'coffee', 'uglify']);
};