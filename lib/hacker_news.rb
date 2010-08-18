require 'net/http'
require 'hpricot'
require 'watchbot'

class HackerNews < Watchbot
  URL = 'http://news.ycombinator.com'
	CMT_URL = "#{URL}/threads?id="
	SBM_URL = "#{URL}/submitted?id="

  MAX_PAGES = 5
	MAX_USER_PAGES = 1
	attr_accessor :links, :points, :users, :comments, :times, :more
	
	def self.refresh
		$stderr.puts "Begin HN.refresh #{Time.now}"
		bot = HackerNews.first_or_create(:target_url => URL)
		bot.record(:begin)
		bot.crawl_page
    bot.refresh_watchlist
		bot.record(:end)
	rescue => e
		$stderr.puts "#{e.class} #{e.message}", e.backtrace
	ensure
		return bot
	end

	def self.stats
    status = (hn = HackerNews.first) ? hn.refresh_status : "Not refreshed"
		{ 
			:posts => Posting.count, 
			:avatars => Avatar.count,
			:refresh => status
		}
	end

  def refresh_watchlist
    @watched = Avatar.watched
    @watched.each do |user|
      crawl_threads(user)
      sleep 23 + rand*42
    end
  end

  def crawl_threads(avatar, doc=nil)
    # In each refresh period, check only the latest page of comment threads 
    # for each user in the watchlist. 
    $stderr.puts "--- HN: crawl_threads: #{avatar.name}"
    @thread = doc || HackerNews.fetch("#{CMT_URL}#{avatar.name}")
    @thread = Hpricot(@thread)
    
    comments = []
    texts = @thread.search("td.default/span.comment/font")
    hdrs = @thread.search("td.default/div/span.comhead")
    indents = @thread.search("td/img[@src=http://ycombinator.com/images/s.gif]")
    indents = indents.search("[@height=1]")
    lvl_step = 40
    rspfor = []
    uppers = {}
    hdrs.each_with_index do |hdr, ix|
      html = hdr.inner_html
      if cid = html.match(/id=\"score_([^\"]+)\">/)
        cid = cid[1]
      end
      tm = html.match(/\/a>\s+(\d+\s(second|minute|hour|day|month|year)s?\s+ago)\s+\|/)
      tm = time_from_words(tm[1]) if tm and tm.size > 1

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
      if cmtr != avatar.name and !rspfor.empty?
        # increment response count and move on
        Comment.increment({:cid => rspfor.last[:cid]}, :nrsp => 1)
        next
      else
        rspfor.push({:level => lvl, :cid => cid})
      end

      $stderr.puts rspfor.inspect

      comments <<
      Comment.add(:avatar_id => avatar.id, :name => avatar.name,
                  :cid => cid, :pid => pid, :nrsp => 0,
                  :parent_cid => parent, 
                  :text => texts[ix].inner_html,
                  :pntx => points,
                  :posted_at => tm
                 )
    end
    comments
  end
  
	def crawl_page(url=URL, page=1)
		$stderr.puts "=== HN: crawl_page: #{page} ==="
		@page = HackerNews.fetch(url)
		@page = Hpricot(@page)

		update_bot_bio if page == 1
		gather_page_elements
		if process_page_elements and page < MAX_PAGES and @more
			sleep 42 + rand*42
			crawl_page("#{URL}#{@more}", page+1)
    end 
	end

	def update_bot_bio
  	self.name = @page.search("title").inner_html
  	self.icon_url = @page.search("link[@rel*='icon']").first[:href]
  	self.target_rss_url = "#{URL}/rss"
  	self.save
	end
  
  def gather_page_elements  
    @links = @page.search("tr/td.title/a:first-child")
    @points = @page.search("tr/td.subtext/span")
    @users = @page.search("tr/td.subtext/a[@href*='user']")
    @comments = @page.search("tr/td.subtext/a[@href*='item']")
    @times = @page.search("tr/td.subtext")
		@more = @page.search("tr/td.title/a[@href*='/x?fnid']")
		@more = @more.first[:href] if @more
		
		last = @links.pop
		raise "Link structure assumption faulty" if last[:href] != @more
		raise "Mismatched page elements" if @links.size != @points.size
	end

	def process_page_elements(newer_than=10.day)
		raise "No links. Page not parsed?" if @links.blank?

		fresh_links = true
    @links.each_with_index do |link, ix|
      av = Avatar.first_or_create(:name => @users[ix].inner_html)
      pts = @points[ix].inner_html.split(/\s/).first.to_i if @points[ix]
      cmts = @comments[ix].inner_html.split(/s/).first.to_i if @comments[ix]
      pid = @comments[ix][:href].match(/item\?id=(\w+)/)
      pid = pid[1] if pid and pid.size > 1
      lnk = link[:href]
      lnk = "#{HackerNews::URL}/#{lnk}" if lnk !~ /^http/
                                       
			$stderr.puts "P: #{pid} #{link.inner_html}"
			tm = parse_time_from_post(ix)
			if (tm > (Time.now - newer_than))
				Posting.add(:avatar_id => av.id, :name => av.name,
					:link => lnk, :title => link.inner_html,
					:pntx => pts, :cmtx => cmts, :posted_at => tm,
          :pid => pid
				)
			else
				$stderr.puts "Not fresh: #{tm} #{link.inner_html}"
				fresh_links = false
			end
    end
		fresh_links
	end

	def parse_time_from_post(ix)
		tm = @times[ix].inner_html.match(/a\>([^\|]+)\s(\||$)/)
    tm and tm.size > 1 ? time_from_words(tm[1]) : Time.now
	end

end
