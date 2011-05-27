class FindGamesController < CrawlTemplateController

  before_filter :define_instance_variables
  def define_instance_variables
    @salt = "Gwen1aTere22a@1" # this MUST be different for each destiny!
    @destiny_cod = "find_games"
    @base_url = "localhost" 
    @port = 3001            # must be other server! Running on the same one will block
    @url_path = '/receiver_example'
    @sleep = 0.8
  end
  
  def puts msg
    logger.info { msg }
    Kernel.puts msg
  end
  
  def index
    super
    #render :text => Rails.cache.read('req_count')
    #Rails.cache.write 'req_count', 0
  end
  
  
  
  
  def concept_test
    
    # test pre-owned MD5 effective?
    url = "http://www.gamestop.com/browse/nintendo-wii?nav=16k-Iron+Man,28-xp0,138a"
    fetch_data_for( 'wii', url ) rescue nil
    render :text => "See server output!"
    
  end
  
  
  def mega_initial_fetch
    t1 = Time.now
    puts ">> START mega_initial_tech() for #{@destiny_cod} #{t1}"
    
    load_console_list()
    
    # caso venha por parametro o nome da plataform, roda só ela.
    #if params[:id] && params[:id] != 'all'
    if @consoles[ params[:id] ]
      fetch_data_for( params[:id], @consoles[ params[:id] ] )
    elsif params[:id] == 'all'
      @consoles.each do |k,v|
        fetch_data_for( k, v )
      end
    else
      return render :text => "['FAIL', 'bad use of param on request']"
    end
    
    
    
    puts ">> WIN global #{Time.now - t1}s"
    puts ""
    render :text => "['WIN']"
    
  end
  
  
  
  
  def fetch_data_for( platform=nil, url=nil )
    
    if !platform || !platform.is_a?(String)
      puts ">>  FATAL param missing :platform"
      return fail_response
    end
    
    if !url || !url.is_a?(String)
      puts ">>  FATAL param missing :url"
      return fail_response
    end
    
    
    if @agent = Mechanize.new
      @agent.user_agent_alias = "Linux Firefox"
      puts ">> INIT platform: #{platform}"
    else
      puts ">> INIT-FAIL platform: #{platform}"
    end
    
    i = 0
    valid_count = 0
    
    while( url ) do
      
      i += 1
      puts ">>  PAGE #{i}"
      # try and fetch page
      @page = page_fetch( url )
      
      return fail_response unless @page
      
      # assert if the page name fetched was the expected
      return fail_response unless test_page_crumb( @page, platform )


      itens = []
      
      # ✓ Crawl the whole page
      @page.search( '.product' ).each do |div| # '.product.new_product'
        
        next unless assert_product_status( div )
        
        itens.push << extract_game_data( div, platform )
        
      end
      
      # Persist the valid info
      #valid_count = 0
      itens.each do |item|
        
        next unless item
          
        c = CrawlStore.new({
          :destiny    => @destiny_cod,
          :content    => item.to_yaml
        })

        # dont want stuff like 'price' or 'rate' in the md5
        c.custom_md5_id = (item['name'].to_s + item['by'].to_s + item['platform'].to_s rescue "" )
        
        if c.save
          valid_count += 1
          puts ">>  SAVED #{ c.id }"
        else
          puts ">>  FAILED #{ c.errors.to_json }"
        end
        
      end
      
      
      # Busca pelo link de 'Next'
      #@next_link = fetch_next_page_link( @page )
      last_url = url+""
      url = fetch_next_page_link( @page )
      
      # give a small time b4 continues
      zzz = 9 + rand(5) + rand(5) + rand()
      puts ">>  SLEEPING #{zzz}s "
      sleep zzz
      
      #return fail_response unless @next_link
      #unless url
      #  puts ">>  FINISHED #{platform}, #{i}+1 pages"
      #end
      
    end
    
    puts ">>  FINISHED #{platform}, #{i} pages, #{valid_count} valid scrapes"
    
  end
  
  
  
  
  def fetch_next_page_link page
    next_link = nil
    page.search('.result_pagination')[0].children.search('a').each do |link| 
      begin 
        next_link = link[:href] if link.text =~ /next/i
      rescue
        #puts('>>  FAIL fetch_next_page_link()')
        1
      end
    end
    next_link
  end
  
  
  def assert_product_status( div )
    
    valid = true
    
    # as from NOW, we may want PRE-OWNED too.. # only parse if NEW | DIGITAL --don't want PRE-OWNED repetition
    condition = div.search('.purchase_info > h4').text
    if !(condition =~ /new/i) and !(condition =~ /digital/i) and !(condition =~ /pre-own/i)
      valid = false
      puts ">>  SKIP don't want #{condition}"
    end
    
    # Also, don't get unreleased games!
    prod_info = div.search('.product_info > ul').text()
    if valid && ( prod_info =~ /Release Date/i || prod_info =~ /Pre-order/i )
      valid = false
      puts ">>  SKIP unreleased game"
    end
    
    # For PSP, we want no satisfaction Movie!
    if valid && div.search('.product_info h3 strong').text =~ /UMD Mov/i
      valid = false
      puts ">>  SKIP psp movie"
    end
    
    
    valid
  end
  
  def extract_game_data( div, platform )
    item = nil
    
    begin
      # Soft attributes set here.
      item = {
        'name' => div.search('h3>a').text.strip,
        'by' => div.search('.publisher').text.match(/by (.*)/)[1].strip,
        'platform' => platform,
        'default_rate' => div.search('.rating > strong > em').text.to_f,
        'img_source' => div.search('.product_art').attribute('src').value,
        'price_now' => div.search('.pricing').text.strip.sub(/\$/, '').to_f,
        'their_url' => div.search('h3>a').attribute('href').text,
        'esrb' => div.search('div.product_info img').attribute('src').text.match( /.*search_(.*)\./)[1],
        'digital' => ( div.search('.purchase_info > h4').text =~ /digital/i ) ? true : false,
      }
      puts ">>  GOT #{item.inspect}"
    rescue
      puts ">>  FAIL extract_game_data()"
    end
    
    
    item
    
  end
  
  
  def page_fetch( url_str )
    page = ( @agent.get( url_str ) rescue nil )
    
    if page
      puts ">>  OK Page Fetch: #{url_str}"
    else
      puts ">>  FAIL Page Fetch: #{url_str}"
    end
    
    page
  end
  
  def test_page_crumb( page, target )
    target = case( target )
      when 'xbox360' then /Xbox.*360/i
      when 'ps3'     then  /PlayStation/i
      when 'wii'     then  /Wii/i
      when '3ds'     then  /3DS/i
      when 'ds'      then  /Nintendo.*DS/i
      when 'psp'     then  /Sony.*PSP/i
      when 'pc'      then  /PC/i
      
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
    #render :text => ['FAIL']
    raise("CRAWLER BOOMMMMMMMMMM !!!!!!!!!!!!")
  end
  
  
  
  
  
  protected
  
  def load_console_list
    @consoles = ActiveSupport::OrderedHash.new()
    @consoles['xbox360'] =       'http://www.gamestop.com/browse/xbox-360/games?nav=2b0,28rp0,1385-177'
    @consoles['ps3'] =           'http://www.gamestop.com/browse/playstation-3/games?nav=28rp0,138d-177'
    @consoles['wii'] =           'http://www.gamestop.com/browse/nintendo-wii/games?nav=28rp0,138a-177'
    @consoles['3ds'] =           'http://www.gamestop.com/browse/games/nintendo-3ds?nav=28rp0,131a2-177'
    @consoles['ds'] =            'http://www.gamestop.com/browse/games/nintendo-ds?nav=28rp0,1386-177'
    @consoles['psp'] =           'http://www.gamestop.com/browse/sony-psp/games?nav=2b0,28rp0,1388-177'
    @consoles['pc'] =            'http://www.gamestop.com/browse/pc/games?nav=28rp0,138c-177'
  end
  
end
