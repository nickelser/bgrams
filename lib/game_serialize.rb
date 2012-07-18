module GameSerialize
  def unserialize_board(board)
    new_board = {}
    unless board.blank?
      board.split('|').each do |b|
        pos, v = b.split ':'
        unless pos.blank? || v.blank?
          x, y = pos.split ','
          new_board[[x.to_i,y.to_i]] = v.downcase unless x.blank? || y.blank?
        end
      end
    end
    #logger.debug "cleaned board: "+new_board.inspect
    new_board
  end
  
  def serialize_board(board)
    board.to_a.map { |v| "#{v[0]}:#{v[1]}" }.join '|'
  end
  
  def unserialize_delta(delta)
    new_delta = []
    
    unless delta.blank?
      delta.split('|').map do |b|
        pos, v = b.split ':'
        unless pos.blank? || v.blank?
          op, letter = v.split ','
          new_delta.push({:op => op, :pos => pos, :letter => letter}) unless op.blank? || letter.blank?
        end
      end
    end
    
    Rails.logger.debug "new delta: "+new_delta.inspect
    new_delta
  end
  
  def unserialize_board_keys(board)
    new_board = {}
    
    board.each_pair do |k, v|
      pos = k.split ','
      new_board[[pos[0].to_i, pos[1].to_i]] = v if pos.length == 2
    end
    
    new_board
  end
end