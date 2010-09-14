class Avatar
  include MongoMapper::Document
  
  key :name, String
  key :karma, Integer
  key :since, Integer 
  key :watch, Boolean
  key :nwx, Integer, :default => 0
  key :valid, Boolean, :default => true
    
  has_many :postings
  has_many :comments

  class NoSuchUser < StandardError; end

  def self.watch(name)
    Avatar.collection.update({:name => name}, 
      {"$inc" => {:nwx => 1}}, :upsert => true
    )
  end

  def self.unwatch(name)
    Avatar.decrement({:name => name}, :nwx => -1)
  end

  def self.watched
    Avatar.where(:nwx.gt => 0).sort(:$name.asc).all
  end

  def self.num_watch
    # default keys may not be stored, since we add watch as an upsert
    Avatar.count({:nwx.gt => 0, :valid.ne => false})
  end

  def unwatch(num)
    Avatar.decrement(:nwx => -1*num)
  end

  def invalid!
    self.set(:valid => false)
  end

end

