require 'watchbot'
require 'private_config'

# HNBot lets you track comments made by people you follow via mavenn, 
#
class HNBot < Watchbot
  BASE_URL = 'http://news.ycombinator.com'
  NEW_LNKS = "#{BASE_URL}/newest"
  NEW_CMTS = "#{BASE_URL}/newcomments"
  ITEM_URL_PREFIX = "#{BASE_URL}/item?id="

  # A REP friendly bot honoring `curl news.ycombinator.com/robots.txt`
  # Politeness restricts us to /, /newest, /newcomments and /item with a
  # wait_interval between 30sec to 1min.
  #
  # Daemonized fetch of /newcomments storing Comments and stub Postings
  # Fetches full Postings info less often, say every 10 min.

  def initialize(args)
    first_or_create(:target_url => NEW_CMTS)
  end

  # Fetch newest comments (first page only)
  def fetch_comments
    CommentList.new(NEW_CMTS).crawl
  end

  # Fetch posts on which watchlist avatars have commented. 
	def fetch_postings
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
	end

  # Post latest activity to mavenn via API
  def post_activity
    before = self.last_post
    self.set(:last_post => Time.now)
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

      sleep 2
    end
  end

end


