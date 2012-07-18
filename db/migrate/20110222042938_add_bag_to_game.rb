class AddBagToGame < ActiveRecord::Migration
  def self.up
    add_column :games, :bag, :text
  end

  def self.down
    remove_column :games, :bag
  end
end
