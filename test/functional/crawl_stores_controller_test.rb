require 'test_helper'

class CrawlStoresControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => CrawlStore.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    CrawlStore.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    CrawlStore.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to crawl_store_url(assigns(:crawl_store))
  end
  
  def test_edit
    get :edit, :id => CrawlStore.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    CrawlStore.any_instance.stubs(:valid?).returns(false)
    put :update, :id => CrawlStore.first
    assert_template 'edit'
  end
  
  def test_update_valid
    CrawlStore.any_instance.stubs(:valid?).returns(true)
    put :update, :id => CrawlStore.first
    assert_redirected_to crawl_store_url(assigns(:crawl_store))
  end
  
  def test_destroy
    crawl_store = CrawlStore.first
    delete :destroy, :id => crawl_store
    assert_redirected_to crawl_stores_url
    assert !CrawlStore.exists?(crawl_store.id)
  end
end
