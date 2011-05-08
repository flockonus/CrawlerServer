class CrawlTemplateController < ApplicationController
  # This gotta be set as the public url accessible
  @@my_url = "127.0.0.1:3000"
  
  after_filter :required_stuff
  
  def index
    @crawl_stores = CrawlStore.all( :conditions => { :destiny => @destiny_cod }, :order => "created_at DESC" )
    render 'crawl_template/index'
  end
  
  def crawl
    "Do the hoppy dope : YQL"
    "Parse that tasty JSON!"
    "wave hello at destiny"
  end
  
  def show
    @reg = CrawlStore.find( params[:id] )
    render 'crawl_template/show'
  end
  
  
  protected
  def required_stuff
    required = [:@salt, :@destiny_cod, :@destiny_url]
    # logger.info "#{@destiny_cod}"
    #FIXME very unreadable | Check if all required fields are defined
    unless required.select{ |x| !instance_variable_get(x) }.empty?
      error_msg = "Define all required fields! (#{required.join(', ')})"
      render( :text => error_msg ) rescue raise( error_msg )
      logger.error "Define all required fields! (#{required.join(', ')})"
      return false
    end
  end
  
  def decode s
    require 'md5'
    logger.info "DECODING: #{s[0,s.size/2] + @salt[0,@salt.size/2] + s[(s.size/2)..-1] + @salt[(@salt.size/2)..-1]}"
    MD5.hexdigest  s[0,s.size/2] + @salt[0,@salt.size/2] + s[(s.size/2)..-1] + @salt[(@salt.size/2)..-1]
  end
  
end
