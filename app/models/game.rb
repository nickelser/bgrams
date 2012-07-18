class Game
  include Mongoid::Document
  require 'english_number'
  
  # state flags
  WAITING_FOR_START = 0
  IN_PROGRESS = 1
  
  field :name
  field :short_id, :type => Integer
  field :pgram_lock_held, :type => Boolean, :default => false
  field :dirty, :type => Boolean, :default => false
  field :bag, :type => Array, :default => []
  field :state, :type => Integer, :default => WAITING_FOR_START
  field :session, :type => Integer, :default => 0
  field :lobby_players, :type => Array, :default => []
  field :created_at, :type => Time, :default => Proc.new { Time.now.utc }
  field :private, :type => Boolean, :default => false
  embeds_many :player_sessions
  
  index :short_id
  
  after_create :init_game
  
  LETTERS_PER_PLAYER = 36 # 15
  INITIAL_TILES = 21 # 5
  MAX_PLAYERS_PER_GAME = 7
  MIN_LETTERS = 144 # 21
  
  DUMP_LETTERS_BACK = 3
  
  FREQ_REF = 144
  BASE_FREQS = { 'a' => 13, 'b' => 3, 'c' => 3, 'd' => 6, 'e' => 18, 'f' => 3,
                 'g' => 4, 'h' => 3, 'i' => 12, 'j' => 2, 'k' => 2, 'l' => 5,
                 'm' => 3, 'n' => 8, 'o' => 11, 'p' => 3, 'q' => 2, 'r' => 9,
                 's' => 6, 't' => 9, 'u' => 6, 'v' => 3, 'w' => 3, 'x' => 2,
                 'y' => 3, 'z' => 2 }
  
  def init_game
    self.short_id = Game.count
    if self.name.blank?
      self.name = "game #{self.short_id.to_english}"
    end
    self.save!
  end
  
  def players
    player_sessions.where(:session => session)
  end
  
  def start
    self.state = IN_PROGRESS
    self.dirty = true # set the dirty flag so we don't re-use it
    
    num_letters = [players.length * LETTERS_PER_PLAYER, MIN_LETTERS].max
    # get the correct freqs
    tmp = BASE_FREQS.merge(BASE_FREQS) { |k, v| (v.to_f/FREQ_REF*num_letters).to_i }
    # and turn it to one big array
    self.bag = tmp.map { |k, v| Array.new(v, k) }.flatten.shuffle
    
    # then give tiles to all of mah players
    # we don't care about data integrity for the first tiles :)
    initial_tiles = {}
    
    players.each do |p|
      # grab the initial letters
      letters = self.bag.sample(INITIAL_TILES)
      
      # and remove them from the initial bag
      letters.each { |l| self.bag.delete_at(self.bag.index l) }
      initial_tiles[p.player_id] = letters
      p.letters = letters
      p.save!
    end
    
    self.save!
    initial_tiles
  end
  
  def player_ready?(player)
    players.where(:player_id => player.id).count > 0
  end
  
  def add_player_to_lobby(player)
    raw_add_player_to_lobby(player.id)
  end
  
  def player_in_lobby?(player)
    return !(self.lobby_players.select { |p| p == player.id }.empty?)
  end
  
  def set_lobby(player_list)
    self.lobby_players = player_list.map { |e| _oid(e) }.select { |e| !e.blank? }
    self.save!
  end
  
  def raw_remove_player_from_lobby(player_id)
    return if player_id.blank?
    
    unless (o = _oid(player_id)).blank?
      self.lobby_players -= [o]
      self.save!
    end
  end
  
  def raw_add_player_to_lobby(player_id)
    return if player_id.blank?
    
    unless (o = _oid(player_id)).blank?
      self.lobby_players |= [o]
      self.save!
    end
  end
  
  def add_player(player)
    if players.where(:player_id => player.id).empty?
      ps = PlayerSession.new(:player_id => player.id, :session => self.session)
      self.player_sessions << ps
      self.save!
      player.player_session_ids << ps.id
      player.save!
    end
  end
  
  def remove_letter_from_player(letter, ps)
    return false unless ps.letters.index(letter)
    # atomically delete the first instance of the letter from a player session
    _col.update({'_id' => self.id, "#{ps._position}.letters" => letter},
                {'$unset' => {"#{ps._position}.letters.$" => 1}})
    # $unset replaces the elements with null, so we need to clear that
    _col.update({'_id' => self.id}, {'$pull' => {"#{ps._position}.letters" => nil}})
    true
  end
  
  def add_letters_to_player(letters, ps)
    # atomically add some letters to the set
    unless letters.blank?
      _col.update({'_id' => self.id}, {'$pushAll' => {"#{ps._position}.letters" => letters}})
    end
  end

  def dump(ps, letter)
    # first, remove the letter from the player
    if remove_letter_from_player(letter, ps)
      # successful, so remove the necessary letters from the bag
      new_letters = get_letters_from_bag(DUMP_LETTERS_BACK)
      if new_letters.empty?
        # couldn't dump, so just return their letter back to them
        add_letters_to_player([letter], ps)
        return [letter]
      end
      # atomically add the letters to the player
      add_letters_to_player(new_letters, ps)
      # and finally add the dumped letter to the bag
      add_letter_to_bag(letter)
      # return the added letters to the player
      return new_letters
    end
    # nil if we couldn't find the letter
    nil
  end
  
  def pgram(ps)
    # atomic section start
    if acquire_pgram_lock
      begin
        ok, errors = ps.validate_board
      rescue
        ok = false
        errors = "generic error with validating your board"
      end
      
      if ok
        # bgrams!
        if letters_remaining < players.count
          release_pgram_lock
          return true, {:bgrams => true}
        else
          new_tiles = {}
          players.each do |p|
            new_tiles[p.player_id] = get_letters_from_bag(1)[0]
            add_letters_to_player([new_tiles[p.player_id]], p)
          end
          
          release_pgram_lock
          return true, {:bgrams => false, :new_tiles => new_tiles}
        end
      else
        release_pgram_lock
        return false, errors
      end
    end
    # do not release, since we didn't acquire it!
    return false, "unable to peel, try again :("
  end
  
  # atomically add a letter to the bag
  def add_letter_to_bag(letter)
    self.reload.bag.insert(rand(self.bag.length), letter)
    self.save!
  end
  
  # atomically remove a number of letters from the bag, and return them
  def get_letters_from_bag(num_tiles)
    ret = []
    # so try and pull the values, and re-do until possible
    num_tiles.times do
      # bleh?
      begin 
        l = _col.find_and_modify(:query => {'_id' => self.id}, :update => {'$pop' => {'bag' => 1}}, :fields => {'bag' => 1}, :new => false)
      rescue Mongo::OperationFailure # mongodb bug http://jira.mongodb.org/browse/SERVER-2465
        l = {'bag' => []}
      end
      if l['bag'].length > 0
        ret << l['bag'].last
      end
    end
    
    ret
  end
  
  def letters_remaining
    bag.count
  end
  
  def channel
    Pusher[channel_name]
  end
  
  def channel_name
    'presence-game-'+id.to_s
  end
  
  def unready_players
    (lobby_players - (players.map &:player_id)).length
  end
  
  def ready_players
    players.count
  end
  
  def state_str
    case state
    when WAITING_FOR_START
      "waiting for start"
    when IN_PROGRESS
      "in progress"
    end
  end
  
  # no clue why i have to do it this way
  def _col
    self.db.collection(self.collection.name)
  end
  
  protected
  
  def acquire_pgram_lock
    attempts = 0
        
    while _col.find({'_id' => self.id}, :fields => 'pgram_lock_held').first['pgram_lock_held']
      # couldn't acquire lock!
      if attempts > 15
        return false
      end
      attempts += 1
      sleep 0.01
    end
    
    _col.update({'_id' => self.id}, {'$set' => {'pgram_lock_held' => true}})
    
    return true
  end
  
  def release_pgram_lock
    _col.update({'_id' => self.id}, {'$set' => {'pgram_lock_held' => false}})
  end
  
  def _oid(o)
    return o if o.class == BSON::ObjectId
    begin
      unless o.blank?
        return BSON::ObjectId(o)
      end
    rescue StandardError
      # will return nil
    end
    return nil
  end
end
