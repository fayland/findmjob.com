'use strict';

module.exports = function(grunt) {
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    bowercopy: {
      options: {
          srcPrefix: 'bower_components',
          destPrefix: 'static'
      },
      fonts: {
          files: {
              'fonts': 'fontawesome/fonts'
          }
      }
    },
    cssmin: {
      combine: {
        options: {
          root: '',
          keepSpecialComments: 0
        },
        files: {
          'static/assets/findmjob.min.css': [
            'bower_components/bootstrap/dist/css/bootstrap.min.css',
            'bower_components/fontawesome/css/font-awesome.min.css',
            'static/assets/src/css/findmjob.css'
          ]
        }
      }
    },
    coffee: {
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
          'bower_components/jquery/jquery.js',
          'bower_components/bootstrap/dist/js/bootstrap.js',
          'bower_components/jquery-timeago/jquery.timeago.js',
          'static/assets/src/js/findmjob.js',
          'static/assets/src/js/ga.js'
        ],
        dest: 'static/assets/findmjob.min.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-bowercopy');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.registerTask('default', ['bowercopy', 'cssmin', 'coffee', 'uglify']);
};