class CrawlTemplateController < ApplicationController
  
  ## Warning
  # make sure to define all required stuff in the child controller!
  after_filter :required_stuff
  
  def index
    @crawl_stores = CrawlStore.all( :conditions => { :destiny => @destiny_cod }, :order => "created_at DESC" )
    render 'crawl_template/index'
  end
  
  def show
    @reg = CrawlStore.find( params[:id] )
    render 'crawl_template/show'
  end
  
  
  
  def transmit
    
    data_sent_count = 0
    
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
    
    
    transmissions_count = 0
    fail_flag = false
    ## STEP 3 : POSTs stream data in batches (many times as needed)
    Net::HTTP.start( @base_url, @port || 80 ) { |http|
      
      ## POST!
      # see thanks.txt for insights
      
      response = Net::HTTP.start(@base_url, @port){ |http|
        stream do |data|
          
          # the actual data push!
          resp = http.request( factory_request(data) )
          
          #response analysis
          if (JSON.parse( resp.body )[0] rescue false)
            transmissions_count += 1
            data_sent_count += data.size
          else
            fail_flag = true
            logger.info ">> transmit() got an error! #{resp.body}"
            break
          end
          
          
          logger.info ">> data sent #{data.size} "
          
          sleep( @time_between_transmissions || 0.1 ) # this param can make this operation real long..
        end
      }
      
    }
    
    render :text => "the end! sent [#{data_sent_count}] records under [#{transmissions_count}] POSTs. Failed at any point? [#{fail_flag}]. See log for details"
    
  end
  
  
  
  
  
  
  
  
  
  
  protected
  
  def stream &block
    CrawlStore.find_in_batches( :batch_size => 100, :conditions => ["destiny = ? and(transmited = ? or transmited is ?)", @destiny_cod, false, nil,] ) do |regs|
      ids = []
      data_to_send = regs.map do |d|
        ids.push d.id
        d.content
      end
      
      yield data_to_send
      
      # if transmission suceeded, mass mark as sent! #http://apidock.com/rails/ActiveRecord/Base/update_all/class
      CrawlStore.update_all({:transmited => true}, {:id => ids})
    end
    
  end
  
  
  
  def factory_request( data_arr )
    
    ## Setup the params for POST
    post_param = {
      "authenticity_token" => @auth_token
    }
    data_arr.each_with_index do |reg,i|
      post_param["data[#{i}]"] = reg
    end
    
    
    ## Create a POST request
    req = Net::HTTP::Post.new( @url_path+'/receive_info/1' )
    
    ## Setup parameters
    req.add_field("Cookie", @cookie)
    req.set_form_data(post_param)
    
    return req
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
