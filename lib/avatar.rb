require 'valid_property'

class Avatar < ActiveRecord::Base
  include ValidProperty

  has_many :postings
  #has_many :comments

  class NoSuchUser < StandardError; end

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

  def is_watched?
    self.nwx > 0 && self.valid
  end

end

