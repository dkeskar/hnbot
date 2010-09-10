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

  # TODO: Excerpt the posting by crawling and parsing the link. 
  key :summary, String    # summary excerpted
  key :thumbs, Array      # img url
  key :pinged, Boolean, :default => false
  
  belongs_to :avatar

  TEMPLATE = <<-END
  {{user}} submitted <a href="{{link}}><{{title}}</a> {{time}}<br/>
  {{cmtx}} comments, {{pntx} points.
  END
  TEMPLATE.freeze
  
  def self.add(info={})
    set_data = {}
    # posted at will have larger error drift if we set it all the time. 
    # Better if set first time and never changed later. 
    Posting.collection.update({:link => info[:link]}, 
      {"$set" => info}, 
      :upsert => true
    )
  end


  def objectify 
    # thumb and summary to come soon
    { :url => self.link, :title => self.title, :time => self.posted_at.to_s}
  end

  def actify
    { :url => self.link, :title => self.title, 
      :time => self.posted_at.to_s, :type => 'submit'}
  end

  def info
    ret = {}
    [:link, :title, :pntx, :cmtx].each do |attr|
      ret[attr] = self[attr]
    end
    ret[:user] = self.name
    ret[:time] = self.posted_at   # FIXME: relative time please
    ret[:template] = self.class.to_s.underscore
    ret 
  end

  def feed_data
    ret = {:event  => 'submitted'}
    ret[:person] = self.name
    ret[:object] = {
      :link => self.link, :title => self.title,
      :thumb => 'http://ycombinator.com/images/y18.gif',
      :time => self.posted_at
    }
    ret[:stats] = {:points => self.pntx, :comment => self.cmtx}
    ret
  end

end
