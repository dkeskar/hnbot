require 'net/http'
require 'hpricot'
require 'watchbot'

class HackerNews < Watchbot
  URL = 'http://news.ycombinator.com'
  MAX_PAGES = 7
	attr_accessor :links, :points, :users, :comments, :times, :more
	
	def self.refresh
		@bot = HackerNews.first_or_create(:target_url => URL)
		@bot.record(:begin)
		@bot.crawl_page
		@bot.record(:end)
	rescue => e
		$stderr.puts "#{e.class} #{e.message}", e.backtrace
	ensure
		return @bot
	end

	def self.stats
		{ 
			:posts => Posting.count, 
			:avatars => Avatar.count,
			:refresh => HackerNews.first.refresh_status
		}
	end

	def crawl_page(url=URL, page=1)
		$stderr.puts "=== HN: crawl_page: #{page} ==="
		@doc = HackerNews.fetch(url)
		@doc = Hpricot(@doc)

		update_bot_bio
		gather_page_elements
		if process_page_elements and page < MAX_PAGES and @more
			sleep 42 + rand*42
			crawl_page("#{URL}#{@more}", page+1)
    end 
	end

	def update_bot_bio
  	self.name = @doc.search("title").inner_html
  	self.icon_url = @doc.search("link[@rel*='icon']").first[:href]
  	self.target_rss_url = "#{URL}/rss"
  	self.save
	end
  
  def gather_page_elements  
    @links = @doc.search("tr/td.title/a")
    @points = @doc.search("tr/td.subtext/span")
    @users = @doc.search("tr/td.subtext/a[@href*='user']")
    @comments = @doc.search("tr/td.subtext/a[@href*='item']")
    @times = @doc.search("tr/td.subtext")
		@more = @doc.search("tr/td.title/a[@href*='/x?fnid']")
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
			$stderr.puts "Posting: #{link.inner_html}"
			tm = parse_time_from_post(ix)
			if (tm > (Time.now - newer_than))
				Posting.add(:avatar_id => av.id, 
					:link => link[:href], :title => link.inner_html,
					:pntx => pts, :cmtx => cmts, :posted_at => tm
				)
			else
				$stderr.puts "Not fresh: #{tm} #{link.inner_html}"
				fresh_links = false
			end
    end
		fresh_links
	end

	def parse_time_from_post(ix)
		if tm = @times[ix].inner_html.match(/a\>([^\|]+)\s(\||$)/)
			tm = tm[1].strip.split(/\s/)
			period = case tm[1]
			when "hour", "hours"; :hour
			when "day", "days"; :day
			when "minute", "minutes"; :minute
			when "month", "months"; :month
			when "year", "years"; :year
			end
			tm = Time.now - (tm.first.to_i).send(period)
		end
		tm
	end
end
