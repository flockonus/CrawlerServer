class CreateCrawlStores < ActiveRecord::Migration
  def self.up
    create_table :crawl_stores do |t|
      t.string :destiny
      t.text :content
      t.boolean :transmited
      t.timestamps
    end
  end
  
  def self.down
    drop_table :crawl_stores
  end
end
