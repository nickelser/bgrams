class SeparateOutState < ActiveRecord::Migration
  def self.up
    add_column :game_players, :letters, :text, :null => false, :default => ""
    add_column :game_players, :board, :text, :null => false, :default => ""
    remove_column :game_players, :state
  end

  def self.down
    remove_column :game_players, :letters
    remove_column :game_players, :board
    add_column :game_players, :state, :text
  end
end
