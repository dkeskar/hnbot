require 'crawler'

# parse and process news.yc comments 
class CommentList < Crawler

  def initialize(url)
    @base_url = url
    super
  end

  def url_next
    # no more than the first page, since /x? is disallowed by robots.txt
    nil
  end

  def process_page
    raise ArgumentError, "Missing document to process" if not @doc
    raise ArgumentError, "Expect Hpricot::Doc" if not @doc.is_a?(Hpricot::Doc)
  end

end

