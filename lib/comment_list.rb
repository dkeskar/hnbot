require 'crawler'

# parse and process news.yc comments 
class CommentList < Crawler
  class Empty < StandardError; def message; "No Comments"; end; end 

  def initialize(url)
    @base_url = url
    super
  end

  def url_next
    # no more than the first page, since /x? is disallowed by robots.txt
    nil
  end

  def process_page
    raise ArgumentError, "Missing document to process" if not @doc
    raise ArgumentError, "Expect Hpricot::Doc" if not @doc.is_a?(Hpricot::Doc)

    count = 0
    entries = @doc.search("td.default") or raise CommentList::Empty
    entries.each_with_index do |cmt, ix| 
      text = cmt.search("span.comment/font").inner_html
      info = cmt.search("div/span.comhead")
      html = info.inner_html

      if cid = html.match(/id=\"score_([^\"]+)\">/)
        cid = cid[1]
      end
      tm = html.match(/\/a>\s+(\d+\s(second|minute|hour|day|month|year)s?\s+ago)\s+\|/)
      tm = Crawler.time_from_words(tm[1]) if tm and tm.size > 1

      parent = html.match(/<a\s+href=\".*=([^"]+)\">parent<\/a>/)
      parent = parent[1] if parent and parent.size > 1

      pid = html.match(/on\:\s+<a href=\".*id=([^"]+)\">/)
      if pid and pid.size > 1
        pid = pid[1] 
      end

      points = html.match(/span id=\"score.*>(\d+)\s+point(s)?</)
      points = points[1].to_i if points and points.size > 1

      cmtr = html.match(/by\s+<a[^>]+>(\w+)<\/a>/)
      cmtr = cmtr[1] if cmtr and cmtr.size > 1

      $stderr.puts "C: #{cid} #{text.slice(0..42)}... #{cmtr} #{pid}"

      avatar = Avatar.first_or_create(:name => cmtr)
      # Add the comment 
      newcmt = Comment.add(:avatar_id => avatar.id, :name => cmtr,
                  :cid => cid, :pid => pid, :nrsp => 0,
                  :parent_cid => parent, 
                  :text => text,
                  :pntx => points,
                  :posted_at => tm
                 )
      if newcmt 
        Posting.add(:pid => pid)    # to be fetched for details
        count += 1 
      end
    end
    # since we only fetch one page at a time, don't wait 
    count
  end

end

