'use strict';

module.exports = function(grunt) {
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    cssmin: {
      combine: {
        files: {
          'static/assets/css/findmjob.min.css': [
            'static/bootstrap/css/bootstrap.min.css',
            'static/assets/css/font-awesome.min.css',
            'static/assets/css/findmjob.css'
          ]
        }
      }
    },
    coffee: {
      compile: {
        files: {
          'static/js/facebook.js': 'static/js/facebook.coffee'
        }
      },
      compileJoined: {
        options: {
          join: true
        },
        files: {
          'static/js/findmjob.js': 'static/js/coffee/*.coffee'
        }
      }
    },
    uglify: {
      build: {
        src: [
          'static/js/jquery.min.js',
          'static/bootstrap/js/bootstrap.min.js',
          'static/js/jquery.timeago.js',
          'static/js/findmjob.js',
          'static/js/ga.js'
        ],
        dest: 'static/js/findmjob.min.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.registerTask('default', ['cssmin', 'coffee', 'uglify']);
};