require 'rubygems'
require 'sinatra'
require 'haml'

require 'environment'

configure(:development) do |c|
  require 'sinatra/reloader'
end

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
	if (opt = params[:captures]) and opt.is_a?(Array) and opt.size == 2
		@highlight = opt.last
	end
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

get '/configure' do 
  # UI for viewing stream types and configuring a new stream instance
  haml :configure
end

get '/streams' do 
  # get activity for a stream
end

post '/streams' do 
  # create a stream based on config provided
end

get '/activity/:stream_id' do 
  
end
