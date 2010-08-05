require 'rubygems'
require 'sinatra'
require 'spec'
require 'spec/interop/test'
require 'rack/test'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'

# establish in-memory database for testing
MongoMapper.connection = Mongo::Connection.new(ENV["MONGO_HOST"] || 'localhost')
MongoMapper.database = "#{SiteConfig.app}_#{Sinatra::Base.environment}"

Spec::Runner.configure do |config|
  # reset database before each example is run
  config.after(:each) do 
    MongoMapper.database.collections.each do |coll| 
      coll.remove unless c.name.match(/^system\./)
    end
  end 
end
