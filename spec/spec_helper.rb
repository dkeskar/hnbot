require 'rubygems'

require 'bundler/setup'

Bundler.require :default, :development

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'

# configure FactoryGirl
FactoryGirl.find_definitions

RSpec.configure do |config|
  # reset db
  [Avatar, Stream, Setting, Posting, Comment].each do |table|
    table.delete_all
  end

  # enable filtering for examples
  config.filter_run :wip => true
  config.run_all_when_everything_filtered = true
end
