class Avatar < ActiveRecord::Base
  #has_many :postings
  #has_many :comments

  class NoSuchUser < StandardError; end

  # database has column with name valid it not so good because
  # ActiveRecord has a method with name valid?
  # this is patch but would be better to rename column
  def self.instance_method_already_implemented?(method_name)
    return true if method_name.to_s == 'valid?'
    super
  end

  def self.watch(name)
    change_nwx name, 1
  end

  def self.unwatch(name)
    change_nwx name, -1
  end

  def self.change_nwx name, value
    avatar = Avatar.find_by_name(name)
    
    if avatar
      avatar.nwx += value
      avatar.save
    end

    avatar
  end

  def self.watched(method=:all)
    # explicitly check for default keys. They may not be stored with upserts
    Avatar.where('nwx > 0 and valid <> 0').order('name asc').send(method)
  end

  def unwatch(num)
    decrement! :nwx, num
    self
  end

  def invalid!
    update_attribute :valid, false
    self
  end

  def is_watched?
    self.nwx > 0 && self.valid
  end

end

