class PlayerSession
  include Mongoid::Document
    
  include ScrabbleChecker
  include GameSerialize
  
  field :letters, :type => Array, :default => []
  field :board, :type => Hash, :default => {}
  field :won, :type => Boolean, :default => false
  field :session, :type => Integer, :default => 0
  referenced_in :player
  embedded_in :game, :inverse_of => :player_sessions
  
  def update_board(delta)
    delta = unserialize_delta(delta)
    
    delta.each do |d|
      if d[:op] == '-' && d[:pos] != 'r'
        _parent._col.update({'_id' => _parent.id, "#{self._path}._id" => self.id},
                            {'$unset' => {"#{self._position}.board.#{d[:pos]}" => true}})
      elsif d[:op] == '+' && d[:pos] != 'r'
        _parent._col.update({'_id' => _parent.id, "#{self._path}._id" => self.id},
                            {'$set' => {"#{self._position}.board.#{d[:pos]}" => d[:letter]}})
      end
    end
    
    delta.blank?
  end
  
  def validate_board
    unless self.board.blank?
      ret = check_board(unserialize_board_keys(self.board), self.letters)
      self.save
      return ret
    end
    
    return false, "empty board"
  end
end
