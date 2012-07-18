# global constants
API_URL = '/game/'
TILE_DIM = 32
NUM_TILES_PER_SIDE = 60
BOARD_DIM = TILE_DIM * NUM_TILES_PER_SIDE
PLAYER_BOARD_DIM = 200
PLAYER_TILE_DIM = 10
MIN_TILES = 144
TILES_PER_PLAYER = 36
INITIAL_TILES = 21
WINNER_TILE_DIM = 26
WINNER_BOARD_DIM = [597, 317]

NUM_PLAYERS_ON_SIDE = 3
UPDATE_INTERVAL = 3500
UPDATE_DELAY = 150

# set up global jquery vars
_divs = 
  rack: '#rack'
  board: '#board'
  board_wrapper: '#board_wrapper'
  dump: '#dump'
  chat_input: '#chat_input'
  chatter: '#chatter'
  pubsub: '<div></div>'
  left_players: '#players_left'
  right_players: '#players_right'
  notice: '#notice'
  alert: '#alert'
  pgramb: '#pgram_button'
  progress: '#game_progress'
  pgram_action: '#pgram_action'
  players_ready: '#players_ready'
  total_players: '#total_players'
  ready: '#ready'
  overlay: '#not_started_overlay'
  game_status_wrapper: '#game_status_wrapper'
  how_to_play: '#how_to_play'

_.each _divs, (v, k) -> window["$#{k}"] = $(v)

# utility fns
text_effect = (text, pos) ->
  $("<div class='effect_text'>#{text}</div>").css('left', pos.left).css('top', pos.top)\
    .appendTo('body').animate {opacity: 0, fontSize: 100}, 2600, 'swing', -> $(this).remove()

_i = (i) ->
  parseInt i, 10

_pos = (p) ->
  t = p.split(',') unless _.isArray(p)
  _.map t, (e) -> _i e

response_text = (t) ->
  t.replace(/\"/g, '')
  
disable_selection = (jq) ->
  jq.find('div, span, a').andSelf().disableSelection()

show_notice = (msg, msg_type = 'notice') ->
  $.noticeAdd
    text: msg
    type: msg_type
    
new_message = (msg, who) ->
  w = if who && who.length then "<span class='name'>#{who}:</span> " else ''
  $chatter.append("<div class='message'>#{w} #{msg}</div>").attr
    scrollTop: $chatter.attr 'scrollHeight'

msg_notice = (msg, cls = 'notice') ->
  log "len", msg.length
  if msg.length > 5000
    # probably a backtrace
    msg = "probably a server error :'("
  show_notice msg, cls
  new_message msg, ""

get_tile_from_ui = (ui) ->
  if $(ui.draggable).data('tile')
    $(ui.draggable).data('tile')
  else if $(ui.helper).data('tile')
    $(ui.helper).data('tile')
  else if $(ui.item).data('tile')
    $(ui.item).data('tile')

update_board = (op, tile) ->
  $pubsub.trigger 'update_board', [op, tile]

serialize_board = (board) ->
  ret = ""
  _.each board, (v, k) ->
    ret += "#{k}:#{v.letter}|"
  ret

unserialize_board = (board) ->
  new_board = {}
  
  unless board && board.length > 0
    return new_board
  
  _.each board.split('|'), (e) ->
    log "E:", e
    pos_v = e.split ':'
    if pos_v.length == 2
      pos = pos_v[0].split ','
      pos = [_i(pos[0]), _i(pos[1])] if pos.length == 2
      new_board[pos] = pos_v[1] if pos.length > 1
  
  log "unserialized: ", new_board
  new_board

unserialize_delta = (delta) ->
  new_delta = []
  
  _.each delta.split('|'), (e) ->
    pos_v = e.split ':'
    if pos_v.length == 2
      pos = pos_v[0].split ','
      
      if pos.length > 0 && pos[0] == 'r'
        pos = 'rack'
      else if pos.length == 2
        pos = [_i(pos[0]), _i(pos[1])]
              
      op_letter = pos_v[1].split ','
      new_delta.push({op:op_letter[0], letter:op_letter[1], pos:pos}) if pos.length > 0 && op_letter.length == 2
  
  log "got delta: ", delta
  new_delta

_p_to_str = (p) ->
  if p == 'rack'
    'r'
  else
    p.join ','

serialize_delta = (delta) ->
  _.map(delta, (e) -> "#{_p_to_str e.pos}:#{e.op},#{e.letter}").join "|"

unused_letters = (req_set, used_set) ->
  c = _.clone(used_set)
  _.select req_set, (e) ->
    if (idx = _.indexOf(c, e)) > -1
      c.splice(idx, 1)
      return false
    true

init_csrf = ->
  window._settings.token = $('meta[name="csrf-token"]').attr 'content'

  $.ajaxSetup
    beforeSend: (xhr) ->
      xhr.setRequestHeader "X-CSRF-Token", _settings.token
    type: 'POST'
    data:
      game_id: _settings.game_id

class Chat
  constructor: ->
    @history = []
    @history_pos = 0
    @cur_message = ""

    $chat_input.keydown (e) =>
      c = e.keyCode || e.which
      if c == 13 # enter
        msg = $chat_input.val()
        $.ajax
          url: API_URL + 'chat'
          data:
            message: msg

        log "sent chat msg of #{msg}"
        new_message msg, "you"
        @history.unshift msg
        @history_pos = 0

        $chat_input.val('')
        e.stopPropagation()
      #TODO broken
      else if c == 40 # down arrow
        if @history_pos > 0
          @history_pos -= 1
          if @history_pos > 0
            $chat_input.val @history[@history_pos - 1]
          else
            $chat_input.val(@cur_message)
        e.stopPropagation()
      else if c == 38 # up arrow
        if @history_pos < @history.length
          @cur_message = $chat_input.val() if @history_pos == 0
          @history_pos += 1
          $chat_input.val @history[@history_pos - 1]
        e.stopPropagation()

class ReadyBox
  constructor: ->
    log "on readybox", _settings.game_state, _settings.ready
    
    # if game not started
    if _settings.game_state == 0 && _settings.ready == 0
      @init_ready()
      # make the nice how to play overlay
      $how_to_play.find('a').tooltip
        relative: true
        position: 'bottom center'
      $how_to_play.overlay
        top: 'center'
        oneInstance: true
        closeOnClick: false
        closeOnEsc: false
        load: true
        close: '#NOOP'
    else
      @is_ready()
      @start()
  
  init_ready: ->
    log "init ready"
    $overlay.show()
    $game_status_wrapper.show()
    $ready.addClass('not_ready')
    $ready.removeAttr('disabled')
    $ready.html('ready')
    $ready.click =>
      log "CLICK"
      unless @ready
        _settings.ready = 1
        @is_ready()
        $.ajax
          url: API_URL + 'ready'
          success: (data) =>
            @update_ready data.ready, data.total

  update_ready: (ready, total) ->
    $players_ready.html(ready)
    $total_players.html(total)
  
  update_total: (total) ->
    $total_players.html(total)
  
  is_ready: ->
    $ready.attr('disabled', true)
    $ready.html('already ready')
    $ready.removeClass('not_ready')

  start: ->
    htp = $how_to_play.data('overlay')
    htp.close() if htp
    log "starting the game!"
    $overlay.hide()
    $game_status_wrapper.hide()

class PgramButton
  init: (num_left, @num_players) ->
    log "init num_left ", num_left
    @is_bgram = false
    mt = @num_players * TILES_PER_PLAYER
    @total_tiles = if mt < MIN_TILES then MIN_TILES else mt
    @total_tiles -= (@num_players*INITIAL_TILES)
    log "total tiles", @total_tiles
    if _i(num_left) > 0
      if !$('#pgram_progress_str').length
        $pgramb.append "<div id='pgram_progress_str'>#{num_left} left</div>"
      else
        $('#pgram_progress_str').show()
      
    @new_num_left num_left

  new_num_left: (num_left) ->
    @num_left = _i num_left
    if @num_left < @num_players && !@is_bgram
      $pgram_action.html 'bgrams'
      $pgram_action.css
        left: 5
        top: 5
      $pgramb.width(200)
      @is_bgram = true
      $progress.hide()
      $('#pgram_progress_str').hide()
    else
      $('#pgram_progress_str').show()
      $('#pgram_progress_str').html("#{@num_left} left")
      $progress.width "#{Math.round(@num_left/@total_tiles*100)}%"
  
  reset: ->
    $pgram_action.html 'peel'
    $pgram_action.css
      left: 40
      top: 0
    $pgramb.width(180)
    $('#pgram_progress_str').hide()

class Dump
  constructor: (@rack, @board, @pgram) ->
    @dump = $dump.droppable
      accept: '.tile'
      drop: (e, ui) =>
        if $(ui.draggable).hasClass('ui-multidraggable')
          show_notice 'one at a time, please!', 'error'
          return false
        tile = $(ui.draggable).data('tile')
        if tile.pos == 'rack'
          @rack.remove_tile(tile)
        else
          @board.remove_tile_at_pos(tile.grid_pos())
        log "wtf: ", $(tile.tile)
        $(ui.draggable).remove()
        #$(ui.helper).remove()
        $(ui.helper).hide()
        log "tile.tile", tile.tile
        log "helper: ", $(ui.helper)
        log "e, ui", e, ui
        window._cur_tiles[0].remove()
        #tile.tile.toggle()
        #_.defer ->
        #  tile.tile.toggle()
        #  tile.remove()
        log "dumped", tile
        update_board '-', tile
        $dump.append '<div class="loading"></div>' unless $dump.find('.loading').length

        $.ajax
          url: API_URL + 'dump'
          data: {letter: tile.letter}
          success: (data) =>
            $dump.find('.loading').remove()
            show_notice "dumped! got back #{data.new_letters.join(', ')}"
            log "got letters ", data, " num remain", data.num_remain
            @rack.add_letters data.new_letters
            @pgram.new_num_left data.num_remain
          error: (data) =>
            show_notice "wasn't able to dump! shit.", "error"
            $dump.find('.loading').remove()

    disable_selection @dump

class Tile
  constructor: (@letter, @where, @pos, @tile_dim, @board) ->
    @tile = $("<div class='tile'><div class='letter'>#{@letter}</div></div>")\
              .data('letter', @letter).data('tile', this)
    disable_selection @tile
    @tile.appendTo @where
    @returned = false
    @helper = null
    @dropped_to_board = false
 
  make_draggable: ->
    if @tile.data('draggable')
      @tile.draggable('enable')
    else
      saved_this = this
      @tile.multidraggable
        appendTo: 'body'
        helper: 'clone'
        revert: 'invalid'
        zIndex: 2000
        directionThreshold: TILE_DIM*0.45
        set_tile_group: (e, direction) =>
          log "e: ", e
          log "direction: ", direction
          tiles = @board.get_group_from_tile_and_direction(saved_this, direction)
          window._cur_tiles = tiles
          log "tiles", tiles
          _.each tiles, (t) ->
            log "added class: ", t.tile
            t.tile.addClass('ui-multidraggable')
        start: (e, o, multi) ->
          log "STARTEDDRAG", e, o, multi
          saved_this.in_progress = true
          window._cur_tiles = [saved_this] unless $(this).hasClass('ui-multidraggable')
          log("set tiles!", window._cur_tiles)
          #saved_this.helper = $(this).data('draggable').helper
          $(this).toggle()
        stop: (e, ui) ->
          saved_this.in_progress = false
          log "STOPPEDDRAG"
          $(this).toggle()
          #saved_this.helper = null
  
  make_undraggable: ->
    log "disabling draggable!"
    @tile.removeClass('ui-sortable-helper ui-draggable ui-draggable-helper ui-multidraggable')
    @tile.draggable('destroy')
    @tile.attr('style', '')
    @tile.css
      position: ''
      left: 0
      top: 0
  
  move: (pos = null) =>
    if pos
      top = @tile_dim*(_i pos[1])
      left = @tile_dim*(_i pos[0])
      @pos = {top:top, left:left}
    
    log "setting pos", @pos
    
    @tile.css
      position: 'absolute'
      top: @pos.top
      left: @pos.left
  
  return: (animate = true) ->
    log "returning!"
    unless @pos == 'rack'
      @tile.css
        top: @pos.top
        left: @pos.left
  
  remove: =>
    @where = null
    if @tile.helper
      @tile.helper.remove()
    @tile.remove()
  
  detach: =>
    @where = null
    @tile.detach()
  
  append: (where) =>
    log "appending to", where
    @where = where
    @tile.appendTo @where
    log "ahwat", @tile
        
  get_draggable_pos: () ->
    log "GETTING POS: ", @tile, @tile.data()
    if @tile.data('draggable')
      pos = @tile.data('draggable').position #$(@tile.handle).offset() #if @helper then @helper.offset() else @tile.offset()
    else
      pos = @tile.offset()
    offset = $board.offset()
    left = Math.round((pos.left + @tile_dim/4 - offset.left)/@tile_dim - 0.5) * @tile_dim
    top = Math.round((pos.top - @tile_dim/2 - offset.top)/@tile_dim + 0.5) * @tile_dim
    [left/@tile_dim, top/@tile_dim]
  
  grid_pos: =>
    unless @pos == 'rack'
      [@pos.left/TILE_DIM, @pos.top/TILE_DIM]
    else
      'rack'

class Rack
  constructor: (@board) ->
    @letters = []
  
  init: (tiles) =>
    log "got tiles ", tiles
    @add_letters tiles
  
  reset: =>
    _.each @letters, (e) ->
      e.remove()
    @letters = []
  
  add_letters: (letters) ->
    log "add_letters ", letters
    _.each letters, (letter) => 
      @letters.push(new Tile(letter, @rack, 'rack', TILE_DIM, @board))
  
  add_tile: (tile) ->
    @letters.push tile
  
  remove_letter: (letter) ->
    idx = -1
    
    # XXX use for loop, beeyotch
    _.each @letters, (t, i) ->
      idx = i if t.letter == letter
        
    l = @letters.splice(idx, 1) if idx > -1
    log "SPLICE: ", l
    l[0].remove() if l && l.length > 0
  
  move_tile_to_board: (tile) ->
    if @remove_tile(tile)
      tile.make_draggable()
      tile.tile.toggle()
      _.defer ->
        tile.tile.toggle()
        tile.append $board
        tile.move()
  
  move_tile_to_rack: (tile) ->
    if @letters.indexOf(tile) == -1
      update_board '-', tile
      tile.pos = 'rack'
      update_board '+', tile
      @add_tile tile
      tile.make_undraggable()
      
  remove_tile: (tile) ->
    if (idx = @letters.indexOf(tile)) > -1
      # tile.detach() # XXX
      @letters.splice(idx, 1)
      return true
      
    false

class UserRack extends Rack
  constructor: ->
    super
    @rack = $rack.sortable
      appendTo: 'body'
      #tolerance: 'pointer'
      #revert: 200
      start: (e, ui) =>
        log "draggable", $(ui.draggable)
        tile = get_tile_from_ui ui
        log "tile START", tile, window._cur_tiles
        window._cur_tiles = [tile] if tile
        tile.in_progress = true
      stop: (e, ui) =>
        tile = window._cur_tiles[0]
        log "STOP"
        if tile && tile.dropped_to_board && !tile.returned
          log "moving tile to board"
          @move_tile_to_board tile
        if tile
          tile.returned = false
          tile.dropped_to_board = false
          tile.over_board = false
      
    disable_selection @rack

class PlayerRack extends Rack
  constructor: (@rack) ->
    super
    
class EndOfGame
  constructor: ->
    @in_end = false
    
  end: (players, user_board, user_won, user_id) ->
    log "end of game!", @players, user_board, user_won
    @in_end = true
    @overlay = $("<div id='winner_overlay'></div>").appendTo('body')
    player_obj = {board:user_board, won:user_won, id:user_id, name:'You'}
    players.push player_obj
    winner = {}
    
    _.each players, (e) -> winner = e if e.won
            
    @overlay.append "<div class='name_wrapper'><span class='big name'>#{winner.name} won!</span></div>
                     <div class='names name_wrapper'></div><div class='board_wrapper'></div>"
    
    _.each players, (p, idx) =>
      log "processing player: ", p
      link = $("<a class='#{if p.won then 'winner selected ' else ''}name' href='#'>#{p.name}</a>").click (e) =>
        @load_board p.id
        @overlay.find('.names .name').removeClass('selected')
        $(e.target).addClass('selected')
        e.preventDefault()
        
      @overlay.find('.names').append link
      log "link: ", link
      board_div = $("<div class='board' id='end_player_board_#{p.id}'></div>")
      board = new Board(board_div, WINNER_TILE_DIM, WINNER_BOARD_DIM, true)
      log "using board: ", p.board
      # clean the board state
      cleaned_board = {}
      _.each p.board, (v, k) ->
        cleaned_board[k] = v.letter
      board.initial_board_state cleaned_board
      log "initial board", board
      log "board.board", board_div
      board_div.appendTo @overlay.find('.board_wrapper')
      delete board
    
    @overlay.find('.board').draggable()
    
    @load_board winner.id
    
    @overlay.overlay
      top: 109
      oneInstance: true
      closeOnClick: false
      closeOnEsc: false
      load: true
      close: '#NOOP'
  
  start: =>
    if @in_end
      htp = @overlay.data('overlay')
      htp.close() if htp
      log "starting the game!"
      @overlay.remove()
      @in_end = false
  
  load_board: (id) ->
    log "loading board: ", id
    @overlay.find('.board').hide()
    $("#end_player_board_#{id}").show()

class Board
  constructor: (@board, @tile_dim, @board_dim, @miniboard = false) ->
    @reset()
  
  reset: =>
    @center = {top: -1, left: -1}
    unless _.isEmpty @board_state
      _.each @board_state, (v, k) ->
        v.remove()
    @board_state = {}
    @move_to_center()
  
  move_to_center: ->
    @board.css
      top: -@board_dim/2 + $(window).height()/2
      left: -@board_dim/2 + $(window).width()/2
  
  adjust_center: (pos, initial = false, adjust = true, animate = true) =>
    if adjust
      if @center.top == -1
        @center.top = -pos[1]*@tile_dim
        @center.left = -pos[0]*@tile_dim
      else
        @center.top = (@center.top - pos[1]*@tile_dim)/2
        @center.left = (@center.left - pos[0]*@tile_dim)/2
        unless @miniboard
          @center.top -= $(window).height()/2
          @center.left -= $(window).width()/2 - 400
    log "CENTER", @center
    if _.isArray(@board_dim)
      left = @board_dim[0]/2
      top = @board_dim[1]/2
    else
      left = @board_dim/2
      top = @board_dim/2
      
    unless initial
      css_pos = 
        top: Math.round @center.top + top
        left: Math.round @center.left + left
      
      if adjust && animate
        @board.animate(css_pos, 'slow')
      else
        @board.css(css_pos)
  
  # called initially
  initial_board_state: (board_state) ->
    log "loading board state", board_state
    do_adjust = false
    log "bs ", board_state
    
    _.each board_state, (letter, pos) =>
      @add_letter_at_pos letter, _pos(pos), true
      do_adjust = true
    
    @adjust_center null, false, false if do_adjust
  
  add_letter_at_pos: (letter, pos, initial = false, animate = true) =>
    log "adding ", letter, " at ", pos
    @board_state[pos] = new Tile(letter, @board, pos, @tile_dim, this)
    @board_state[pos].move pos
    @board_state[pos].make_draggable() unless @miniboard
    @adjust_center pos, initial, true, animate
  
  check_tile_move: (tile) =>
    pos = tile.get_draggable_pos()
    gp = tile.grid_pos()
    log "gp", gp, " pos", pos
    #return
    valid_pos = (0 <= pos[0] <= NUM_TILES_PER_SIDE) && (0 <= pos[1] <= NUM_TILES_PER_SIDE)
    
    log "COND1: ", (!@board_state[pos] && valid_pos)
    log "COND2: ", (valid_pos && @board_state[pos] && _.indexOf(window._cur_tiles, @board_state[pos]) > -1)
        
    # ignore it if its in the multidrag group
    if (!@board_state[pos] && valid_pos) || \
       (valid_pos && @board_state[pos] && _.indexOf(window._cur_tiles, @board_state[pos]) > -1)
      return true
    else
      return false
    
  return_tile: (tile) ->
    if tile.pos == 'rack'
      tile.returned = true # rack will take care of it
      tile.dropped_to_board = false
    else
      tile.return()
  
  lift_tile: (tile) =>
    pos = tile.get_draggable_pos()
    gp = tile.grid_pos()
    
    delete @board_state[gp] if @board_state[gp] && @board_state[gp] == tile
    @board_state[pos] = tile
    
    update_board '-', tile
    tile.move pos
  
  place_tile: (tile) ->
    update_board '+', tile
  
  remove_tile_at_pos: (pos) ->
    if @board_state[pos]
      @board_state[pos].remove()
      delete @board_state[pos]

class UserBoard extends Board
  constructor: ->
    log "making userboard"
    @board = $board.draggable()
    $board_wrapper.droppable
      appendTo: '#content'
      accept: '.tile'
      drop: (e, ui) =>
        #log "cur_tiles", window._cur_tiles
        good = true
        one_in_progress = false
        
        _.each window._cur_tiles, (tile) =>
          if tile.in_progress
            one_in_progress = true
            tile.dropped_to_board = true
            tile.in_progress = false
            good = false if good && !@check_tile_move(tile)
        
        if good && one_in_progress
          # gotta do these in two steps, otherwise the delta gets all fucked up (overwriting &c.)
          _.each window._cur_tiles, (tile) =>
            @lift_tile tile
          _.each window._cur_tiles, (tile) =>
            @place_tile tile
        else if !good && one_in_progress
          _.each window._cur_tiles, (tile) =>
            @return_tile tile
        
        e.stopImmediatePropagation()
        
    disable_selection @board
    
    super @board, TILE_DIM, BOARD_DIM
    
    @update_queue = []
    
    # both throttle and delay the update so updates/peels don't trip over each other
    @send_update = _.throttle ( => _.delay(@_send_update, UPDATE_DELAY)), UPDATE_INTERVAL
    $pubsub.bind 'update_board', @update_board
  
  reset: =>
    super
    @update_queue = []
      
  update_board: (e, op, tile) =>
    log "update board: ", tile
    @update_queue.push
      op: op
      pos: tile.grid_pos()
      letter: tile.letter
    
    @send_update()
  
  rack_letters: (inc_letters) =>
    log "values: ", _.values(@board_state).map((e) -> e.letter)
    unused_letters(inc_letters, _.values(@board_state).map((e) -> e.letter))
  
  the_board: =>
    serialize_board @board_state
  
  get_group_from_tile_and_direction: (tile, direction) =>
    # eight possible directions (n, e, s, w) + (ne, se, sw, nw)
    # logic is: all adjacent/contiguous tiles in all the directions besides opposite direction
    # so if input direction is n, contiguous from e,s,w are taken
    # if input is nw, only contiguous from s, e
    gp = tile.grid_pos()
    neighbors = []

    _.each [@_north, @_east, @_south, @_west], (f) =>
      t = f(gp)
      neighbors.push t if t
    
    log "neighbors ", neighbors

    skip_tiles = []
    
    log "direction", direction

    _.each direction, (e) =>
      t = @_opposite_fns(e)(gp)
      log "t", t, "e", e
      if t
        skip_tiles.push t unless neighbors.length == 1 && neighbors[0] == t
          
    log "skips", _.clone(skip_tiles)
    
    tiles = []
    @_get_adjacent_contiguous_tiles(tile, tiles, skip_tiles)
    
    tiles
  
  _get_adjacent_contiguous_tiles: (tile, tiles, skip_tiles, skip_tile_recurse = false) =>
    # nil is passed in if no tile at that square
    # we also can pass if the tile has been added (only added if checked all directions)
    return unless tile && _.indexOf(tiles, tile) == -1 && _.indexOf(skip_tiles, tile) == -1
    
    if skip_tile_recurse
      skip_tiles.push tile
    else
      tiles.push tile
        
    # recurse into the four directions
    unless skip_tile_recurse
      _.each [@_north, @_east, @_south, @_west], (f) =>
        _.each skip_tiles.slice(-4), (st) =>
          @_get_adjacent_contiguous_tiles(f(st.grid_pos()), tiles, skip_tiles, true) if st
        @_get_adjacent_contiguous_tiles(f(tile.grid_pos()), tiles, skip_tiles)
  
  _north: (gp) =>
    @board_state[[gp[0], gp[1]-1]]
  
  _east: (gp) =>
    @board_state[[gp[0]+1, gp[1]]]
  
  _south: (gp) =>
    @board_state[[gp[0], gp[1]+1]]
  
  _west: (gp) =>
    @board_state[[gp[0]-1, gp[1]]]
    
  _opposite_fns: (direction) =>
    switch direction
      when 'n' then @_south
      when 's' then @_north
      when 'e' then @_west
      when 'w' then @_east
  
  get_and_clear_queue: =>
    q = @update_queue
    @update_queue = []
    q
  
  _send_update: (async = true) =>
    unless _.isEmpty @update_queue
      log "sending update: ", serialize_delta(@update_queue)
      $.ajax
        async: async
        url: API_URL + 'update_board'
        data: {delta: serialize_delta(@update_queue)}
      @update_queue = []
      log "board state: ", @board_state
      
class Player
  constructor: (@name) ->
    log "adding #{@name}"
    if $left_players.find('.player').length < NUM_PLAYERS_ON_SIDE
      where = $left_players
    else
      where = $right_players
    
    log "adding player to", where
      
    @player = $("<div class='player'><div class='name_wrapper'><span class='name'>#{@name}</span></div>
                 <div class='board_wrapper'><div class='board'></div></div>
                 <div class='letter_wrapper'><div class='letters'></div></div></div>")\
              .appendTo(where)
              
    disable_selection @player
    @name_div = @player.find '.name'
   
    @rack = new PlayerRack(@player.find '.letters')
    log "PASSING BOARD", @player.find('.board')
    @board = new Board(@player.find('.board'), PLAYER_TILE_DIM, PLAYER_BOARD_DIM, true)
    @did_init = false
    @is_online = true
  
  reset: ->
    @rack.reset()
    @board.reset()
    @did_init = false
  
  init: (letters, board_state) =>
    if board_state
      l = unused_letters(letters, _.values(board_state))
    else
      l = letters
    
    log "HERE", l, " bs", board_state
    @rack.add_letters l
    @board.initial_board_state board_state, false if board_state
    @did_init = true
      
  action: (text) =>
    pos = @player.offset()
    pos.left += 15
    pos.top += @player.height()/2
    text_effect text, pos
  
  handle_delta: (delta) =>
    log "got delta ", delta
    animate = delta.length < 5
    _.each delta, (e) =>
      switch e.op
        when '+' then this.add_tile e.pos, e.letter, animate
        when '-' then this.delete_tile e.pos, e.letter
  
  delete_tile: (pos, letter) =>
    if pos == 'rack' || pos == 'r'
      @rack.remove_letter letter
    else
      @board.remove_tile_at_pos pos
  
  add_tile: (pos, letter, animate = true) =>
    if pos == 'rack' || pos == 'r'
      @rack.add_letters [letter]
    else
      @board.add_letter_at_pos letter, pos, false, animate
  
  online: =>
    log "#{@name} is online!"
    show_notice "#{@name} has joined the game"
    @name_div.addClass 'online'
    @is_online = true
  
  offline: =>
    log "#{@name} is offline :("
    show_notice "#{@name} has left the game"
    @name_div.removeClass 'online'
    @is_online = false
    # TODO send offline to server?
  
  remove: =>
    log "deleting player!"
    @player.remove()
    
class Game
  constructor: ->
    log "constructing game"
    if !_settings.logged_in
      log "not logged in, booting to login overlay"
      # not logged in, show the login box!
      open_login_overlay(true, "gotta sign in to play")
      return
    
    @player_id = _settings.player_id
    @players = {}
    
    init_csrf()
      
    @chat = new Chat()
    @board = new UserBoard()
    @rack = new UserRack(@board)
    @pgram = new PgramButton()
    @dump = new Dump(@rack, @board, @pgram)
    @ready_box = new ReadyBox()
    @end_of_game = new EndOfGame()
    
    this.connect_to_pusher() # calls our loading function
    #this.load_game()
      
  connect_to_pusher: ->
      Pusher.log = log
      Pusher.channel_auth_endpoint = API_URL + 'pusher_auth'
      Pusher.csrf_token = _settings.token
      
      @pusher = new Pusher _settings.api_key
        
      @pusher.subscribe(_settings.channel)\
        .bind('update', this.handle_update)\
        .bind('chat', this.handle_chat)\
        .bind('joined', this.handle_joined)\
        .bind('dump', this.handle_dump)\
        .bind('peel', this.handle_peel)\
        .bind('bgrams', this.handle_bgram)\
        .bind('start', this.handle_start)\
        .bind('player_ready', this.handle_ready)\
        .bind('update_lobby', this.handle_lobby_update)\
        .bind('pusher:subscription_succeeded', this.handle_online)\
        .bind('pusher:member_added', this.handle_member_added)\
        .bind('pusher:member_removed', this.handle_member_removed)
            
      @pusher.bind 'pusher:connection_established', (e) =>
        $.ajaxSetup {data: {socket_id: e.socket_id, game_id:_settings.game_id}}
        this.load_game() unless _settings.game_state == 0 
        
        $(window).unload =>
          # force an update on away navigation
          @board._send_update(false)
        
  load_game: (data) ->
    $.ajax
      url: API_URL + 'load_game'
      data:
        game_id: _settings.game_id
      error: (data) =>
        msg_notice "unable to load game. error: #{response_text(data.responseText)}", "error"
      success: (data) =>
        msg_notice "connected to the game!", "success"
        log "load_game: ", data
        
        inc_playerid = data.id
        
        if inc_playerid != @player_id
          show_notice "failed consistency check! damn.", "error"
          return
        
        @player_id = inc_playerid
        
        @board.initial_board_state unserialize_board(data.board)
        rl = @board.rack_letters(data.letters)
        log "rack letters", rl, " letters", data.letters
        @rack.add_letters @board.rack_letters(data.letters)
        
        log "loaded pgram", data.num_remain, data.players.length
        
        @pgram.init data.num_remain, data.players.length+1
        
        _.each data.players, (e) => this.add_player e
        
        @start()
  
  start: =>
    _settings.game_state = 1
    @ready_box.start()
    @end_of_game.start()
    @enable_interactions()
    
  enable_interactions: =>
    disable_selection $pgram_action
    $pgramb.removeClass 'disabled'
    
    $pgramb.click (e) =>
      return if $pgramb.find('.loading').length
      
      if @rack.letters.length > 0
        show_notice "you still have letters remaining in your rack!", "error"
        return
        
      log "about to send for pgram: ", @board.the_board()
      action = if @pgram.is_bgram then 'bgram' else 'peel'
      $pgramb.append '<div class="loading"></div>'
      $pgramb.addClass('disabled')
      
      $.ajax
        url: API_URL + 'pgram'
        data:
          delta: serialize_delta(@board.get_and_clear_queue())
        success: (data) =>
          $pgramb.find('.loading').remove()
          $pgramb.removeClass 'disabled'
          @pgram.new_num_left data.num_remain
          if action == 'peel'
            @_add_tiles_for_players data.new_letters
            show_notice "peel successful!", "success"
          else
            @handle_win @player_id
        error: (data) =>
          $pgramb.find('.loading').remove()
          $pgramb.removeClass 'disabled'
          log "failed! ", data.responseText
          msg_notice "#{action} failed. error: #{response_text(data.responseText)}", "error"
  
  handle_ready: (data) =>
    @ready_box.update_ready data.ready, data.total
    msg_notice "#{@players[data.player]?.name} is ready!" unless data.player == @player_id
        
  handle_update: (data) =>
    log "update", data
    @players[data.player].handle_delta(unserialize_delta(data.delta))
  
  _add_tiles_for_players: (tiles) =>
    log "adding tiles", tiles
    _.each tiles, (v, k) =>
      log "adding stuff for player: ", k, " me: ", @player_id
      if k == @player_id
        @rack.add_letters v
      else
        @players[k]?.rack.add_letters v
  
  handle_peel: (data) =>
    log "got peel", data
    unless data.player == @player_id
      @players[data.player].action "peel"
      @pgram.new_num_left data.num_remain
      
      msg_notice "#{@players[data.player]?.name} just peeled!"
      @_add_tiles_for_players data.new_tiles
  
  handle_start: (data) =>
    @pgram.init data.num_remain, (_.keys(@players).length)+1
    @_add_tiles_for_players data.initial_tiles
    @start()
    msg_notice "game started!", "success"
  
  handle_bgram: (data) =>
    log "handle_bgram ", data
    unless data.player == @player_id # handled in the ajax handler
      msg_notice "#{@players[data.player].name} just did bgrams, game over :-("
      @handle_win data.player
  
  handle_joined: (data) =>
    this.add_player data
    @ready_box.update_ready data.ready, data.total
  
  handle_chat: (data) =>
    unless data.player == @player_id
      new_message data.message, @players[data.player]?.name
  
  handle_dump: (data) =>
    log "DUMP", data
    @pgram.new_num_left _i(data.num_remain)
    unless data.player == @player_id
      @players[data.player].action "dump"
      @players[data.player].rack.add_letters data.letters
  
  handle_online: (members) =>
    log "other dudes in this game ", members
    _.each members, (member, k) =>
      @add_player(member)?.online()
    
    if _settings.game_state == 0
      log "handling online", _.map(members, (e) -> e.user_id)
      $.ajax
        url: API_URL + 'update_lobby'
        data: {players:_.map(members, (e) -> e.user_id)}
  
  handle_member_added: (member) =>
    log "player #{member.user_id} online"
    @add_player(member)?.online()
    
    if _settings.game_state == 0
      $.ajax
        url: API_URL + 'add_to_lobby'
        data: {player: member.user_id}
  
  handle_member_removed: (member) =>
    log "player #{member.user_id} offline"
    if _settings.game_state == 0
      @players[member.user_id]?.remove()
      delete @players[member.user_id]
      @ready_box.update_total (_.keys(@players).length + 1)
    else
      @players[member.user_id]?.offline()
    
    if _settings.game_state == 0
      $.ajax
        url: API_URL + 'remove_from_lobby'
        data: {player: member.user_id}
  
  add_player: (data) =>
    unless data.id
      data.id = data.user_id
    
    return if data.id == @player_id
      
    if !@players[data.id]
      log "adding player", data.name
      @players[data.id] = new Player data.name
          
    if (data.letters || data.board) && !(@players[data.id].did_init)
      log "adding letters", data.letters, " board", data.board
      @players[data.id].init data.letters, unserialize_board(data.board)
    
    @players[data.id]
  
  handle_win: (player_id) ->
    players = []
    
    _.each @players, (v, k) ->
      players.push {name: v.name, board: v.board.board_state, id: k, won: (k == player_id)}
      v.reset()
    
    log "end of game", players, @board, player_id == @player_id, @board.the_board(), @board.board_state
    
    @end_of_game.end players, @board.board_state, (player_id == @player_id), @player_id
    
    # clear the settings, etc.
    _settings.ready = 0
    _settings.game_state = 0
    
    @ready_box.update_ready 0, @players.length
    @ready_box.init_ready()
    
    # delete offline players
    _.each @players, (v, k) =>
      v.remove() unless v.is_online
      delete @players[k] unless v.is_online
    
    @board.reset()
    @rack.reset()
    @pgram.reset()

$ -> 
  _.defer ->
    common_init()
    new Game