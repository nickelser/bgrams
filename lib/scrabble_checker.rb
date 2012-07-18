module ScrabbleChecker  
  def check_board(board, in_letters)
    horizontal = {}
    vertical = {}
    letters = in_letters.clone
    extras = []
    loners = []
    
    Rails.logger.debug "checking board: "+board.inspect
    Rails.logger.debug "letters: "+in_letters.inspect
    
    board.keys.sort.each do |k|
      x, y = k
      v = board[k].downcase
      
      # check to make sure we are using all the letters
      unless (i = letters.find_index(v)).nil?
        letters.delete_at i
      else
        board.delete k
        extras.push v
        next
      end
      
      # check to see if the letter has no neighbors
      unless board.has_key?([x, y + 1]) || board.has_key?([x, y - 1]) ||
             board.has_key?([x + 1, y]) || board.has_key?([x - 1, y])
        loners.push v
        next
      end
      
      found = false
      
      # build two hashes of words indexed by starting position
      horizontal.each_pair do |start, word|
        xs, ys = start
        # check to see if we are inside the existing word
        if ys == y && x <= (xs + word.length)
          horizontal[start] += v
          found = true
          break
        end
      end
      
      horizontal[k] = v unless found
      found = false
      
      vertical.each_pair do |start, word|
        xs, ys = start
        if xs == x && y <= (ys + word.length)
          vertical[start] += v
          found = true
          break
        end
      end
      
      vertical[k] = v unless found
    end
    
    unwords = (vertical.values + horizontal.values).select do |word|
      word.length > 1 && Word.where(:word => word).count == 0
    end
    
    ret = ""
    ret += "lone letters: #{loners.join(', ')} " if loners.length > 0
    ret += "unwords: #{unwords.join(', ')} " if unwords.length > 0
    ret += "unused letters: #{letters.join(', ')} " if letters.length > 0
    ret += "extra letters (deleted from board): #{extras.join(', ')} " if extras.length > 0
    
    return ret.blank?, ret
  end
end