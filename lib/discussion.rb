require 'crawler'
# logic for parsing and making sense of news.yc/thread
class Discussion < Crawler

  def initialize(cmt_url)
    @cmt_url = cmt_url
    super
  end

  def user=(avatar)
    raise "Expect Avatar" if not avatar.is_a?(Avatar)
    @avatar = avatar
    @base_url = "#{@cmt_url}#{@avatar.name}"
  end

  def process_page
    raise ArgumentError, "Missing document to process" if not @doc
    raise ArgumentError, "Expect Hpricot::Doc" if not @doc.is_a?(Hpricot::Doc)

    lvl_step = 40
    lvl_spacer = 'http://ycombinator.com/images/s.gif'
    count = 0
    rspfor = []
    tracked_pid = nil
    uppers = {}

    entries = @doc.search("td.default")
    if entries.empty? and @doc.inner_html =~ /no such user/i
      @avatar.invalid!
      raise Avatar::NoSuchUser
    end
    entries.each_with_index do |cmt, ix| 
      text = cmt.search("span.comment/font").inner_html
      info = cmt.search("div/span.comhead")
      html = info.inner_html

      if cid = html.match(/id=\"score_([^\"]+)\">/)
        cid = cid[1]
      end
      tm = html.match(/\/a>\s+(\d+\s(second|minute|hour|day|month|year)s?\s+ago)\s+\|/)
      tm = Crawler.time_from_words(tm[1]) if tm and tm.size > 1

      # beware - threaded comments displayed without parent link.
      # which is why we maintain tracked_pid 
      parent = html.match(/<a\s+href=\".*=([^"]+)\">parent<\/a>/)
      parent = parent[1] if parent and parent.size > 1

      pid = html.match(/on\:\s+<a href=\".*id=([^"]+)\">/)
      if pid and pid.size > 1
        tracked_pid = pid = pid[1] 
      else
        pid = tracked_pid
      end

      points = html.match(/span id=\"score.*>(\d+)\s+point(s)?</)
      points = points[1].to_i if points and points.size > 1

      cmtr = html.match(/by\s+<a[^>]+>(\w+)<\/a>/)
      cmtr = cmtr[1] if cmtr and cmtr.size > 1

      # thread levels
      if indent = cmt.parent.at("td/img")
        lvl = indent[:width]
      end
      lvl = lvl.to_i
      uppers[lvl] = cid
    
      # note comments which are in response to comments
      parent = uppers[lvl - lvl_step] if lvl > 0 or parent.blank?  

      $stderr.puts "L: #{lvl} by: #{cmtr} cid: #{cid} pid: #{pid}"
      rspfor.pop while !rspfor.empty? and rspfor.last[:level] >= lvl

      $stderr.puts "C: #{cid} #{text.slice(0..60)}..."

      avid = (cmtr == @avatar.name) ? @avatar.id : nil 

      # Add the comment 
      count += 1
      newcmt = Comment.add(:avatar_id => avid, :name => cmtr,
                  :cid => cid, :pid => pid, :nrsp => 0,
                  :parent_cid => parent, 
                  :text => text,
                  :pntx => points,
                  :posted_at => tm
                 )
      if newcmt and avid 
        # Track watched users' comment activity for posting 
        Posting.add(:pid => pid, :updated_at => Time.now)
        Posting.increment({:pid => pid}, :wacx => 1)    # relative
      end

      # Track response threads
      if not rspfor.empty?
        context = rspfor.last[:cid]
        # track response and increment count for parent
        Comment.increment({:cid => context}, :nrsp => 1)
        response = { 
          :name => cmtr, 
          :posted_at => tm, 
          :cid => cid, 
          :text => text,
          :pntx => points
        }
        Comment.addToSet(context, :responses, response)
        # To get an accurate context, we need to crawl up the 
        # parent link until we reach the article item or a top-level 
        # comment. 
        Comment.addToSet(cid, :contexts, context)
      end

      rspfor.push({:level => lvl, :cid => cid})
      $stderr.puts rspfor.inspect
    end
    # since we only fetch one page at a time, wait here
    sleep wait_interval
    count
  end

  def url_next
    # check only the latest page of comment threads 
    nil
  end
end

