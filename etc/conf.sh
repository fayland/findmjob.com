#!/bin/bash

ln -s /findmjob.com/etc/nginx.findmjob.com.conf /etc/nginx/sites-enabled/nginx.findmjob.com.conf;
ln -s /findmjob.com/etc/supervise/www/ /service/www;
ln -s /findmjob.com/etc/supervise/api/ /service/api;
ln -s /findmjob.com/etc/supervise/sphinx/ /service/sphinx;
