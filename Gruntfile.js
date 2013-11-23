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
	}
  });

  grunt.loadNpmTasks('grunt-contrib-cssmin');

  grunt.registerTask('default', ['cssmin']);
};