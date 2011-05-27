class ReceiverExampleController < ApplicationController
  @@salt = "Gwen1aTere22a@1"
  
  def index
    render :text => "oi"
  end
  
  # possibly a crawler wants to open communication, respond with a test.
  def knock_knock
    test = "" # http://snippets.dzone.com/posts/show/2111
    20.times { test << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    
    Rails.cache.write "crawl_test_for", test
    render :json => [test]
    logger.info ">> KNOCK #{test}, #{form_authenticity_token}"
  end
  
  # check and store the verified ip as safe.
  def open_the_door
    auth = params[:code] == decode( Rails.cache.read("crawl_test_for").to_s )
    logger.info "Auth: #{auth ? 'ok' : 'fail'}! IP:#{ request.remote_ip }"
    
    if auth
      Rails.cache.write 'crawl_ack_ip', request.remote_ip
      render :json => ['ok', form_authenticity_token]
    else
      #render 500 #:json => ['fail']
      logger.info ">>>OPEN_THE_DOOR no"
      throw "fail"
    end
    
    logger.info ">>>OPEN_THE_DOOR yes"
  end
  
  def receive_info
    logger.info "> receiving info from #{ request.remote_ip }"
    
    # If this is the Authed IP (weakspot)
    if request.remote_ip == Rails.cache.read( 'crawl_ack_ip' ).to_s
      new_data = false
      
      # TODO do something specific for each of the params and persist
      
      
      render :json => ['ok']
    else
      throw "fail"
    end
    
    logger.info ">>>RECEIVE_INFO"
  end
  
  def test_post
    if request.post?
      render :json => ['ok']
    end
  end
  
  protected
  
  def decode s
    require 'md5'
    @salt = @@salt
    logger.info "DECODING: #{s[0,s.size/2] + @salt[0,@salt.size/2] + s[(s.size/2)..-1] + @salt[(@salt.size/2)..-1]}"
    MD5.hexdigest  s[0,s.size/2] + @salt[0,@salt.size/2] + s[(s.size/2)..-1] + @salt[(@salt.size/2)..-1]
  end
  
end
