require 'watchbot'

class HackerNews < Watchbot
  URL = 'http://news.ycombinator.com'
	CMT_URL = "#{URL}/threads?id="
	SBM_URL = "#{URL}/submitted?id="

  MAX_PAGES = 5
	MAX_USER_PAGES = 1
	
	def self.refresh
		$stderr.puts "Begin HN.refresh #{Time.now}"
		bot = HackerNews.first_or_create(:target_url => URL)
		bot.record(:begin)
		bot.refresh_postings
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
    Avatar.watched.each do |user|
      thread = Discussion.new
      thread.base_url = "#{CMT_URL}#{user.name}"
      thread.crawl
    end
  end
  
	def refresh_postings
    list = List.new
    list.base_url = URL
    list.crawl
	end

end
