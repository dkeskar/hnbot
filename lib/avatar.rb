class Avatar
  include MongoMapper::Document
  
  key :name, String
  key :nwx, Integer, :default => 0
  key :valid, Boolean, :default => true
    
  has_many :postings
  has_many :comments

  class NoSuchUser < StandardError; end

  def self.watch(name)
    Avatar.increment({:name => name}, {:nwx => 1})
  end

  def self.unwatch(name)
    Avatar.decrement({:name => name}, {:nwx => 1})
  end

  def self.watched(method=:all)
    # explicitly check for default keys. They may not be stored with upserts
    Avatar.where(:nwx.gt => 0, :valid.ne => false).sort(:$name.asc).send(method)
  end

  def unwatch(num)
    Avatar.decrement(:nwx => -1*num)
  end

  def invalid!
    self.set(:valid => false)
  end

  def is_watched?
    self.nwx > 0 && self.valid
  end

end

