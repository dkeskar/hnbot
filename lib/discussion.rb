
# logic for parsing and making sense of news.yc/thread
class Discussion < Crawler
  attr_accessor :hdrs

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

    count = 0
    texts = @doc.search("td.default/span.comment/font")
    @hdrs = @doc.search("td.default/div/span.comhead")
    indents = @doc.search("td/img[@src=http://ycombinator.com/images/s.gif]")
    indents = indents.search("[@height=1]")
    lvl_step = 40
    rspfor = []
    uppers = {}
    @hdrs.each_with_index do |hdr, ix|
      html = hdr.inner_html
      if cid = html.match(/id=\"score_([^\"]+)\">/)
        cid = cid[1]
      end
      tm = html.match(/\/a>\s+(\d+\s(second|minute|hour|day|month|year)s?\s+ago)\s+\|/)
      tm = Crawler.time_from_words(tm[1]) if tm and tm.size > 1

      pid = html.match(/<a\s+href=\".*=([^"]+)\">parent<\/a>/)
      parent = pid[1] if pid and pid.size > 1

      pid = html.match(/on\:\s+<a href=\".*id=([^"]+)\">/)
      pid = pid[1] if pid and pid.size > 1

      points = html.match(/span id=\"score.*>(\d+)\s+point(s)?</)
      points = points[1].to_i if points and points.size > 1

      cmtr = html.match(/by\s+<a[^>]+>(\w+)<\/a>/)
      cmtr = cmtr[1] if cmtr and cmtr.size > 1

      lvl = indents[ix][:width].to_i
      uppers[lvl] = cid

      # note comments which are in response to comments
      parent = uppers[lvl - lvl_step] if lvl > 0 or parent.blank?  

      $stderr.puts "L: #{lvl} by: #{cmtr} cid: #{cid}"
      rspfor.pop if !rspfor.empty? and rspfor.last[:level] >= lvl

      if cmtr != @avatar.name and !rspfor.empty?
        # increment response count and move on
        Comment.increment({:cid => rspfor.last[:cid]}, :nrsp => 1)
        next
      else
        rspfor.push({:level => lvl, :cid => cid})
      end

      text = texts[ix].inner_html

      $stderr.puts "C: #{cid} #{text.slice(0..60)}"
      $stderr.puts rspfor.inspect

      Comment.add(:avatar_id => @avatar.id, :name => @avatar.name,
                  :cid => cid, :pid => pid, :nrsp => 0,
                  :parent_cid => parent, 
                  :text => text,
                  :pntx => points,
                  :posted_at => tm
                 )
      count += 1
    end
    count
  end

  def url_next
    # check only the latest page of comment threads 
    nil
  end
end

