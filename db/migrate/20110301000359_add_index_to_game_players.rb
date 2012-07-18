class AddIndexToGamePlayers < ActiveRecord::Migration
  def self.up
    add_index :game_players, [ :game_id, :player_id ], :unique => true 
  end

  def self.down
    remove_index :game_players, [ :game_id, :player_id ]
  end
end
