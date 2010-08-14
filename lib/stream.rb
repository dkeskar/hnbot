class Stream
  include MongoMapper::Document

  USER = 1; TREND = 2; KEYWORD = 3;

  key :sid, String    # mavenn stream id
  key :config, Hash
  key :_type, String

  def self.activity(sid)
    me = Stream.where(:sid => sid).load
    return [] if not me 
    me.activity 
  end
  
  def activity
    # only support user comment and submission watch currently 
    return [] if self.stype != USER

    avatar = Avatar.where(:name => self.config[:user])
    comments = avatar.comments.sort(:$natural).limit(20).all
    postings = avatar.postings.sort(:$natural).limit(20).all
    
    # interleave later
    feed = []
    
    (comments + postings).each do |item|
      feed << item.info
    end
  end
end
