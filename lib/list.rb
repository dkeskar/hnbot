
# parse and process news.yc list of links
class List < Crawler

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
      user = info.at("a[@href*='user']").inner_html

      title = hdr.at('a').inner_html
      link = hdr.at('a')[:href]
      link = full_url(link)

      tm = info.inner_html.match(/a\>([^\|]+)\s(\||$)/)
      tm = (tm and tm.size > 1) ? Crawler.time_from_words(tm[1]) : Time.now

			next if (tm < (Time.now - newer_than))
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

  # FIXME: deprecated
	def update_bot_bio
  	self.name = @doc.search("title").inner_html
  	self.icon_url = @doc.search("link[@rel*='icon']").first[:href]
  	self.target_rss_url = "#{@base_url}/rss"
  	self.save
	end


end
