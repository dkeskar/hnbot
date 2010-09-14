require 'crawler'
# parse and process news.yc links 
class Link < Crawler

  def initialize(url)
    @prefix_url = url
    # set base url only after postings are provided
    super
  end

  def item=(posting)
    raise ArgumentError, "Expect Posting" if not posting.is_a?(Posting)
    @posting = posting
    @base_url = "#{@prefix_url}/item?id=#{@posting.pid}"
  end

  def url_next
    nil   
  end

  def process_page
    raise ArgumentError, "Missing document to process" if not @doc 
    raise ArgumentError, "Expect Hpricot::Doc" if not @doc.is_a?(Hpricot::Doc) 
    
    link_info = @doc.search("tr/td.title")
    meta_info = @doc.search("tr/td.subtext")

    if link_info.empty? and @doc.inner_html =~ /no such item/i
      @posting.set(:valid => false)
      raise Posting::NoSuchItem, "pid=#{@posting.pid}"
    end

    link, title = Link.extract_link_title(link_info.first)
    link = full_url(link)
    info = meta_info.first
    pts, cmts, pid = Link.extract_meta(info)
    user = Link.extract_user(info)
    tm = Link.extract_posted_at(info)

    $stderr.puts "P: #{pid} #{title}"

    avatar = Avatar.first_or_create(:name => user)
    posting = Posting.add(
      :avatar_id => avatar.id, :name => avatar.name,
      :link => link, :title => title,
      :pntx => pts, :cmtx => cmts, 
      :posted_at => tm,
      :pid => pid
    )
    1 
  end

  def self.extract_link_title(info)
    raise ArgumentError, "Expect Hpricot::Elem" if !info.is_a?(Hpricot::Elem)
    link = info.at('a')[:href]
    title = info.at('a').inner_html
    [link, title]
  end

  def self.extract_posted_at(info)
    tm = info.inner_html.match(/a\>([^\|]+)\s(\||$)/)
    (tm and tm.size > 1) ? Crawler.time_from_words(tm[1]) : Time.now
  end
 
  def self.extract_user(info)
    info.at("a[@href*='user']").inner_html
  end

  def self.extract_meta(info)
    pts = info.at('span').inner_html.split(/\s/).first.to_i
    item_link = info.at("a[@href*='item']")
    if item_link
      cmts = item_link.inner_html.split(/\s/).first.to_i 
      pid = item_link[:href].match(/item\?id=(\w+)/)
    elsif pt_id = info.at('span')
      # job posts have no comments. Use span info to get id
      pid = pt_id[:id].match(/score_(\w+)/)
    end

    pid = pid[1] if pid and pid.size > 1
    [pts, cmts, pid]
  end
end

