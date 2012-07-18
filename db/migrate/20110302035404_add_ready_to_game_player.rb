class AddReadyToGamePlayer < ActiveRecord::Migration
  def self.up
    add_column :game_players, :ready, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :game_players, :ready
  end
end
