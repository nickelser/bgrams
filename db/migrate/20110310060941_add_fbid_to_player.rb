class AddFbidToPlayer < ActiveRecord::Migration
  def self.up
    add_column :players, :fb_id, :string
  end

  def self.down
    remove_column :players, :fb_id
  end
end
