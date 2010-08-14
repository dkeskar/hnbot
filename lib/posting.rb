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
    [:avatar_id, :name, :title, :pntx, :cmtx, :posted_at].each do |attribute|
      set_data[attribute] = info[attribute]
    end
    Posting.collection.update({:link => info[:link]}, 
      {"$set" => set_data}, 
      :upsert => true
    )
  end


  def info
    ret = {}
    [:link, :title, :pntx, :cmtx].each do |attr|
      ret[attr] = self[attr]
    end
    ret[:time] = self.posted_at
    ret 
  end
end
