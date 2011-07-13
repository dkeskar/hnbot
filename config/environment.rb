require 'rubygems'
require 'mongo_mapper'
require 'ostruct'

$KCODE = 'u'

default_env = defined?(Sinatra) ? Sinatra::Base.environment : :development
environs = ENV['APP_ENV'] || default_env  
cur_path = File.dirname(__FILE__)

SiteConfig = OpenStruct.new(:title => 'Hacker News Watch', :app => 'hnbot')

# Load app configuration 
conf = "#{File.dirname(__FILE__)}/app_config.yml" 
app_config = (YAML.load_file(conf) or Hash.new).with_indifferent_access
app_config = app_config[environs] || {}

app_config.keys.each do |key| 
  SiteConfig.new_ostruct_member(key)
  SiteConfig.send("#{key}=", app_config[key])
end

# configure MongoDB 
mongo_host = ENV["MONGO_HOST"] || 'localhost'
mongo_db = ENV["MONGO_DB"] || "#{SiteConfig.app}_#{environs}"

MongoMapper.config = {environs => {
  'host' => mongo_host, 'database' => mongo_db
}}.with_indifferent_access

if environs == :development
  port = Mongo::Connection::DEFAULT_PORT
  opt = {:logger => Logger.new(STDERR)}
else
  port = nil
  opt = {}
end
MongoMapper.connection = Mongo::Connection.new(mongo_host, port, opt)
MongoMapper.database = mongo_db

# connect forked processes to MongoDB
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    MongoMapper.connection.connect_to_master if forked
  end
end

# load models 
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
Dir.glob("#{File.dirname(__FILE__)}/../lib/*.rb") { |lib| require File.basename(lib, '.*') }

