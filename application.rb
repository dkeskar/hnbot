require 'rubygems'
require 'sinatra'
require 'haml'

require 'environment'

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
end


get '/' do
  @top10 = Posting.where(
    :posted_at.gte => (Time.now - 10.hours)
  ).sort(:pntx.desc).limit(10).all
  @stats = HackerNews.stats  
  haml :hn  
end

get %r{/watch(/([\w]+))?} do 
	if (opt = params[:captures]) and opt.is_a?(Array) and opt.size == 2
		@highlight = opt.last
	end
	$stderr.puts "highlight #{@highlight}"
	@watched = Avatar.where(:nwx.gt => 0).sort(:name.asc).all
	haml :watch
end

post '/watch' do 
	@watch = Avatar.first_or_new(:name => params[:user])
  inc = params[:unwatch] ? -1 : 1
	@watch.increment(:nwx => inc)
	redirect "/hn/watch/#{@watch.id}"
end

get '/hners/new' do 
  # UI for viewing stream types and configuring a new stream instance
  haml :configure
end

get %r{/hners([\.](json|html))?$} do |specified, format|
  @streams = if params[:user]
    Stream.where('config.user' => params[:user]).all
  else
    Stream.paginate(:page => params[:page])
  end
  case format
  when 'json'; jsonp @streams
  else; haml :streams
  end
end

get '/hners/:stream_id.:format' do 
  # get activity for a stream
  if params[:stream_id] == 'default'
    @stream = Stream.new(:title => "HN Users Preview")
    @activity = Stream.preview
  else
    @stream = Stream.where(:sid => params[:stream_id]).first
    not_found and return if not @stream
    @activity = @stream.activity
  end
  case params[:format]
  when :json, 'json'
    ret = {:stream_id => @stream.sid, :id => @stream.id}
    ret[:status] = @stream.status
    ret[:activity] = @activity || []
    jsonp ret
  else
    haml :streams
  end
end

	#if (opt = params[:captures]) and opt.is_a?(Array) and opt.size > 2
    #@stream = Stream.where(:sid => opt[1]).first
  #else

post %r{/tests([\.](json|html))?$} do |specified, format|
  ret = {:ok => true, :params => params}
  jsonp ret
end

post %r{/hners([\.](json|html))?$} do |specified, format|
  # create a stream based on config provided
  @stream = Stream.new(:sid => params[:stream_id], :status => 'Created')
  @stream.sid ||= Stream.generate_stream_id
  @stream.config = {:user => params[:user], :points => params[:points].to_i}
  @stream.title = params[:title]
  
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
    if rc
      redirect "/hners/#{@stream.sid}.html"
    else 
      haml :configure
    end
  end
end

# update config parameters for an existing stream
put '/hners/:sid' do 
  "put #{params[:sid]}"
end

delete '/hners/:sid' do 
  "delete #{params[:sid]}"
end
