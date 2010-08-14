class Avatar
  include MongoMapper::Document
  
  key :name, String
  key :karma, Integer
  key :since, Integer 
  key :watch, Boolean
    
  has_many :postings
  has_many :comments
  validates_presence_of :name
end
