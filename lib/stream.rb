class Stream
  include MongoMapper::Document
  before_save :update_avatar_settings
  before_destroy :unwatch_avatar

  USER = 1; TREND = 2; KEYWORD = 3;

	AZSET = ("a".."z").to_a + ("A".."Z").to_a + (0..9).to_a
	AZLEN = AZSET.size

  key :sid, String    # mavenn stream id
  key :title, String
  key :config, Hash
  key :_type, String
  key :cache, Hash    # cache config in effect
  key :status, String, :default => "Active"

  def self.activity(sid)
    me = Stream.where(:sid => sid).load
    return [] if not me 
    me.feed 
  end

  def self.preview
    pv = Stream.limit(20).sort(:$natural.desc).all.shuffle.random_element
    pv ? pv.feed : []
  end
  
  # Facebook style feed
  def feed
    avatar = Avatar.where(:name => self.config[:user]).first
    points = self.config[:points] || 1

    comments = avatar.comments.where(:pntx.gte => pts).sort(:posted_at.desc).paginate
    postings = avatar.postings.sort(:posted_at.desc).limit(20).all
    result = []

    while !comments.empty? and !postings.empty do 
      cm = comments.shift
      ps = postings.shift
      item = if cm and ps 
        cm.posted_at > ps.posted_at ? cm : ps 
      else
        cm || ps
      end
      case item
      when Comment; postings.unshift(ps) if ps
      when Posting; comments.unshift(cm) if cm
      end
      result << item.feed_data
    end
    result
  end

  def activity
    # only support user comment and submission watch currently 

    avatar = Avatar.where(:name => self.config[:user]).first
    pts = self.config[:points] || 1

    # Items are already entered in reverse chronological order. 
    # Getting them back in natural order is fine.
    comments = avatar.comments.where(:pntx.gte => pts).sort(:$natural).paginate
    postings = avatar.postings.sort(:$natural).limit(20).all
    
    # interleave later
    feed = []
    
    (comments + postings).each do |item|
      feed << item.info
    end
    feed
  end

  def Stream.interpolate(template, item)
    instr = template
    item.keys.each do |field|
      instr = instr.gsub(/\{\{#{field}\}\}/, item[field].to_s)
    end
    instr
  end

  def self.display(item)
    templ = item[:comment] ? Comment::TEMPLATE : Posting::TEMPLATE
    interpolate(templ, item)
  end

		
	def self.generate_stream_id(len=11)
		(1..len).map {AZSET[rand(AZLEN)]}.join
	end

  def self.invalidate(avatar)
    streams = Stream.all("cache.user" => avatar.name)
    Stream.set({:id => {"$in" => streams.map{|x| x.id}}}, :status => 'Invalid')
    avatar.unwatch(streams.size)
  end

  def update_avatar_settings
    previous = self.cache ? self.cache[:user] :nil
    Avatar.unwatch(previous) if previous
    self.cache[:user] = self.config[:user]
    Avatar.watch(self.cache[:user])
  end

  def unwatch_avatar
    Avatar.unwatch(self.cache[:user])
  end

end
