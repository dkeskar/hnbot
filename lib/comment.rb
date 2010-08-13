class Comment
  include MongoMapper::Document
  
  key :avatar_id, ObjectId
  # These are ids as used by hacker news
  key :pid, String
  key :cid, String
  key :parent_cid, String       

  key :text, String
  key :pntx, Integer
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
end
