class Avatar
  include MongoMapper::Document
  
  key :name, String
  key :karma, Integer
  key :since, Integer 
  key :watch, Boolean
    
  has_many :postings
  validates_presence_of :name
end
