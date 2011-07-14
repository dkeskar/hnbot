class Comment < ActiveRecord::Base
  belongs_to :avatar
  #belongs_to :parent, :class => "Comment"
  
  def self.add(info={})
    set_data = {}
    added = true
    unless Comment.find_by_cid(info[:cid]).nil?
      # posted at will have larger error drift if we set it all the time. 
      # We set first time and never changed later. 
      [:posted_at, :created_at].each {|k| info.delete(k) }
      added = false
    else
      info[:created_at] = Time.now
    end
    info[:updated_at] = Time.now
    Comment.find_or_create_by_cid(info[:cid]).update_attributes(info) 
    added
  end

  def self.watched_for(pid)
    Comment.where("pid = #{pid} and avatar_id").order('posted_at asc').all
  end

  def actify
    info = {:type => 'comment', :time => self.posted_at.to_s, :uid => self.cid}
    info[:url] = "#{HNBot::BASE_URL}/item?id=#{self.cid}"
    info[:summary] = self.text
    info[:meta] = {:points => self.pntx, :responses => self.nrsp}
    info
  end

  def threadify
    # return info for inclusion in a thread
    info = {:type => 'context', :time => self.posted_at.to_s, :uid => self.cid}
    info[:person] = self.name
    info[:summary] = self.text
    info
  end

end
