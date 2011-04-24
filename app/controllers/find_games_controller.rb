class FindGamesController < CrawlTemplateController

  before_filter :define_instance_variables
  def define_instance_variables
    @salt = "Gwen1aTere22a@1" # this MUST be different for each destiny!
    @destiny_cod = "find_games"
    @destiny_url = "127.0.0.1:3000/receiver_example" # must be other Server! Running on the same will block
  end
  
  def index
    super
    
    #render :text => Rails.cache.read('req_count')
    #Rails.cache.write 'req_count', 0
  end
  
  def fetch_data
    agent = Mechanize.new
    # this is the sorted by Oldest titles.
    url_xbox = 'http://www.gamestop.com/browse/search.aspx?dsNav=Ns:inventory.PreorderAvailabilityDate|101|-1|,N:138'
    page = agent.get( url_xbox )
    
    ".product.new_product"
    
    render :text => "Bla Bla Bla"
  end
  
  def crawl
    # Suspecting of multiple calls, but probably not #Rails.cache.increment 'req_count'
    # CONSOLE
    # r = Net::HTTP.get_response URI.parse("http://127.0.0.1:3005/find_games/json/1")
    # r.body #=> "[1,2,3]"
    # JSON.parse( r.body ) #=> [1, 2, 3]
    # 
    # #one-liner:
    # JSON.parse( Net::HTTP.get_response( URI.parse("http://127.0.0.1:3005/find_games/json/1")).body )
    
=begin    do
      new_record = false
      fetch = URL.request Net::HTTP.get_response URI.parse("place to crawl")
      fetch.div.each do |d|
        info = d.crawled_fields_to_yaml
        unless CrawlStore.find(@destiny_cod, info)
          CrawlStore.add(@destiny, info)
          new_record = true
        end
        
      end
    while(new_record)
=end
    
    
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
  end
  
  protected
  
  def stream
    @datas = CrawlStore.all( :conditions => ["(transmited = ? or transmited is ?) and destiny = ?", false, nil, @destiny_cod] )
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
  
end
