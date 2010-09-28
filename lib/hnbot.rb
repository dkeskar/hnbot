
# HNBot lets you track comments made by people you follow via mavenn, 
#
class HNBot 
  BASE_URL = 'http://news.ycombinator.com'
  NEW_LNKS = "#{BASE_URL}/newest"
  NEW_CMTS = "#{BASE_URL}/newcomments"
  ITEM_URL_PREFIX = "#{BASE_URL}/item?id="

  # A REP friendly bot honoring `curl news.ycombinator.com/robots.txt`
  # Politeness restricts us to /, /newest, /newcomments and /item with a
  # wait_interval between 30sec to 1min.
  #
  # Fetch of /newcomments storing Comments and stub Postings
  # Fetches full Postings for stub postings
  # Posts activity to mavenn

	def self.stats
		{ 
			:posts => Posting.count, 
			:avatars => Avatar.count,
      :watched => Avatar.watched(:count),
		}
	end

  # Fetch newest comments (first page only)
  def self.fetch_comments
    last_fetch = Setting.getval(:method) || Time.now - 1.day
    sleep 42*rand                     # create some variability
    Setting.setval(:method, Time.now)
    CommentList.new(NEW_CMTS).crawl   # only gets one page
  end

  # Fetch posts on which watchlist avatars have commented. 
	def self.fetch_postings
    last_fetch = Setting.getval(:method) || Time.now - 1.day
    fetching = Setting.getval(:fetch_postings_underway)
    return false if fetching

    Setting.setval(:fetch_postings_underway, true)
    Setting.setval(:method, Time.now)
    sleep 42*rand

    link = Link.new(BASE_URL)
    Posting.unfetched.each do |posting|
      begin
        next if not posting.valid
        link.item = posting
        link.crawl
      rescue Posting::NoSuchItem, Posting::Dead
        # soldier on 
      end
    end
    tm = (Time.now - tm)/1.minute
    Setting.setval("fetch_postings_minutes", tm)
    Setting.setval(:fetch_postings_underway, false)
	end

  # Post latest activity to mavenn via API
  def self.post_activity
    before = Setting.getval(:method) || Time.now - 1.day
    Setting.setval(:method, Time.now)

    Stream.all.each do |stream|
      activity = stream.tuples(:since => before)
      json = activity.to_json

      uri = "#{SiteConfig.mavenn}/2010-10-17/streams/#{stream.sid}/activity"
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)

      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(:activity => activity)

      req.basic_auth(SiteConfig.apid, SiteConfig.token)
      rsp = http.request(req)

      sleep 30
    end
  end

end


