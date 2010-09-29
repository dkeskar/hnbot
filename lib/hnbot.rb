
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
    Setting.setval(:method, (tm = Time.now))
    STDERR.puts("fetch_comments: begin #{tm}")
    sleep 42*rand                     # create some variability
    CommentList.new(NEW_CMTS).crawl   # only gets one page
  end

  # Fetch posts on which watchlist avatars have commented. 
	def self.fetch_postings
    count = 0
    last_fetch = Setting.getval(:method) || Time.now - 1.day
    if fetching = Setting.getval(:fetch_postings_underway)
      STDERR.puts("fetch_posting: underway") 
      return false 
    end

    Setting.setval(:method, (tm = Time.now))
    STDERR.puts("fetch_postings: begin: #{tm}")
    sleep 10*rand

    link = Link.new(BASE_URL)
    Posting.unfetched.each do |posting|
      begin
        Setting.setval(:fetch_postings_underway, true)
        next if not posting.valid
        link.item = posting
        link.crawl
        count += 1
      rescue Posting::NoSuchItem, Posting::Dead
        # soldier on 
      end
    end
    tm = ((Time.now - tm)/1.second).ceil
  ensure 
    Setting.setval("fetch_postings_seconds", tm)
    Setting.setval(:fetch_postings_underway, false)
    STDERR.puts("fetch_postings: did #{count} in #{tm || 0} sec")
	end

  # Post latest activity to mavenn via API
  def self.post_activity
    STDERR.puts "post_activity: begin" 
    before = Setting.getval(:method) || Time.now - 1.day
    Setting.setval(:method, Time.now)

    items = reqs = 0
    mark_for_deletion = []
    Stream.where(:mavenn.ne => false).all.each do |stream|
      activity = stream.tuples(:since => before)
      json = {:activity => activity}.to_json

      uri = "#{SiteConfig.mavenn}/2010-10-17/streams/#{stream.sid}/activity"
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)

      req = Net::HTTP::Post.new(uri.request_uri)
      req.content_type = "application/json"
      req.body = json

      req.basic_auth(SiteConfig.apid, SiteConfig.token)
      rsp = http.request(req)

      STDERR.puts "#{rsp.code} #{stream.title}"
      items += activity.size and reqs += 1 if rsp.code == 200

      mark_for_deletion << stream if rsp.code == 410 # gone
      # Ignore 500s and 422

      sleep 30
    end
    bad = 0; mark_for_deletion.each { |st| st.destroy; bad += 1 } 
    STDERR.puts "post_activity: #{items}, #{reqs} reqs, deleted #{bad}"
  end

end


