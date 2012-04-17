require 'sinatra'
require 'erb'
require "yaml"
require 'pp'

set :public_folder, File.dirname(__FILE__) + '/../static'
set :views, File.dirname(__FILE__) + '/templates'

configure do
  config = YAML::load( File.read(File.dirname(__FILE__) + '/../conf/findmjob.yml') )
  config_local = YAML::load( File.read(File.dirname(__FILE__) + '/../conf/findmjob_local.yml') )
  set :config, config.merge(config_local)
end

before do
  @config = settings.config
end

get '/' do

  erb :index
end
