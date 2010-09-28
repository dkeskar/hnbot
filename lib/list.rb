require 'crawler'
# parse and process news.yc list of links
class List < Crawler

  def initialize(url=nil)
    @prefix_url = url
    super
  end

  def user=(avatar)
    raise "Expect Avatar" if not avatar.is_a?(Avatar)
    raise "Prefix URL not set" if not @prefix_url
    @avatar = avatar
    @base_url = "#{@prefix_url}#{@avatar.name}"
  end

  def base_url=(url)
    @avatar = nil
    @base_url = @prefix_url = url
  end

  def process_page
    raise ArgumentError, "Missing document to process" if not @doc
    raise ArgumentError, "Expect Hpricot::Doc" if not @doc.is_a?(Hpricot::Doc)

    titles = @doc.search("tr/td.title:nth-of-type(2)")
    subtexts = @doc.search("tr/td.subtext")

    if titles.size != subtexts.size
      raise "Extraction mismatch t: #{titles.size} s: #{subtexts.size}"
    end
    count = 0

    titles.each_with_index do |hdr, ix| 
      info = subtexts[ix]

      link, title = Link.extract_link_title(hdr)
      link = full_url(link)

      pts, cmts, pid = Link.extract_meta(info)
      user = Link.extract_user(info)
      tm = Link.extract_posted_at(info)

      break if tm and newer_than and (Time.now - tm) > newer_than 

			$stderr.puts "P: #{pid} #{title}"

      avatar = Avatar.first_or_create(:name => user)
      posting = Posting.add(
        :avatar_id => avatar.id, :name => avatar.name,
        :link => link, :title => title,
        :pntx => pts, :cmtx => cmts, 
        :posted_at => tm,
        :pid => pid
      )
      count += 1
    end
    count
  end

  def url_next
		more = @doc.search("tr/td.title/a[@href*='/x?fnid']")
		more.size > 0 ? more.first[:href] : nil
  end

end
