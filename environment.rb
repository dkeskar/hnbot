require 'rubygems'
require 'mongo_mapper'
require 'ostruct'

$KCODE = 'u'

default_env = defined?(Sinatra) ? Sinatra::Base.environment : :development
environs = ENV['APP_ENV'] || default_env  

SiteConfig = OpenStruct.new(:title => 'Hacker News Watch', :app => 'watchbots')

case environs.to_sym
when :development
  SiteConfig.url_base = 'http://localhost:4567'
  SiteConfig.mavenn = 'http://localhost:3000'
  SiteConfig.apid = "99f4bf3ea0d737d2f58af6a8afa7a096304dc8c4"
  SiteConfig.token = "ec887807294022d532262f988e94f495"
when :production
  SiteConfig.url_base = 'http://nyx.memamsa.com'
  SiteConfig.mavenn = 'http://mavenn.com'
  SiteConfig.apid = "39a784d1c8c3a5709b86d77cdf96879ec008de42"
  SiteConfig.token = "a1601a55bd017ba111e48aad2f8a068c"
end

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
