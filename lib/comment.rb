class Comment
  include MongoMapper::Document
  
  key :avatar_id, ObjectId
  key :name, String   # denormalized
  #
  # These are ids as used by hacker news
  key :pid, String
  key :cid, String
  key :parent_cid, String       

  key :text, String
  key :pntx, Integer
  key :nrsp, Integer, :default => 0
  key :posted_at, Time
  
  belongs_to :avatar
  belongs_to :parent, :class => "Comment"
  
  TEMPLATE = <<-END
  {{user}} <a href="{{comment}}">commented</a> on 
  <a href="{{link}}">{{title}}</a> within {{interval}}<br/>
  {{text}}<br/>
  {{numrsp}} people responded.
  END
  TEMPLATE.freeze

  def self.add(info={})
    set_data = {}
    # FIXME: posted at will have larger error drift if we set it all the time. 
    # Better if set first time and never changed later. 
    Comment.collection.update({:cid => info[:cid]}, 
      {"$set" => info}, 
      :upsert => true
    )
  end

  def info 
    ret = {:user => self.name, :comment => self.cid, :text => self.text}
    ret[:numrsp] = self.nrsp
    if not (post = Posting.where(:pid => self.pid).first)
      $stderr.puts "Comment: #{cid} couldn't find Posting #{pid}." 
      ret[:interval] = ((Time.now - self.posted_at)/1.hour).round
    else
      ret[:link] = post.link
      ret[:title] = post.title
      ret[:interval] = ((self.posted_at - post.posted_at)/1.minute).round
    end
    ret
  end
end
