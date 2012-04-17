require 'sinatra'
require 'erb'
require "yaml"
require 'dbi'
require 'pp'

set :public_folder, File.dirname(__FILE__) + '/../static'
set :views, File.dirname(__FILE__) + '/templates'

configure do
  # config
  config = YAML::load( File.read(File.dirname(__FILE__) + '/../conf/findmjob.yml') )
  config_local = YAML::load( File.read(File.dirname(__FILE__) + '/../conf/findmjob_local.yml') )
  config = config.merge(config_local)
  set :config, config

  # dbh
  # Ruby use Mysql while Perl use mysql (mysql_enable_utf8=1 is not supported)
  dns = config['DBI'][0]
  dns = dns.gsub(/mysql/, 'Mysql').gsub /:Mysql_enable_utf8=1/, ''
  dbh = DBI.connect( dns, config['DBI'][1], config['DBI'][2] )
  set :dbh, dbh
  set :dbh_log, dbh
end

before do
  @config = settings.config
  @dbh    = settings.dbh
  @dbh_log = settings.dbh_log
end

get '/' do
  erb :index
end

get '/stats' do

  daysago = Time.now.to_i - 17 * 86400
  @sth = @dbh_log.prepare("select DATE(FROM_UNIXTIME(time)) d, COUNT(*) as cnt from `findmjob_log`.sharebot WHERE time > #{daysago} group by d ORDER by d DESC")
  @sth.execute

  erb :stats
end
