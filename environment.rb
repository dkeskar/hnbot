require 'rubygems'
require 'mongo_mapper'
require 'ostruct'

$KCODE = 'u'

SiteConfig = OpenStruct.new(
               :title => 'Hacker News Watch',
               :author => 'Dhananjay Keskar',
               :app => 'watchbots',
               :url_base => 'http://localhost:4567/'
             )

default_env = defined?(Sinatra) ? Sinatra::Base.environment : :development
environs = ENV['APP_ENV'] || default_env  

# configure MongoDB 
MongoMapper.connection = Mongo::Connection.new(ENV["MONGO_HOST"] || 'localhost')
MongoMapper.database = ENV["MONGO_DB"] || "#{SiteConfig.app}_#{environs}" 
# 
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    MongoMapper.connection.connect_to_master if forked
  end
end

# load models 
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
