require 'sinatra'
require 'erb'
require "yaml"
require 'pp'

set :public_folder, File.dirname(__FILE__) + '/../static'
set :views, File.dirname(__FILE__) + '/templates'

configure do
  set :config, YAML::load( File.read(File.dirname(__FILE__) + '/../conf/findmjob.yml') )
end

get '/' do
  @config = settings.config
  erb :index
end
