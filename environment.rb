require 'rubygems'
require 'mongo_mapper'
require 'haml'
require 'ostruct'

require 'sinatra' unless defined?(Sinatra)

configure do
  SiteConfig = OpenStruct.new(
                 :title => 'Hacker News Watcher',
                 :author => 'Dhananjay Keskar',
                 :app => 'hnbot',
                 :url_base => 'http://localhost:4567/'
               )
  
  # configure MongoDB 
  MongoMapper.connection = Mongo::Connection.new(ENV["MONGO_HOST"] || 'localhost')
  MongoMapper.database = ENV["MONGO_DB"] ||
                        "#{SiteConfig.app}_#{Sinatra::Base.environment}"

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      MongoMapper.connection.connect_to_master if forked
    end
  end
                        
  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
    
end
