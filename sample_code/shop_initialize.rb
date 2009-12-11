require "rubygems"
require "activerecord"

ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :dbfile => "shop.sqlite3"
)

class InitialSchema < ActiveRecord::Migration
    def self.up
        create_table :items do |t|
            t.column :name, :string, :null => false
            t.column :stock, :integer, :null => false
        end

        create_table :prices do |t|
            t.column :item_id, :id
            t.column :price, :integer, :null => false
            t.column :created_at, :datetime, :null => false
        end

        create_table :sales do |t|
            t.column :item_id, :id
            t.column :remain, :integer, :null => false
            t.column :created_at, :datetime, :null => false
        end
    end

    def self.down
        drop_table :items
        drop_table :prices
        drop_table :sales
    end
end

InitialSchema.migrate(:up)
