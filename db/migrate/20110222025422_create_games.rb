class CreateGames < ActiveRecord::Migration
  def self.up
    create_table :games do |t|
      t.integer :state, :default => Game::WAITING_FOR_START, :null => false
      t.string :name, :default => ""
      t.string :password, :default => nil
      
      t.timestamps
    end
  end

  def self.down
    drop_table :games
  end
end
