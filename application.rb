require 'rubygems'
require 'sinatra'
require 'haml'

require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

before do 
	params = params.with_indifferent_access if params.is_a?(Hash)
end

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end

helpers do
  # add your helpers here
end

# root page
get '/' do
  haml :root
end

get '/hn' do
  @top10 = Posting.where(
    :posted_at.gte => (Time.now - 10.hours)
  ).sort(:pntx.desc).limit(10).all
  @stats = HackerNews.stats  
  haml :hn  
end

get %r{/hn/watch(/([\w]+))?} do 
	@highlight = params[:captures][1] 
	$stderr.puts "highlight #{@highlight}"
	@watched = Avatar.where(:watch => true).sort(:name.asc).all
	haml :watch
end

post '/hn/watch' do 
	@watch = Avatar.first_or_new(:name => params[:user])
	@watch.watch = true
	@watch.save
	redirect "/hn/watch/#{@watch.id}"
end

post '/hn/streams' do 
  
end

get '/hn/activity' do 
  
end
