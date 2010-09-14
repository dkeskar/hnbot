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
    bot.refresh_watchlist
		bot.fetch_postings
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
      :watched => Avatar.num_watch,
			:refresh => status
		}
	end

  def refresh_watchlist
    thread = Discussion.new(CMT_URL)
    submit = List.new(SBM_URL)
    Avatar.watched.each do |user|
      begin
        next if not user.valid 
        thread.user = user
        thread.crawl

        submit.user = user
        submit.crawl
      rescue Avatar::NoSuchUser
        Stream.invalidate(user)
      end
    end
  end
  
  # Fetch posts on which watchlist avatars have commented. 
	def fetch_postings
    link = Link.new(URL)
    Posting.unfetched.each do |posting|
      begin
        next if not posting.valid
        link.item = posting
        link.crawl
      rescue Posting::NoSuchItem, Posting::Dead
        # soldier on 
      end
    end
	end

end
