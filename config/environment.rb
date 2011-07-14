$KCODE = 'u'

require 'ostruct'

default_env = defined?(Sinatra) ? Sinatra::Base.environment : :development
environs = ENV['APP_ENV'] || default_env  
cur_path = File.dirname(__FILE__)

SiteConfig = OpenStruct.new(:title => 'Hacker News Watch', :app => 'hnbot')

# Load app configuration 
conf = "#{File.dirname(__FILE__)}/app_config.yml" 
app_config = YAML.load_file(conf) || Hash.new
app_config = app_config[environs] || {}

app_config.keys.each do |key| 
  SiteConfig.new_ostruct_member(key)
  SiteConfig.send("#{key}=", app_config[key])
end

# establish connection with db
dbconfig = YAML::load(File.open('config/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig[environs.to_s])
ActiveRecord::Migrator.up('db/migrate') 

# load models 
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
Dir.glob("#{File.dirname(__FILE__)}/../lib/*.rb") { |lib| require File.basename(lib, '.*') }

