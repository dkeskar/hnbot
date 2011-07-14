__DIR__ = File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'rake'

require "#{__DIR__}/tasks/testing"

task :environment do
  require 'config/environment'
end

Dir.glob("#{__DIR__}/tasks/*.rake").each { |rake_file| import rake_file }
