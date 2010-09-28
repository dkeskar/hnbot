# A property-value store 
class Setting 
  include MongoMapper::Document

  key :name, String, :required => true
  key :value, String
  key :ptyp, String

  def self.setval(name, value) 
    name = (caller[1] =~ /`([^']*)'/ and $1) if name == :method
    kv = {:value => value.to_s, :ptyp => value.class.to_s}
    prop = Setting.first_or_create({:name => name})
    prop.set(kv)
  end

  def self.getval(name)
    name = (caller[1] =~ /`([^']*)'/ and $1) if name == :method
    setting = Setting.first(:name => name) or return nil
    val = case setting.ptyp
    when "Fixnum"; setting.value.to_i
    when "Time"; Time.parse(setting.value)
    when "Float"; setting.value.to_f
    when "TrueClass"; true
    when "FalseClass"; false
    else; setting.value
    end
  end

  def self.remove(name)
    name = (caller[1] =~ /`([^']*)'/ and $1) if name == :method
    if prop = Setting.first(:name => name)
      prop.destroy
    end
    prop.value
  end
end

module Kernel
private
  def this_method
    caller[0] =~ /`([^']*)'/ and $1
  end
  def calling_method
    caller[1] =~ /`([^']*)'/ and $1
  end
end

