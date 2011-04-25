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
    t1 = Time.now
    puts ">> START #{@destiny_cod} #{t1}"
    @agent = Mechanize.new
    # this is the sorted by Oldest titles.
    # url_xbox = 'http://www.gamestop.com/browse/xbox-360?nav=28rp0,1385'
    
    # Only Games sorted by oldest first
    url_xbox = 'http://www.gamestop.com/browse/xbox-360/games?nav=2b0,28rp0,1385-177' # http://www.gamestop.com/browse/xbox-360/games?nav=2b1344,28rp0,1385-177
    
    @page = page_fetch( url_xbox )
    
    return fail_response unless @page
    
    return fail_response unless test_page_crumb( @page, :xbox360 )
    
    itens = []
    
    # Crawl the whole page
    @page.search( '.product' ).each do |div| # '.product.new_product'
      
      status = div.search('.purchase_info > h4').text # 'BUY NEW' | 'BUY PRE-OWNED' | 'BUY DIGITAL'
      
      next unless assert_product_status( status )
      
      itens.push << extract_game_data( div )
      
    end
    
    # Persist the valid info
    valid_count = 0
    itens.each do |item|
      
      next unless item
        
      c = CrawlStore.new({
        :destiny    => @destiny_cod,
        :content    => item.to_yaml
      })
      
      if c.save
        valid_count += 1
        puts ">>  SAVED #{ c.id }"
      else
        puts ">>  FAILED #{ c.errors.inspect }"
      end
      
      
    end
    
    
    puts ">> WIN #{Time.now - t1}s"
    puts ""
    render :text => "[WIN]"
  end
  
  
  
  
  
  
  
  def assert_product_status( str )
    # only parse if NEW | DIGITAL --don't want pre-owned repetition
    
    str =~ /new/i or str =~ /digital/i
  end
  
  def extract_game_data( div )
    item = nil
    
    begin
      item = {
        'name' => div.search('h3>a').text.strip,
        'by' => div.search('.publisher').text.strip.split(' ')[-1],
        'default_rate' => div.search('.rating > strong > em').text.to_f,
        'img_source' => div.search('.product_art').attribute('src').value,
        'price_now' => div.search('.pricing').text.strip.sub(/\$/, '').to_f,
        'their_url' => div.search('h3>a').attribute('href').text,
        'digital' => ( div.search('.purchase_info > h4').text =~ /digital/i ) ? true : false
      }
    rescue
      puts ">>  FAIL extract_game_data()"
    end
    
    puts ">>  GOT #{item.inspect}"
    
    item
    
  end
  
  
  def page_fetch( url_str )
    page = ( @agent.get( url_str ) rescue nil )
    
    if page
      puts ">>  OK Page Fetch"
    else
      puts ">>  FAIL Page Fetch"
    end
    
    page
  end
  
  def test_page_crumb( page, target )
    target = case( target )
      when :xbox360 then /Xbox.*360/i
      # add more ..
      else raise("ARGUMENT target is unknown")
    end
    
    if page && page.search( '.results_header.grid_20.alpha' ).inner_text =~ target
      puts ">>  OK XBOX String - match"
      return true
    else
      puts ">>  FAIL XBOX String - match"
      return false
    end
  end
  
  def fail_response
    render :text => ['FAIL']
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
