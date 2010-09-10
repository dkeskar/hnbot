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
  validates_presence_of :name

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

  def unwatch(num)
    Avatar.decrement(:nwx => -1*num)
  end

end

