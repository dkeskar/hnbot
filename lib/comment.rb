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
  <div style="margin: 10px 0; padding: 6px 0;">
  <div style="background-color: #efefef">
  {{user}} on 
  <a href="{{link}}">{{title}}</a> within {{interval}}</div>
  {{text}}
  <div style="text-align:right; font-size:smaller; ">
  {{points}}, <a href="{{comment}}">{{numrsp}} responses</a> 
  </div>
  </div>
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
    ret = {:user => self.name, :text => self.text}
    ret[:comment] = "#{HackerNews::URL}/item?id=#{self.cid}"
    ret[:points] = "#{self.pntx} point#{self.pntx > 1 ? 's' : ''}"
    ret[:numrsp] = self.nrsp
    if not (post = Posting.where(:pid => self.pid).first)
      interval = if self.posted_at
        ((Time.now - self.posted_at)/1.hour).round
      else
        42
      end
      # FIXME: This needs to be refactored into the proper place
      ret[:title] = 'another comment'
      ret[:link] = "#{HackerNews::URL}/item?id=#{self.parent_cid}"
    else
      ret[:link] = post.link
      ret[:link] = "#{HackerNews::URL}/#{post.link}" if post.link !~ /^http/
      ret[:title] = post.title
      interval = if self.posted_at and post.posted_at
        ((self.posted_at - post.posted_at)/1.minute).round
      else
        42
      end
    end
    ret[:interval] = "#{interval} min"
    ret[:template] = self.class.to_s.underscore
    ret
  end
end
