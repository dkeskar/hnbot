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
  if format and format == 'json'
    jsonp @streams
  else
    haml :streams
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
    ret = {:success => (!@stream.nil? && !@activity.nil?)}
    ret[:stream_id] = @stream ? @stream.sid : params[:stream_id]
    ret[:id] = @stream.id if @stream
    ret[:activity] = @activity || []
    jsonp ret
  else
    haml :streams
  end
end

	#if (opt = params[:captures]) and opt.is_a?(Array) and opt.size > 2
    #@stream = Stream.where(:sid => opt[1]).first
  #else

post %r{/hners([\.](json|html))?$} do |specified, format|
  # create a stream based on config provided
  @stream = Stream.new(:sid => params[:stream_id])
  @stream.sid ||= Stream.generate_stream_id
  @stream.config = {:user => params[:user], :points => params[:points].to_i}
  @stream.title = params[:title]
  rc = @stream.save
  if rc
    msg = "Stream created and queued for monitoring"
    status = "Created"
  else
    msg = "Failed to create stream." 
    status = "Failed"
  end
  if format and format == 'json' 
    ret = {:success => rc, :status => status, :message => msg}
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
