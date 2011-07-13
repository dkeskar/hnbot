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
    posting = Posting.where(:pid => info[:pid])
    posting = posting.fields(:pid => 1, :posted_at => 1).first
    if posting 
      # posted at will have larger error drift if we set it all the time. 
      # Better if set first time and never changed later. 
      info.delete(:posted_at) if not posting.posted_at.blank?
      added = false
      return added if info.keys.size == 1 
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

  def self.bump(pid) 
    Posting.increment({:pid => pid}, :wacx => 1)
  end

  def objectify 
    # thumb and summary to come soon
    { :url => self.link, :title => self.title,
      :meta => {:person => self.name, :points => self.pntx, :comments => self.cmtx}
    }
  end

  def actify
    { :type => 'submit', :uid => self.pid, :time => self.posted_at.to_s}
  end

  def self.unfetched
    Posting.all(:link => nil, :valid.ne => false)
  end

  # Top posting by watched user activity in last 24 hours
  def self.top
    watched = Avatar.fields(:name => 0).where(:nwx.gt => 0).all 
    watched = watched.map {|x| x.id}
    pids = Comment.collection.group(
      ['pid'], 
      {
        'posted_at' => {'$gte' => Time.now - 2.day}, 
        'avatar_id' => {'$in' => watched}
      },
      {:cmts => 0.0},
      "function(d, p) { p.cmts++ }"
    )
    pids.sort! { |a, b| b['cmts'] <=> a['cmts']}
    query_pids = pids.map {|x| x['pid']}
    query = Posting.where(:valid.ne => false, :pid => {'$in' => query_pids})
    res = query.sort(:updated_at.desc).limit(21).all
    pidmap = {}
    res.each {|posting| pidmap[posting.pid] = posting}

    sorted = []
    pids.each { |pinfo| sorted << [pidmap[pinfo['pid']], pinfo['cmts'].to_i]  }
    sorted
  end

  def invalid!
    self.set(:valid => false)
  end

end
