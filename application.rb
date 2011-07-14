require 'rubygems'
require 'bundler/setup'

Bundler.require :default

require 'config/environment'

configure(:development) do |c|
  require 'sinatra/reloader'
  c.also_reload('lib/*.rb')
end

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

before do 
  merge_json_data_into_params
	params = params.with_indifferent_access if params.is_a?(Hash)
  verify_mavenn_request
end

error do
  e = request.env['sinatra.error']
  Kernel.puts "Parameters: #{params.inspect}"
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end

helpers do
  # add your helpers here
  def request_headers
    #env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
    env.inject({}){|acc, (k,v)| acc[k] = v; acc}
  end

  def merge_json_data_into_params
    if request.content_type == 'application/json' and (request.post? or request.put?)
      json_data = JSON::parse(request.body.string)
      json_data.keys.each {|k| params[k] = json_data[k] }
    end
  end

  def verify_mavenn_request
    params[:mavenn] = (env['HTTP_X_MAVENN_SIGNATURE'] == 'mavenn')
  end
end

# Site Root - Top postings commented by tracked users
get '/' do
  @top = Posting.top
  @stats = HNBot.stats  
  haml :hn  
end

# Comments by watched users for a given posting
get '/watch/activity/:pid' do 
  @posting = Posting.first(:pid => params[:pid])
  @comments = Comment.watched_for(params[:pid])
  haml :comments
end

get %r{/watch(/([\w]+))?} do 
	if (opt = params[:captures]) and opt.is_a?(Array) and opt.size == 2
		@highlight = opt.last
	end
	$stderr.puts "highlight #{@highlight}"
	@watched = Avatar.where(:nwx.gt => 0).sort(:name.asc).all
	haml :watch
end

# Site interface to start watching some user
post '/watch' do 
	@watch = Avatar.first_or_new(:name => params[:user])
  inc = params[:unwatch] ? -1 : 1
	@watch.increment(:nwx => inc)
	redirect "/hn/watch/#{@watch.id}"
end

####################################################################
# 
# Stream API 
# 
# UI for viewing stream types and configuring a new stream instance
get '/hners/new' do 
  haml :configure
end

# List streams, possibly filtered by user
get %r{/hners([\.](json|html))?$} do |specified, format|
  criteria = params[:user] ? {'config.user' => params[:user]} : {}
  @streams = Stream.all(criteria)
  case format
  when 'json'; jsonp @streams
  else; haml :streams
  end
end

# Activity for a specific stream
get '/hners/:stream_id.:format' do 
  # get activity for a stream
  if params[:stream_id] == 'default' or params[:stream_id] == 'preview'
    @stream = Stream.new(:title => "HN Users Preview")
    @activity = Stream.preview
  else
    @stream = Stream.first(:sid => params[:stream_id])
    not_found and return if not @stream
    @activity = @stream.tuples
    if !@activity.blank? && @stream.status != 'Active'
      @stream.status = 'Active'
      @stream.save
    end
  end
  case params[:format]
  when :json, 'json'
    ret = {:stream_id => @stream.sid, :id => @stream.id}
    ret[:status] = @stream.status
    ret[:activity] = @activity || []
    jsonp ret
  else
    haml :activity
  end
end

# Test Only -- Parameter/Header/Body/Content 
post %r{/tests([\.](json|html))?$} do |specified, format|
  STDERR.puts "Parameters: #{params.inspect}"
  STDERR.puts "Body: #{request.body.string}"
  STDERR.puts "Headers: #{request_headers.inspect}"
  STDERR.puts "Content-type: #{request.content_type}"
  ret = {:ok => true, :params => params}
  jsonp ret
end

# Create a new stream
# FIXME: Authenticate that the request came from mavenn
post %r{/hners([\.](json|html))?$} do |specified, format|
  # create a stream based on config provided
  @stream = Stream.new(:sid => params[:stream_id], :status => 'Created')
  @stream.sid ||= Stream.generate_stream_id
  @stream.config = {:user => params[:user], :points => params[:points].to_i}
  @stream.title = params[:title]
  @stream.mavenn = params[:mavenn] || false
  
  msg = "Stream created and queued for monitoring"
  if not @stream.save
    msg = "Failed to create stream." 
    @stream.status = "Failed"
  end
  if format and format == 'json' 
    ret = {:status => @stream.status, :message => msg}
    ret[:id] = @stream.id
    ret[:stream_id] = @stream.sid
    jsonp ret
  else
    if @stream.status == 'Failed'
      haml :configure
    else 
      redirect "/hners/#{@stream.sid}.html"
    end
  end
end

# Update config parameters for an existing stream
# FIXME: Authenticate that the request came from mavenn
put '/hners/:sid' do 
  "put #{params[:sid]}"
end

# Delete a previously created stream if it exists
# FIXME: Authenticate that the request came from mavenn
delete '/hners/:sid.:format' do
  @stream = Stream.first(:sid => params[:sid])
  res = @stream ? "OK" : "Failed"
  case params[:format] 
  when 'html'
    body "DELETE #{res} #{params[:sid]}"
  when 'json'
    ret = {:success => !@stream.nil?, :stream_id => params[:sid]}
    rsp = jsonp(ret)
  end
  error 422, rsp if not @stream 
  @stream.destroy
end
