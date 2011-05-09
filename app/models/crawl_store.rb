class CrawlStore < ActiveRecord::Base
  require 'md5'
  
  validates_presence_of :content
  validates_uniqueness_of :md5
  
  before_validation :generate_md5
  
  def generate_md5
    # update/create the attrib md5 when we got new content
    if changes['content']
      self.md5 = MD5.hexdigest( content )
    end
  end
  
end
