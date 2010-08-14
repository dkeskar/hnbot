class Stream
  include MongoMapper::Document

  USER = 1; TREND = 2; KEYWORD = 3;

	AZSET = ("a".."z").to_a + ("A".."Z").to_a + (0..9).to_a
	AZLEN = AZSET.size

  key :sid, String    # mavenn stream id
  key :title, String
  key :config, Hash
  key :_type, String

  def self.activity(sid)
    me = Stream.where(:sid => sid).load
    return [] if not me 
    me.activity 
  end
  
  def activity
    # only support user comment and submission watch currently 

    avatar = Avatar.where(:name => self.config[:user]).first
    pts = self.config[:points] || 1
    comments = avatar.comments.where(:pntx.gte => pts).sort(:$natural).paginate
    postings = avatar.postings.sort(:$natural).limit(20).all
    
    # interleave later
    feed = []
    
    (comments + postings).each do |item|
      feed << item.info
    end
    feed
  end

  def interpolate(template, item)
    str = template
    item.keys.each do |field|
      str.gsub!(/\{\{#{field}\}\}/, item[field].to_s)
    end
    str
  end

  def display(item)
    $stderr.puts item.inspect
    templ = item[:comment] ? Comment::TEMPLATE : Posting::TEMPLATE
    interpolate(templ, item)
  end

		
	def self.generate_stream_id(len=11)
		(1..len).map {AZSET[rand(AZLEN)]}.join
	end

end
