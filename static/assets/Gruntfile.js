'use strict';

module.exports = function(grunt) {
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    bowercopy: {
      options: {
          srcPrefix: 'bower_components',
          destPrefix: '.'
      },
      fonts: {
          files: {
              'fonts': ['fontawesome/fonts', 'bootstrap/fonts']
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
          'css/findmjob.min.css': [
            'bower_components/bootstrap/dist/css/bootstrap.min.css',
            'bower_components/fontawesome/css/font-awesome.min.css',
            'src/css/findmjob.css'
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
          'src/js/findmjob.js': 'src/js/coffee/*.coffee'
        }
      }
    },
    uglify: {
      build: {
        src: [
          'bower_components/jquery/dist/jquery.js',
          'bower_components/bootstrap/dist/js/bootstrap.js',
          'bower_components/jquery-timeago/jquery.timeago.js',
          'src/js/findmjob.js',
          'src/js/ga.js'
        ],
        dest: 'js/findmjob.min.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-bowercopy');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.registerTask('default', ['bowercopy', 'cssmin', 'coffee', 'uglify']);
};