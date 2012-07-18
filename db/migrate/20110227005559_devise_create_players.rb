class DeviseCreatePlayers < ActiveRecord::Migration
  def self.up    
    change_table(:players) do |t|
      #t.token_authenticatable :null => false
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable
    end

    add_index :players, :email
    add_index :players, :reset_password_token, :unique => true
    add_index :players, :username, :unique => true
    # add_index :players, :confirmation_token,   :unique => true
    # add_index :players, :unlock_token,         :unique => true
  end

  def self.down
    #drop_table :players
  end
end
