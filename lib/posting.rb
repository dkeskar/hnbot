require 'valid_property'

class Posting < ActiveRecord::Base
  include ValidProperty

  belongs_to :avatar
  
  class NoSuchItem < StandardError; end 
  class Dead < StandardError; end
  
  def self.add(info={})
    set_data = {}
    added = true
    unless Posting.find_by_pid(info[:pid]).nil?
      # posted at will have larger error drift if we set it all the time. 
      # Better if set first time and never changed later. 
      [:posted_at, :created_at].each {|k| info.delete(k) }
      added = false
      return added if info.keys.size == 1 
    else
      info[:created_at] = Time.now
    end
    info[:updated_at] = Time.now
    Posting.find_or_create_by_pid(info[:pid]).update_attributes(info) 
    added
  end

  def self.bump(pid) 
    Posting.find_by_pid(pid).increment!(:wacx)
  end

  def objectify 
    # thumb and summary to come soon
    { :url => self.link, :title => self.title,
      :meta => {:person => self.name, :points => self.pntx, :comments => self.cmtx}
    }
  end

  def actify
    { :type => 'submit', :uid => self.pid, :time => self.posted_at.to_s}
  end

  def self.unfetched
    Posting.where(:link => nil, :valid => true).all
  end

  # Top posting by watched user activity in last 24 hours
  def self.top
    watched = Avatar.where('nwx > 0').all 
    watched = watched.map {|x| x.id}
    
    two_days_before = (Time.now - 2.day).strftime '%Y-%m-%d'
    pids = Comment.select('pid, count(*) as cmts').where("posted_at > #{two_days_before} and avatar_id in (#{watched.join(',')})").group(:pid).all
    
    pids.sort! { |a, b| b['cmts'] <=> a['cmts']}
    query_pids = pids.map {|x| x['pid']}
    res = Posting.where("pid in (#{query_pids.join(',')}) and valid <> 0").order('updated_at desc').limit(21).all
    pidmap = {}
    res.each {|posting| pidmap[posting.pid] = posting}

    sorted = []
    pids.each { |pinfo| sorted << [pidmap[pinfo['pid']], pinfo['cmts'].to_i]  }
    sorted
  end

end
