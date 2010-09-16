class Posting
  include MongoMapper::Document
  
  key :avatar_id, ObjectId
  key :name, String       # denormalized

  key :pid, String                # Posting id used by Hacker News
  key :link, String
  key :title, String
  key :pntx, Integer
  key :cmtx, Integer
  key :posted_at, Time
  key :valid, Boolean, :default => true
  key :wacx, Integer, :default => 0     # watch activity

  # TODO: Excerpt the posting by crawling and parsing the link. 
  key :summary, String    # summary excerpted
  key :thumbs, Array      # img url
  key :pinged, Boolean, :default => false
  
  belongs_to :avatar
  
  class NoSuchItem < StandardError; end 
  class Dead < StandardError; end

  def self.add(info={})
    set_data = {}
    added = true
    if Posting.exists?(:pid => info[:pid])
      # posted at will have larger error drift if we set it all the time. 
      # Better if set first time and never changed later. 
      [:posted_at, :created_at].each {|k| info.delete(k) }
      added = false
    else
      info[:created_at] = Time.now
    end
    info[:updated_at] = Time.now
    Posting.collection.update({:pid => info[:pid]}, 
      {"$set" => info}, 
      :upsert => true
    )
    added
  end

  def objectify 
    # thumb and summary to come soon
    tuple_info
  end

  def actify
    tuple_info.merge(:type => 'submit')
  end

  def tuple_info
    { :url => self.link, :title => self.title, :time => self.posted_at.to_s, 
      :meta => {:person => self.name, :points => self.pntx, :comments => self.cmtx},
      :uid => self.pid
    }
  end

  def self.unfetched
    Posting.all(:link => nil, :valid.ne => false)
  end

  # Top posting by watched user activity in last 24 hours
  def self.top
    Posting.where(:valid.ne => false,
      :updated_at.gte => (Time.now - 24.hours)
    ).sort(:wacx.desc).limit(21).all
  end

  def invalid!
    self.set(:valid => false)
  end

end
