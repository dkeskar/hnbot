require 'net/http'
require 'hpricot'
require 'watchbot'

class HackerNews < Watchbot
  URL = 'http://news.ycombinator.com'
  MAX_PAGES = 7
  
  def self.happy_times
    puts "Yay! #{Time.now}"
  end
  
  def self.stats 
    wb = Watchbot.where(:target_url => URL).first
    {
      :at => wb.last_refresh_at, 
      :duration => ((wb.last_refresh_at - wb.start_refresh_at)/1.minute).round,
      :posts => Posting.count,
      :avatars => Avatar.count
    }
  end
  
  def self.fetch(link, redir_limit = 5)
    raise "Too many HTTP redirects." if redir_limit == 0
    url = URI.parse(link)
    rsp = Net::HTTP.get_response(url)
    case rsp 
    when Net::HTTPSuccess; rsp.body
    when Net::HTTPRedirection; fetch(rsp['location'], redir_lim - 1)
    else; rsp.error!
    end
  end
  
  def self.register(doc)
    me = Watchbot.first_or_new(:target_url => URL)
    if me.new_record?
      me.name = doc.search("title").inner_html
      me.icon_url = doc.search("link[@rel*='icon']").first[:href]
      me.target_rss_url = "#{URL}/rss"
      me.save
    end
    me.update_attributes(:start_refresh_at => Time.now)
  end

  def self.refresh(url = nil, page=1)
    return if page > MAX_PAGES
    
    hn = fetch(url || URL)
    doc = Hpricot(hn)
    
    HackerNews.register(doc)
    
    links = doc.search("tr/td.title/a:not([@rel])")
    points = doc.search("tr/td.subtext/span")
    users = doc.search("tr/td.subtext/a[@href*='user']")
    comments = doc.search("tr/td.subtext/a[@href*='item']")
    times = doc.search("tr/td.subtext")
    page_has_all_stale_links = true
    links.each_with_index do |link, ix|
      av = Avatar.first_or_create(
        :name => users[ix].inner_html
      )
      if tm = times[ix].inner_html.match(/a\>([^\|]+)\s\|/)
        tm = tm[1].strip.split(/\s/)
        period = case tm[1]
        when "hour", "hours"; :hour
        when "day", "days"; :day
        when "minute", "minutes"; :minute
        when "month", "months"; :month
        when "year", "years"; :year
        end
        tm = Time.now - (tm.first.to_i).send(period)
        page_has_all_stale_links = false if (tm > (Time.now - 1.day))
      end
      pts = points[ix].inner_html.split(/\s/).first.to_i
      cmts = comments[ix].inner_html.split(/s/).first.to_i
      Posting.add(:avatar_id => av.id, 
        :link => link[:href], :title => link.inner_html,
        :pntx => pts, :cmtx => cmts, :posted_at => tm
      )
    end
    if not page_has_all_stale_links
      if more = doc.search("tr/td.title/a[@href*='/x?fnid']")
        page_next = "#{URL}#{more.first[:href]}"
        sleep 42 + rand*42
        HackerNews.refresh(page_next, page+1)
      end
    else 
      # Update last_refresh_at 
      Watchbot.where(:target_url => URL).first.set(:last_refresh_at => Time.now)
    end    
  end  
end
