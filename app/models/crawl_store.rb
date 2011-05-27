class CrawlStore < ActiveRecord::Base
  require 'md5'
  # made in a way that allows a custom 'md5 id' for Object
  attr_accessor :custom_md5_id
  
  # chose not to do so, in order to be flexible
  # serialize :content
  
  validates_presence_of :content
  validates_uniqueness_of :md5
  
  before_validation :generate_md5
  
  def generate_md5
    # update/create the attrib md5 when we got new content
    if changes['content']
      
      # if a custom_md5_id is defined, use it
      if self.custom_md5_id
        self.md5 = MD5.hexdigest( self.custom_md5_id )
      else
        self.md5 = MD5.hexdigest( content )
      end
      
    end
  end
  
end
