require 'net/http'
require 'hpricot'

# General utilities and functions for crawling and parsing 
class Crawler 
  attr_accessor :max_pages, :prefix_url, :base_url, :newer_than
  attr_accessor :doc

  def initialize(min_wait=23, var_wait=42, max_pages=10)
    @min_wait = min_wait
    @var_wait = var_wait
    @max_pages = max_pages
    @newer_than = 10.day
  end

  def wait_interval
    10 #@min_wait + rand*@var_wait
  end

  # Fetch URI, deals with redirects
  def self.fetch(link, redir_limit = 5)
    raise "Too many HTTP redirects." if redir_limit == 0
    url = URI.parse(URI.encode(link))
    rsp = Net::HTTP.get_response(url)
    case rsp 
    when Net::HTTPSuccess; rsp.body
    when Net::HTTPRedirection; fetch(rsp['location'], redir_lim - 1)
    else; rsp.error!
    end
  end

  # extracts a time value from words such as "21 minutes ago"
  def self.time_from_words(tmstr)
    return Time.now if tmstr.blank?
    tm = tmstr.strip.split(/\s/)
    period = case tm[1]
    when "hour", "hours"; :hour
    when "day", "days"; :day
    when "minute", "minutes"; :minute
    when "month", "months"; :month
    when "year", "years"; :year
    else
      return Time.now
    end
    tm = Time.now - (tm.first.to_i).send(period)
  end

  def full_url(link)
    return link if link.nil? or link =~ /^http/
    link = "/#{link}" if link !~ /^\//
    "#{@prefix_url || @base_url}#{link}"
  end

  def crawl(url=nil, page=1)
    url = @base_url if page == 1 and url.nil?
    url = full_url(url)
    $stderr.puts "Crawl: more: #{url}, pg: #{page}"
    raise "URL needs to be passed on or set via #base_url" if not url

    @doc = Crawler.fetch(url)
    @doc = Hpricot(@doc)
    count = process_page

    if count > 0 and page < @max_pages and (more = url_next)
      sleep wait_interval
      crawl(more, page+1)
    end
  end

  def url_next
    # override this method in derived classes
    nil
  end

  def process_page(items_newer_than=10.day)
    # override this methid in derived class
    false
  end

end
