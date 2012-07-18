# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110310060941) do

  create_table "game_players", :force => true do |t|
    t.integer  "game_id"
    t.integer  "player_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "letters",                       :null => false
    t.text     "board",                         :null => false
    t.boolean  "ready",      :default => false, :null => false
  end

  add_index "game_players", ["game_id", "player_id"], :name => "index_game_players_on_game_id_and_player_id", :unique => true

  create_table "games", :force => true do |t|
    t.integer  "state",      :default => 0,  :null => false
    t.string   "name",       :default => ""
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "bag"
  end

  create_table "players", :force => true do |t|
    t.string   "username"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "fb_id"
  end

  add_index "players", ["email"], :name => "index_players_on_email"
  add_index "players", ["reset_password_token"], :name => "index_players_on_reset_password_token", :unique => true
  add_index "players", ["username"], :name => "index_players_on_username", :unique => true

  create_table "words", :force => true do |t|
    t.string "word", :null => false
  end

  add_index "words", ["word"], :name => "index_words_on_word", :unique => true

end
