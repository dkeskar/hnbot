class Watchbot 
  include MongoMapper::Document
  
  key :title, String
  key :name, String
  key :target_url, String
  key :target_rss_url, String
  key :icon_url, String
  key :frequency, Integer, :default => 1.hour.to_i
  
  key :start_refresh_at, Time
  key :last_refresh_at, Time
  key :refreshing, Boolean

	# used by mongomapper to track classes
	key :_type, String	

  # Fetch URI, deals with redirects
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

	# Record refresh actions
	def record(action=:begin) 
		case action
		when :begin
			self.set(:refreshing => true, :start_refresh_at => Time.now)
		when :end
			self.set(:refreshing => false, :last_refresh_at => Time.now)
		end
	end
	
	# String indicating current refresh status
  def refresh_status 
		if !self.refreshing and !self.last_refresh_at.blank?
			"Refresh done " + 
			((Time.now - self.last_refresh_at)/1.minute).round.to_s + 
			" minutes ago in " + 
			((self.last_refresh_at - self.start_refresh_at)/1.minute).round.to_s + 
			" minutes."
		elsif self.refreshing and !self.start_refresh_at.blank?
			"Refresh began " + 
			((Time.now - self.start_refresh_at)/1.minute).round.to_s + 
			" minutes ago."
		else
			"Refreshed never"
		end
  end
  
end
