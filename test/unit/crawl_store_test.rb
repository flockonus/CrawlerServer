require 'test_helper'

class CrawlStoreTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert CrawlStore.new.valid?
  end
end
