class Comment
  include MongoMapper::Document
  
  key :avatar_id, ObjectId
  key :name, String   # denormalized
  #
  # These are ids as used by hacker news
  key :pid, String
  key :cid, String
  key :parent_cid, String       

  # maintain thread contexts within this document
  key :contexts, Array
  key :responses, Array 

  key :text, String
  key :pntx, Integer
  key :nrsp, Integer, :default => 0
  key :posted_at, Time
  
  belongs_to :avatar
  belongs_to :parent, :class => "Comment"
  
  def self.add(info={})
    set_data = {}
    # FIXME: posted at will have larger error drift if we set it all the time. 
    # Better if set first time and never changed later. 
    Comment.collection.update({:cid => info[:cid]}, 
      {"$set" => info}, 
      :upsert => true
    )
  end

  def self.addToSet(cid, setname, element)
    Comment.collection.update(
      {:cid => cid, setname => {"$ne" => element}}, 
      {"$push" => {setname => element}}
    )
  end

  def actify
    info = {:type => 'comment', :time => self.posted_at.to_s, :uid => self.cid}
    info[:url] = "#{HackerNews::URL}/item?id=#{self.cid}"
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
