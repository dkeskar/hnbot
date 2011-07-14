require 'rubygems'

require 'bundler/setup'

Bundler.require :default, :development

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'

# establish in-memory database for testing
MongoMapper.connection = Mongo::Connection.new(ENV["MONGO_HOST"] || 'localhost')
MongoMapper.database = "#{SiteConfig.app}_#{Sinatra::Base.environment}"

# configure FactoryGirl
FactoryGirl.find_definitions

RSpec.configure do |config|
  # cleanup data in db
  [Avatar, Stream, Setting, Posting].each do |table|
    table.delete_all
  end

  # enable filtering for examples
  config.filter_run :wip => true
  config.run_all_when_everything_filtered = true

  # reset database before each example is run
  #config.after(:each) do 
  #  MongoMapper.database.collections.each do |coll| 
  #    coll.remove unless c.name.match(/^system\./)
  #  end
  #end 
end
