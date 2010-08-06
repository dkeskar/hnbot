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
  
end