class CrawlTemplateController < ApplicationController
  
  # This gotta be set as the public url accessible
  # not anymore.. I guess crawler wont have a public interface anymore
  #@@my_url = "127.0.0.1:3000"
  
  after_filter :required_stuff
  
  def index
    @crawl_stores = CrawlStore.all( :conditions => { :destiny => @destiny_cod }, :order => "created_at DESC" )
    render 'crawl_template/index'
  end
  
  def crawl
    #"Do the hoppy dope : YQL / Crawl"
    #"Parse that tasty JSON!"
    #"wave hello at destiny"
  end
  
  def show
    @reg = CrawlStore.find( params[:id] )
    render 'crawl_template/show'
  end
  
  
  
  def transmit
    # #one-liner:
    # JSON.parse( Net::HTTP.get_response( URI.parse("http://127.0.0.1:3005/find_games/json/1")).body )
    
    
    
    ## STEP 1 : GET wave hello, get a code to decode!
    url = URI.parse("http://#{@base_url+(":#{@port||80}")+@url_path}/knock_knock/1")
    begin
      com = Net::HTTP.get_response( url )
    rescue Exception => e
      @msg = "#crawl ERROR, attempt to communicate with '#{url}' failed: '#{e.message}'"
      logger.error @msg
      return render :text => @msg
    end
    # Try parsing the answer of the communication as JSON
    begin
      secret = JSON.parse( com.body )[0]
    rescue Exception => e
      @msg = "#crawl ERROR, Bad JSON response: '#{e.message}', expected a Array, with 0 containing a secret String!"
      logger.error @msg
      return render :text => @msg
    end
    
    
    ## STEP 2 : GET respond with the decoded secret
    decoded_response = decode( secret )
    params_response = ({  :code => decoded_response }.to_param)
    url = URI.parse("http://#{@base_url+(":#{@port||80}")+@url_path}/open_the_door/1?#{ params_response }")
    begin
      resp = Net::HTTP.get_response( url )
      throw 'Auth Failed' unless JSON.parse( resp.body )[0] == 'ok'
      # from now on, we will keep this session.
      @cookie = resp['set-cookie'].split("; ")[0]
      @auth_token = JSON.parse( resp.body )[1]
    rescue Exception => e
      @msg = "#crawl ERROR, attempt to communicate with '#{url}' failed: '#{e.message}'"
      logger.error @msg
      return render :text => @msg
    end
    
    
    
    ## STEP 3 : POSTs stream data in batches (many times as needed)
    Net::HTTP.start( @base_url, @port || 80 ) { |http|
      
      ## info1 http://stackoverflow.com/questions/941594/understand-rails-authenticity-token
      ## ex1 http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTP.html#M001378
      ## ex2 https://github.com/bensonk/fluttrly
      
      #req = Net::HTTP::Get.new(@url_path+'/')
      #response = Net::HTTP.start(@base_url, @port) { |http| http.request(req) }
      
      ## Parse out the auth token and get the session cookie
      #auth_token = JSON.parse( response.body )[1]
      #cookie = response['set-cookie'].split("; ")[0] #?
      #raise "No auth token" if auth_token.nil?
      
      ## Setup the params for POST
      post_param = {
        'oi' => "omg.. here we are!!!",
        "authenticity_token" => @auth_token
      }
      
      ## Create a POST request
      req = Net::HTTP::Post.new(@url_path+'/test_post/1')
      
      ## Setup parameters
      req.add_field("Cookie", @cookie)
      req.set_form_data(post_param)
      
      ## POST!
      response = Net::HTTP.start(@base_url, @port) { |http| http.request(req) }
      
      
    }
    
    render :text => "the end"
    
    
=begin    
    
    # Fire at the Destiny and receive the code to decypher
    url = URI.parse("http://#{@destiny_url}/knock_knock/1")
    begin
      com = Net::HTTP.get_response( url )
    rescue Exception => e
      @msg = "#crawl ERROR, attempt to communicate with '#{url}' failed: '#{e.message}'"
      logger.error @msg
      return render :text => @msg
    end
    
    # Try parsing the answer of the communication as JSON
    begin
      secret = JSON.parse( com.body )[0]
    rescue Exception => e
      @msg = "#crawl ERROR, Bad JSON response: '#{e.message}', expected a Array, with 0 containing a secret String!"
      logger.error @msg
      return render :text => @msg
    end
    
    
    # Respond with the decoded secret
    decoded_response = decode( secret )
    #decoded_response = "mock 2 fail"
    #params_response = ({  :code => decoded_response, :url => URI.encode("http://#{@@my_url}/#{self.controller_name}") }.to_param)
    params_response = ({  :code => decoded_response }.to_param)
    url = URI.parse("http://#{@destiny_url}/open_the_door/1?#{ params_response }")
    begin
      resp = Net::HTTP.get_response( url )
      throw 'Auth Failed' unless JSON.parse( resp.body )[0] == 'ok'
    rescue Exception => e
      @msg = "#crawl ERROR, attempt to communicate with '#{url}' failed: '#{e.message}'"
      logger.error @msg
      return render :text => @msg
    end
    
    #Stream Data
    stream
    
    
    render :text => params_response + "<br/>OK!"
    puts ">> CRAWL"
=end
  end
  
  
  def stream
    @datas = CrawlStore.find_each( :batch_size => 100, :conditions => ["(transmited = ? or transmited is ?) and destiny = ?", false, nil, @destiny_cod] )
    params_to_send = @datas.map do |d|
      #{ :data => d.content }
      d.content
    end
    
    logger.info ">Sending.."+params_to_send.to_param
    
    
    url = URI.parse("http://#{@destiny_url}/receive_info/1?#{ {:data => params_to_send}.to_param }")
    Net::HTTP.get_response( url )
    
    #render :json => [{:name => "Martin"}, {:name => "Johana"}]
    puts ">> STREAM"
  end
  
  
  protected
  def required_stuff
    required = [:@salt, :@destiny_cod, :@base_url, :@url_path]
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
