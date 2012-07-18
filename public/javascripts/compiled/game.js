/* DO NOT MODIFY. This file was compiled Sat, 09 Apr 2011 01:00:16 GMT from
 * /Users/nickelser/Development/bgrams/app/coffeescripts/game.coffee
 */

(function() {
  var API_URL, BOARD_DIM, Board, Chat, Dump, EndOfGame, Game, INITIAL_TILES, MIN_TILES, NUM_PLAYERS_ON_SIDE, NUM_TILES_PER_SIDE, PLAYER_BOARD_DIM, PLAYER_TILE_DIM, PgramButton, Player, PlayerRack, Rack, ReadyBox, TILES_PER_PLAYER, TILE_DIM, Tile, UPDATE_DELAY, UPDATE_INTERVAL, UserBoard, UserRack, WINNER_BOARD_DIM, WINNER_TILE_DIM, disable_selection, get_tile_from_ui, init_csrf, msg_notice, new_message, response_text, serialize_board, serialize_delta, show_notice, text_effect, unserialize_board, unserialize_delta, unused_letters, update_board, _divs, _i, _p_to_str, _pos;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  API_URL = '/game/';
  TILE_DIM = 32;
  NUM_TILES_PER_SIDE = 60;
  BOARD_DIM = TILE_DIM * NUM_TILES_PER_SIDE;
  PLAYER_BOARD_DIM = 200;
  PLAYER_TILE_DIM = 10;
  MIN_TILES = 144;
  TILES_PER_PLAYER = 36;
  INITIAL_TILES = 21;
  WINNER_TILE_DIM = 26;
  WINNER_BOARD_DIM = [597, 317];
  NUM_PLAYERS_ON_SIDE = 3;
  UPDATE_INTERVAL = 3500;
  UPDATE_DELAY = 150;
  _divs = {
    rack: '#rack',
    board: '#board',
    board_wrapper: '#board_wrapper',
    dump: '#dump',
    chat_input: '#chat_input',
    chatter: '#chatter',
    pubsub: '<div></div>',
    left_players: '#players_left',
    right_players: '#players_right',
    notice: '#notice',
    alert: '#alert',
    pgramb: '#pgram_button',
    progress: '#game_progress',
    pgram_action: '#pgram_action',
    players_ready: '#players_ready',
    total_players: '#total_players',
    ready: '#ready',
    overlay: '#not_started_overlay',
    game_status_wrapper: '#game_status_wrapper',
    how_to_play: '#how_to_play'
  };
  _.each(_divs, function(v, k) {
    return window["$" + k] = $(v);
  });
  text_effect = function(text, pos) {
    return $("<div class='effect_text'>" + text + "</div>").css('left', pos.left).css('top', pos.top).appendTo('body').animate({
      opacity: 0,
      fontSize: 100
    }, 2600, 'swing', function() {
      return $(this).remove();
    });
  };
  _i = function(i) {
    return parseInt(i, 10);
  };
  _pos = function(p) {
    var t;
    if (!_.isArray(p)) {
      t = p.split(',');
    }
    return _.map(t, function(e) {
      return _i(e);
    });
  };
  response_text = function(t) {
    return t.replace(/\"/g, '');
  };
  disable_selection = function(jq) {
    return jq.find('div, span, a').andSelf().disableSelection();
  };
  show_notice = function(msg, msg_type) {
    if (msg_type == null) {
      msg_type = 'notice';
    }
    return $.noticeAdd({
      text: msg,
      type: msg_type
    });
  };
  new_message = function(msg, who) {
    var w;
    w = who && who.length ? "<span class='name'>" + who + ":</span> " : '';
    return $chatter.append("<div class='message'>" + w + " " + msg + "</div>").attr({
      scrollTop: $chatter.attr('scrollHeight')
    });
  };
  msg_notice = function(msg, cls) {
    if (cls == null) {
      cls = 'notice';
    }
    log("len", msg.length);
    if (msg.length > 5000) {
      msg = "probably a server error :'(";
    }
    show_notice(msg, cls);
    return new_message(msg, "");
  };
  get_tile_from_ui = function(ui) {
    if ($(ui.draggable).data('tile')) {
      return $(ui.draggable).data('tile');
    } else if ($(ui.helper).data('tile')) {
      return $(ui.helper).data('tile');
    } else if ($(ui.item).data('tile')) {
      return $(ui.item).data('tile');
    }
  };
  update_board = function(op, tile) {
    return $pubsub.trigger('update_board', [op, tile]);
  };
  serialize_board = function(board) {
    var ret;
    ret = "";
    _.each(board, function(v, k) {
      return ret += "" + k + ":" + v.letter + "|";
    });
    return ret;
  };
  unserialize_board = function(board) {
    var new_board;
    new_board = {};
    if (!(board && board.length > 0)) {
      return new_board;
    }
    _.each(board.split('|'), function(e) {
      var pos, pos_v;
      log("E:", e);
      pos_v = e.split(':');
      if (pos_v.length === 2) {
        pos = pos_v[0].split(',');
        if (pos.length === 2) {
          pos = [_i(pos[0]), _i(pos[1])];
        }
        if (pos.length > 1) {
          return new_board[pos] = pos_v[1];
        }
      }
    });
    log("unserialized: ", new_board);
    return new_board;
  };
  unserialize_delta = function(delta) {
    var new_delta;
    new_delta = [];
    _.each(delta.split('|'), function(e) {
      var op_letter, pos, pos_v;
      pos_v = e.split(':');
      if (pos_v.length === 2) {
        pos = pos_v[0].split(',');
        if (pos.length > 0 && pos[0] === 'r') {
          pos = 'rack';
        } else if (pos.length === 2) {
          pos = [_i(pos[0]), _i(pos[1])];
        }
        op_letter = pos_v[1].split(',');
        if (pos.length > 0 && op_letter.length === 2) {
          return new_delta.push({
            op: op_letter[0],
            letter: op_letter[1],
            pos: pos
          });
        }
      }
    });
    log("got delta: ", delta);
    return new_delta;
  };
  _p_to_str = function(p) {
    if (p === 'rack') {
      return 'r';
    } else {
      return p.join(',');
    }
  };
  serialize_delta = function(delta) {
    return _.map(delta, function(e) {
      return "" + (_p_to_str(e.pos)) + ":" + e.op + "," + e.letter;
    }).join("|");
  };
  unused_letters = function(req_set, used_set) {
    var c;
    c = _.clone(used_set);
    return _.select(req_set, function(e) {
      var idx;
      if ((idx = _.indexOf(c, e)) > -1) {
        c.splice(idx, 1);
        return false;
      }
      return true;
    });
  };
  init_csrf = function() {
    window._settings.token = $('meta[name="csrf-token"]').attr('content');
    return $.ajaxSetup({
      beforeSend: function(xhr) {
        return xhr.setRequestHeader("X-CSRF-Token", _settings.token);
      },
      type: 'POST',
      data: {
        game_id: _settings.game_id
      }
    });
  };
  Chat = (function() {
    function Chat() {
      this.history = [];
      this.history_pos = 0;
      this.cur_message = "";
      $chat_input.keydown(__bind(function(e) {
        var c, msg;
        c = e.keyCode || e.which;
        if (c === 13) {
          msg = $chat_input.val();
          $.ajax({
            url: API_URL + 'chat',
            data: {
              message: msg
            }
          });
          log("sent chat msg of " + msg);
          new_message(msg, "you");
          this.history.unshift(msg);
          this.history_pos = 0;
          $chat_input.val('');
          return e.stopPropagation();
        } else if (c === 40) {
          if (this.history_pos > 0) {
            this.history_pos -= 1;
            if (this.history_pos > 0) {
              $chat_input.val(this.history[this.history_pos - 1]);
            } else {
              $chat_input.val(this.cur_message);
            }
          }
          return e.stopPropagation();
        } else if (c === 38) {
          if (this.history_pos < this.history.length) {
            if (this.history_pos === 0) {
              this.cur_message = $chat_input.val();
            }
            this.history_pos += 1;
            $chat_input.val(this.history[this.history_pos - 1]);
          }
          return e.stopPropagation();
        }
      }, this));
    }
    return Chat;
  })();
  ReadyBox = (function() {
    function ReadyBox() {
      log("on readybox", _settings.game_state, _settings.ready);
      if (_settings.game_state === 0 && _settings.ready === 0) {
        this.init_ready();
        $how_to_play.find('a').tooltip({
          relative: true,
          position: 'bottom center'
        });
        $how_to_play.overlay({
          top: 'center',
          oneInstance: true,
          closeOnClick: false,
          closeOnEsc: false,
          load: true,
          close: '#NOOP'
        });
      } else {
        this.is_ready();
        this.start();
      }
    }
    ReadyBox.prototype.init_ready = function() {
      log("init ready");
      $overlay.show();
      $game_status_wrapper.show();
      $ready.addClass('not_ready');
      $ready.removeAttr('disabled');
      $ready.html('ready');
      return $ready.click(__bind(function() {
        log("CLICK");
        if (!this.ready) {
          _settings.ready = 1;
          this.is_ready();
          return $.ajax({
            url: API_URL + 'ready',
            success: __bind(function(data) {
              return this.update_ready(data.ready, data.total);
            }, this)
          });
        }
      }, this));
    };
    ReadyBox.prototype.update_ready = function(ready, total) {
      $players_ready.html(ready);
      return $total_players.html(total);
    };
    ReadyBox.prototype.update_total = function(total) {
      return $total_players.html(total);
    };
    ReadyBox.prototype.is_ready = function() {
      $ready.attr('disabled', true);
      $ready.html('already ready');
      return $ready.removeClass('not_ready');
    };
    ReadyBox.prototype.start = function() {
      var htp;
      htp = $how_to_play.data('overlay');
      if (htp) {
        htp.close();
      }
      log("starting the game!");
      $overlay.hide();
      return $game_status_wrapper.hide();
    };
    return ReadyBox;
  })();
  PgramButton = (function() {
    function PgramButton() {}
    PgramButton.prototype.init = function(num_left, num_players) {
      var mt;
      this.num_players = num_players;
      log("init num_left ", num_left);
      this.is_bgram = false;
      mt = this.num_players * TILES_PER_PLAYER;
      this.total_tiles = mt < MIN_TILES ? MIN_TILES : mt;
      this.total_tiles -= this.num_players * INITIAL_TILES;
      log("total tiles", this.total_tiles);
      if (_i(num_left) > 0) {
        if (!$('#pgram_progress_str').length) {
          $pgramb.append("<div id='pgram_progress_str'>" + num_left + " left</div>");
        } else {
          $('#pgram_progress_str').show();
        }
      }
      return this.new_num_left(num_left);
    };
    PgramButton.prototype.new_num_left = function(num_left) {
      this.num_left = _i(num_left);
      if (this.num_left < this.num_players && !this.is_bgram) {
        $pgram_action.html('bgrams');
        $pgram_action.css({
          left: 5,
          top: 5
        });
        $pgramb.width(200);
        this.is_bgram = true;
        $progress.hide();
        return $('#pgram_progress_str').hide();
      } else {
        $('#pgram_progress_str').show();
        $('#pgram_progress_str').html("" + this.num_left + " left");
        return $progress.width("" + (Math.round(this.num_left / this.total_tiles * 100)) + "%");
      }
    };
    PgramButton.prototype.reset = function() {
      $pgram_action.html('peel');
      $pgram_action.css({
        left: 40,
        top: 0
      });
      $pgramb.width(180);
      return $('#pgram_progress_str').hide();
    };
    return PgramButton;
  })();
  Dump = (function() {
    function Dump(rack, board, pgram) {
      this.rack = rack;
      this.board = board;
      this.pgram = pgram;
      this.dump = $dump.droppable({
        accept: '.tile',
        drop: __bind(function(e, ui) {
          var tile;
          if ($(ui.draggable).hasClass('ui-multidraggable')) {
            show_notice('one at a time, please!', 'error');
            return false;
          }
          tile = $(ui.draggable).data('tile');
          if (tile.pos === 'rack') {
            this.rack.remove_tile(tile);
          } else {
            this.board.remove_tile_at_pos(tile.grid_pos());
          }
          log("wtf: ", $(tile.tile));
          $(ui.draggable).remove();
          $(ui.helper).hide();
          log("tile.tile", tile.tile);
          log("helper: ", $(ui.helper));
          log("e, ui", e, ui);
          window._cur_tiles[0].remove();
          log("dumped", tile);
          update_board('-', tile);
          if (!$dump.find('.loading').length) {
            $dump.append('<div class="loading"></div>');
          }
          return $.ajax({
            url: API_URL + 'dump',
            data: {
              letter: tile.letter
            },
            success: __bind(function(data) {
              $dump.find('.loading').remove();
              show_notice("dumped! got back " + (data.new_letters.join(', ')));
              log("got letters ", data, " num remain", data.num_remain);
              this.rack.add_letters(data.new_letters);
              return this.pgram.new_num_left(data.num_remain);
            }, this),
            error: __bind(function(data) {
              show_notice("wasn't able to dump! shit.", "error");
              return $dump.find('.loading').remove();
            }, this)
          });
        }, this)
      });
      disable_selection(this.dump);
    }
    return Dump;
  })();
  Tile = (function() {
    function Tile(letter, where, pos, tile_dim, board) {
      this.letter = letter;
      this.where = where;
      this.pos = pos;
      this.tile_dim = tile_dim;
      this.board = board;
      this.grid_pos = __bind(this.grid_pos, this);;
      this.append = __bind(this.append, this);;
      this.detach = __bind(this.detach, this);;
      this.remove = __bind(this.remove, this);;
      this.move = __bind(this.move, this);;
      this.tile = $("<div class='tile'><div class='letter'>" + this.letter + "</div></div>").data('letter', this.letter).data('tile', this);
      disable_selection(this.tile);
      this.tile.appendTo(this.where);
      this.returned = false;
      this.helper = null;
      this.dropped_to_board = false;
    }
    Tile.prototype.make_draggable = function() {
      var saved_this;
      if (this.tile.data('draggable')) {
        return this.tile.draggable('enable');
      } else {
        saved_this = this;
        return this.tile.multidraggable({
          appendTo: 'body',
          helper: 'clone',
          revert: 'invalid',
          zIndex: 2000,
          directionThreshold: TILE_DIM * 0.45,
          set_tile_group: __bind(function(e, direction) {
            var tiles;
            log("e: ", e);
            log("direction: ", direction);
            tiles = this.board.get_group_from_tile_and_direction(saved_this, direction);
            window._cur_tiles = tiles;
            log("tiles", tiles);
            return _.each(tiles, function(t) {
              log("added class: ", t.tile);
              return t.tile.addClass('ui-multidraggable');
            });
          }, this),
          start: function(e, o, multi) {
            log("STARTEDDRAG", e, o, multi);
            saved_this.in_progress = true;
            if (!$(this).hasClass('ui-multidraggable')) {
              window._cur_tiles = [saved_this];
            }
            log("set tiles!", window._cur_tiles);
            return $(this).toggle();
          },
          stop: function(e, ui) {
            saved_this.in_progress = false;
            log("STOPPEDDRAG");
            return $(this).toggle();
          }
        });
      }
    };
    Tile.prototype.make_undraggable = function() {
      log("disabling draggable!");
      this.tile.removeClass('ui-sortable-helper ui-draggable ui-draggable-helper ui-multidraggable');
      this.tile.draggable('destroy');
      this.tile.attr('style', '');
      return this.tile.css({
        position: '',
        left: 0,
        top: 0
      });
    };
    Tile.prototype.move = function(pos) {
      var left, top;
      if (pos == null) {
        pos = null;
      }
      if (pos) {
        top = this.tile_dim * (_i(pos[1]));
        left = this.tile_dim * (_i(pos[0]));
        this.pos = {
          top: top,
          left: left
        };
      }
      log("setting pos", this.pos);
      return this.tile.css({
        position: 'absolute',
        top: this.pos.top,
        left: this.pos.left
      });
    };
    Tile.prototype["return"] = function(animate) {
      if (animate == null) {
        animate = true;
      }
      log("returning!");
      if (this.pos !== 'rack') {
        return this.tile.css({
          top: this.pos.top,
          left: this.pos.left
        });
      }
    };
    Tile.prototype.remove = function() {
      this.where = null;
      if (this.tile.helper) {
        this.tile.helper.remove();
      }
      return this.tile.remove();
    };
    Tile.prototype.detach = function() {
      this.where = null;
      return this.tile.detach();
    };
    Tile.prototype.append = function(where) {
      log("appending to", where);
      this.where = where;
      this.tile.appendTo(this.where);
      return log("ahwat", this.tile);
    };
    Tile.prototype.get_draggable_pos = function() {
      var left, offset, pos, top;
      log("GETTING POS: ", this.tile, this.tile.data());
      if (this.tile.data('draggable')) {
        pos = this.tile.data('draggable').position;
      } else {
        pos = this.tile.offset();
      }
      offset = $board.offset();
      left = Math.round((pos.left + this.tile_dim / 4 - offset.left) / this.tile_dim - 0.5) * this.tile_dim;
      top = Math.round((pos.top - this.tile_dim / 2 - offset.top) / this.tile_dim + 0.5) * this.tile_dim;
      return [left / this.tile_dim, top / this.tile_dim];
    };
    Tile.prototype.grid_pos = function() {
      if (this.pos !== 'rack') {
        return [this.pos.left / TILE_DIM, this.pos.top / TILE_DIM];
      } else {
        return 'rack';
      }
    };
    return Tile;
  })();
  Rack = (function() {
    function Rack(board) {
      this.board = board;
      this.reset = __bind(this.reset, this);;
      this.init = __bind(this.init, this);;
      this.letters = [];
    }
    Rack.prototype.init = function(tiles) {
      log("got tiles ", tiles);
      return this.add_letters(tiles);
    };
    Rack.prototype.reset = function() {
      _.each(this.letters, function(e) {
        return e.remove();
      });
      return this.letters = [];
    };
    Rack.prototype.add_letters = function(letters) {
      log("add_letters ", letters);
      return _.each(letters, __bind(function(letter) {
        return this.letters.push(new Tile(letter, this.rack, 'rack', TILE_DIM, this.board));
      }, this));
    };
    Rack.prototype.add_tile = function(tile) {
      return this.letters.push(tile);
    };
    Rack.prototype.remove_letter = function(letter) {
      var idx, l;
      idx = -1;
      _.each(this.letters, function(t, i) {
        if (t.letter === letter) {
          return idx = i;
        }
      });
      if (idx > -1) {
        l = this.letters.splice(idx, 1);
      }
      log("SPLICE: ", l);
      if (l && l.length > 0) {
        return l[0].remove();
      }
    };
    Rack.prototype.move_tile_to_board = function(tile) {
      if (this.remove_tile(tile)) {
        tile.make_draggable();
        tile.tile.toggle();
        return _.defer(function() {
          tile.tile.toggle();
          tile.append($board);
          return tile.move();
        });
      }
    };
    Rack.prototype.move_tile_to_rack = function(tile) {
      if (this.letters.indexOf(tile) === -1) {
        update_board('-', tile);
        tile.pos = 'rack';
        update_board('+', tile);
        this.add_tile(tile);
        return tile.make_undraggable();
      }
    };
    Rack.prototype.remove_tile = function(tile) {
      var idx;
      if ((idx = this.letters.indexOf(tile)) > -1) {
        this.letters.splice(idx, 1);
        return true;
      }
      return false;
    };
    return Rack;
  })();
  UserRack = (function() {
    __extends(UserRack, Rack);
    function UserRack() {
      UserRack.__super__.constructor.apply(this, arguments);
      this.rack = $rack.sortable({
        appendTo: 'body',
        start: __bind(function(e, ui) {
          var tile;
          log("draggable", $(ui.draggable));
          tile = get_tile_from_ui(ui);
          log("tile START", tile, window._cur_tiles);
          if (tile) {
            window._cur_tiles = [tile];
          }
          return tile.in_progress = true;
        }, this),
        stop: __bind(function(e, ui) {
          var tile;
          tile = window._cur_tiles[0];
          log("STOP");
          if (tile && tile.dropped_to_board && !tile.returned) {
            log("moving tile to board");
            this.move_tile_to_board(tile);
          }
          if (tile) {
            tile.returned = false;
            tile.dropped_to_board = false;
            return tile.over_board = false;
          }
        }, this)
      });
      disable_selection(this.rack);
    }
    return UserRack;
  })();
  PlayerRack = (function() {
    __extends(PlayerRack, Rack);
    function PlayerRack(rack) {
      this.rack = rack;
      PlayerRack.__super__.constructor.apply(this, arguments);
    }
    return PlayerRack;
  })();
  EndOfGame = (function() {
    function EndOfGame() {
      this.start = __bind(this.start, this);;      this.in_end = false;
    }
    EndOfGame.prototype.end = function(players, user_board, user_won, user_id) {
      var player_obj, winner;
      log("end of game!", this.players, user_board, user_won);
      this.in_end = true;
      this.overlay = $("<div id='winner_overlay'></div>").appendTo('body');
      player_obj = {
        board: user_board,
        won: user_won,
        id: user_id,
        name: 'You'
      };
      players.push(player_obj);
      winner = {};
      _.each(players, function(e) {
        if (e.won) {
          return winner = e;
        }
      });
      this.overlay.append("<div class='name_wrapper'><span class='big name'>" + winner.name + " won!</span></div>                     <div class='names name_wrapper'></div><div class='board_wrapper'></div>");
      _.each(players, __bind(function(p, idx) {
        var board, board_div, cleaned_board, link;
        log("processing player: ", p);
        link = $("<a class='" + (p.won ? 'winner selected ' : '') + "name' href='#'>" + p.name + "</a>").click(__bind(function(e) {
          this.load_board(p.id);
          this.overlay.find('.names .name').removeClass('selected');
          $(e.target).addClass('selected');
          return e.preventDefault();
        }, this));
        this.overlay.find('.names').append(link);
        log("link: ", link);
        board_div = $("<div class='board' id='end_player_board_" + p.id + "'></div>");
        board = new Board(board_div, WINNER_TILE_DIM, WINNER_BOARD_DIM, true);
        log("using board: ", p.board);
        cleaned_board = {};
        _.each(p.board, function(v, k) {
          return cleaned_board[k] = v.letter;
        });
        board.initial_board_state(cleaned_board);
        log("initial board", board);
        log("board.board", board_div);
        board_div.appendTo(this.overlay.find('.board_wrapper'));
        return delete board;
      }, this));
      this.overlay.find('.board').draggable();
      this.load_board(winner.id);
      return this.overlay.overlay({
        top: 109,
        oneInstance: true,
        closeOnClick: false,
        closeOnEsc: false,
        load: true,
        close: '#NOOP'
      });
    };
    EndOfGame.prototype.start = function() {
      var htp;
      if (this.in_end) {
        htp = this.overlay.data('overlay');
        if (htp) {
          htp.close();
        }
        log("starting the game!");
        this.overlay.remove();
        return this.in_end = false;
      }
    };
    EndOfGame.prototype.load_board = function(id) {
      log("loading board: ", id);
      this.overlay.find('.board').hide();
      return $("#end_player_board_" + id).show();
    };
    return EndOfGame;
  })();
  Board = (function() {
    function Board(board, tile_dim, board_dim, miniboard) {
      this.board = board;
      this.tile_dim = tile_dim;
      this.board_dim = board_dim;
      this.miniboard = miniboard != null ? miniboard : false;
      this.lift_tile = __bind(this.lift_tile, this);;
      this.check_tile_move = __bind(this.check_tile_move, this);;
      this.add_letter_at_pos = __bind(this.add_letter_at_pos, this);;
      this.adjust_center = __bind(this.adjust_center, this);;
      this.reset = __bind(this.reset, this);;
      this.reset();
    }
    Board.prototype.reset = function() {
      this.center = {
        top: -1,
        left: -1
      };
      if (!_.isEmpty(this.board_state)) {
        _.each(this.board_state, function(v, k) {
          return v.remove();
        });
      }
      this.board_state = {};
      return this.move_to_center();
    };
    Board.prototype.move_to_center = function() {
      return this.board.css({
        top: -this.board_dim / 2 + $(window).height() / 2,
        left: -this.board_dim / 2 + $(window).width() / 2
      });
    };
    Board.prototype.adjust_center = function(pos, initial, adjust, animate) {
      var css_pos, left, top;
      if (initial == null) {
        initial = false;
      }
      if (adjust == null) {
        adjust = true;
      }
      if (animate == null) {
        animate = true;
      }
      if (adjust) {
        if (this.center.top === -1) {
          this.center.top = -pos[1] * this.tile_dim;
          this.center.left = -pos[0] * this.tile_dim;
        } else {
          this.center.top = (this.center.top - pos[1] * this.tile_dim) / 2;
          this.center.left = (this.center.left - pos[0] * this.tile_dim) / 2;
          if (!this.miniboard) {
            this.center.top -= $(window).height() / 2;
            this.center.left -= $(window).width() / 2 - 400;
          }
        }
      }
      log("CENTER", this.center);
      if (_.isArray(this.board_dim)) {
        left = this.board_dim[0] / 2;
        top = this.board_dim[1] / 2;
      } else {
        left = this.board_dim / 2;
        top = this.board_dim / 2;
      }
      if (!initial) {
        css_pos = {
          top: Math.round(this.center.top + top),
          left: Math.round(this.center.left + left)
        };
        if (adjust && animate) {
          return this.board.animate(css_pos, 'slow');
        } else {
          return this.board.css(css_pos);
        }
      }
    };
    Board.prototype.initial_board_state = function(board_state) {
      var do_adjust;
      log("loading board state", board_state);
      do_adjust = false;
      log("bs ", board_state);
      _.each(board_state, __bind(function(letter, pos) {
        this.add_letter_at_pos(letter, _pos(pos), true);
        return do_adjust = true;
      }, this));
      if (do_adjust) {
        return this.adjust_center(null, false, false);
      }
    };
    Board.prototype.add_letter_at_pos = function(letter, pos, initial, animate) {
      if (initial == null) {
        initial = false;
      }
      if (animate == null) {
        animate = true;
      }
      log("adding ", letter, " at ", pos);
      this.board_state[pos] = new Tile(letter, this.board, pos, this.tile_dim, this);
      this.board_state[pos].move(pos);
      if (!this.miniboard) {
        this.board_state[pos].make_draggable();
      }
      return this.adjust_center(pos, initial, true, animate);
    };
    Board.prototype.check_tile_move = function(tile) {
      var gp, pos, valid_pos, _ref, _ref2;
      pos = tile.get_draggable_pos();
      gp = tile.grid_pos();
      log("gp", gp, " pos", pos);
      valid_pos = ((0 <= (_ref = pos[0]) && _ref <= NUM_TILES_PER_SIDE)) && ((0 <= (_ref2 = pos[1]) && _ref2 <= NUM_TILES_PER_SIDE));
      log("COND1: ", !this.board_state[pos] && valid_pos);
      log("COND2: ", valid_pos && this.board_state[pos] && _.indexOf(window._cur_tiles, this.board_state[pos]) > -1);
      if ((!this.board_state[pos] && valid_pos) || (valid_pos && this.board_state[pos] && _.indexOf(window._cur_tiles, this.board_state[pos]) > -1)) {
        return true;
      } else {
        return false;
      }
    };
    Board.prototype.return_tile = function(tile) {
      if (tile.pos === 'rack') {
        tile.returned = true;
        return tile.dropped_to_board = false;
      } else {
        return tile["return"]();
      }
    };
    Board.prototype.lift_tile = function(tile) {
      var gp, pos;
      pos = tile.get_draggable_pos();
      gp = tile.grid_pos();
      if (this.board_state[gp] && this.board_state[gp] === tile) {
        delete this.board_state[gp];
      }
      this.board_state[pos] = tile;
      update_board('-', tile);
      return tile.move(pos);
    };
    Board.prototype.place_tile = function(tile) {
      return update_board('+', tile);
    };
    Board.prototype.remove_tile_at_pos = function(pos) {
      if (this.board_state[pos]) {
        this.board_state[pos].remove();
        return delete this.board_state[pos];
      }
    };
    return Board;
  })();
  UserBoard = (function() {
    __extends(UserBoard, Board);
    function UserBoard() {
      this._send_update = __bind(this._send_update, this);;
      this.get_and_clear_queue = __bind(this.get_and_clear_queue, this);;
      this._opposite_fns = __bind(this._opposite_fns, this);;
      this._west = __bind(this._west, this);;
      this._south = __bind(this._south, this);;
      this._east = __bind(this._east, this);;
      this._north = __bind(this._north, this);;
      this._get_adjacent_contiguous_tiles = __bind(this._get_adjacent_contiguous_tiles, this);;
      this.get_group_from_tile_and_direction = __bind(this.get_group_from_tile_and_direction, this);;
      this.the_board = __bind(this.the_board, this);;
      this.rack_letters = __bind(this.rack_letters, this);;
      this.update_board = __bind(this.update_board, this);;
      this.reset = __bind(this.reset, this);;      log("making userboard");
      this.board = $board.draggable();
      $board_wrapper.droppable({
        appendTo: '#content',
        accept: '.tile',
        drop: __bind(function(e, ui) {
          var good, one_in_progress;
          good = true;
          one_in_progress = false;
          _.each(window._cur_tiles, __bind(function(tile) {
            if (tile.in_progress) {
              one_in_progress = true;
              tile.dropped_to_board = true;
              tile.in_progress = false;
              if (good && !this.check_tile_move(tile)) {
                return good = false;
              }
            }
          }, this));
          if (good && one_in_progress) {
            _.each(window._cur_tiles, __bind(function(tile) {
              return this.lift_tile(tile);
            }, this));
            _.each(window._cur_tiles, __bind(function(tile) {
              return this.place_tile(tile);
            }, this));
          } else if (!good && one_in_progress) {
            _.each(window._cur_tiles, __bind(function(tile) {
              return this.return_tile(tile);
            }, this));
          }
          return e.stopImmediatePropagation();
        }, this)
      });
      disable_selection(this.board);
      UserBoard.__super__.constructor.call(this, this.board, TILE_DIM, BOARD_DIM);
      this.update_queue = [];
      this.send_update = _.throttle((__bind(function() {
        return _.delay(this._send_update, UPDATE_DELAY);
      }, this)), UPDATE_INTERVAL);
      $pubsub.bind('update_board', this.update_board);
    }
    UserBoard.prototype.reset = function() {
      UserBoard.__super__.reset.apply(this, arguments);
      return this.update_queue = [];
    };
    UserBoard.prototype.update_board = function(e, op, tile) {
      log("update board: ", tile);
      this.update_queue.push({
        op: op,
        pos: tile.grid_pos(),
        letter: tile.letter
      });
      return this.send_update();
    };
    UserBoard.prototype.rack_letters = function(inc_letters) {
      log("values: ", _.values(this.board_state).map(function(e) {
        return e.letter;
      }));
      return unused_letters(inc_letters, _.values(this.board_state).map(function(e) {
        return e.letter;
      }));
    };
    UserBoard.prototype.the_board = function() {
      return serialize_board(this.board_state);
    };
    UserBoard.prototype.get_group_from_tile_and_direction = function(tile, direction) {
      var gp, neighbors, skip_tiles, tiles;
      gp = tile.grid_pos();
      neighbors = [];
      _.each([this._north, this._east, this._south, this._west], __bind(function(f) {
        var t;
        t = f(gp);
        if (t) {
          return neighbors.push(t);
        }
      }, this));
      log("neighbors ", neighbors);
      skip_tiles = [];
      log("direction", direction);
      _.each(direction, __bind(function(e) {
        var t;
        t = this._opposite_fns(e)(gp);
        log("t", t, "e", e);
        if (t) {
          if (!(neighbors.length === 1 && neighbors[0] === t)) {
            return skip_tiles.push(t);
          }
        }
      }, this));
      log("skips", _.clone(skip_tiles));
      tiles = [];
      this._get_adjacent_contiguous_tiles(tile, tiles, skip_tiles);
      return tiles;
    };
    UserBoard.prototype._get_adjacent_contiguous_tiles = function(tile, tiles, skip_tiles, skip_tile_recurse) {
      if (skip_tile_recurse == null) {
        skip_tile_recurse = false;
      }
      if (!(tile && _.indexOf(tiles, tile) === -1 && _.indexOf(skip_tiles, tile) === -1)) {
        return;
      }
      if (skip_tile_recurse) {
        skip_tiles.push(tile);
      } else {
        tiles.push(tile);
      }
      if (!skip_tile_recurse) {
        return _.each([this._north, this._east, this._south, this._west], __bind(function(f) {
          _.each(skip_tiles.slice(-4), __bind(function(st) {
            if (st) {
              return this._get_adjacent_contiguous_tiles(f(st.grid_pos()), tiles, skip_tiles, true);
            }
          }, this));
          return this._get_adjacent_contiguous_tiles(f(tile.grid_pos()), tiles, skip_tiles);
        }, this));
      }
    };
    UserBoard.prototype._north = function(gp) {
      return this.board_state[[gp[0], gp[1] - 1]];
    };
    UserBoard.prototype._east = function(gp) {
      return this.board_state[[gp[0] + 1, gp[1]]];
    };
    UserBoard.prototype._south = function(gp) {
      return this.board_state[[gp[0], gp[1] + 1]];
    };
    UserBoard.prototype._west = function(gp) {
      return this.board_state[[gp[0] - 1, gp[1]]];
    };
    UserBoard.prototype._opposite_fns = function(direction) {
      switch (direction) {
        case 'n':
          return this._south;
        case 's':
          return this._north;
        case 'e':
          return this._west;
        case 'w':
          return this._east;
      }
    };
    UserBoard.prototype.get_and_clear_queue = function() {
      var q;
      q = this.update_queue;
      this.update_queue = [];
      return q;
    };
    UserBoard.prototype._send_update = function(async) {
      if (async == null) {
        async = true;
      }
      if (!_.isEmpty(this.update_queue)) {
        log("sending update: ", serialize_delta(this.update_queue));
        $.ajax({
          async: async,
          url: API_URL + 'update_board',
          data: {
            delta: serialize_delta(this.update_queue)
          }
        });
        this.update_queue = [];
        return log("board state: ", this.board_state);
      }
    };
    return UserBoard;
  })();
  Player = (function() {
    function Player(name) {
      var where;
      this.name = name;
      this.remove = __bind(this.remove, this);;
      this.offline = __bind(this.offline, this);;
      this.online = __bind(this.online, this);;
      this.add_tile = __bind(this.add_tile, this);;
      this.delete_tile = __bind(this.delete_tile, this);;
      this.handle_delta = __bind(this.handle_delta, this);;
      this.action = __bind(this.action, this);;
      this.init = __bind(this.init, this);;
      log("adding " + this.name);
      if ($left_players.find('.player').length < NUM_PLAYERS_ON_SIDE) {
        where = $left_players;
      } else {
        where = $right_players;
      }
      log("adding player to", where);
      this.player = $("<div class='player'><div class='name_wrapper'><span class='name'>" + this.name + "</span></div>                 <div class='board_wrapper'><div class='board'></div></div>                 <div class='letter_wrapper'><div class='letters'></div></div></div>").appendTo(where);
      disable_selection(this.player);
      this.name_div = this.player.find('.name');
      this.rack = new PlayerRack(this.player.find('.letters'));
      log("PASSING BOARD", this.player.find('.board'));
      this.board = new Board(this.player.find('.board'), PLAYER_TILE_DIM, PLAYER_BOARD_DIM, true);
      this.did_init = false;
      this.is_online = true;
    }
    Player.prototype.reset = function() {
      this.rack.reset();
      this.board.reset();
      return this.did_init = false;
    };
    Player.prototype.init = function(letters, board_state) {
      var l;
      if (board_state) {
        l = unused_letters(letters, _.values(board_state));
      } else {
        l = letters;
      }
      log("HERE", l, " bs", board_state);
      this.rack.add_letters(l);
      if (board_state) {
        this.board.initial_board_state(board_state, false);
      }
      return this.did_init = true;
    };
    Player.prototype.action = function(text) {
      var pos;
      pos = this.player.offset();
      pos.left += 15;
      pos.top += this.player.height() / 2;
      return text_effect(text, pos);
    };
    Player.prototype.handle_delta = function(delta) {
      var animate;
      log("got delta ", delta);
      animate = delta.length < 5;
      return _.each(delta, __bind(function(e) {
        switch (e.op) {
          case '+':
            return this.add_tile(e.pos, e.letter, animate);
          case '-':
            return this.delete_tile(e.pos, e.letter);
        }
      }, this));
    };
    Player.prototype.delete_tile = function(pos, letter) {
      if (pos === 'rack' || pos === 'r') {
        return this.rack.remove_letter(letter);
      } else {
        return this.board.remove_tile_at_pos(pos);
      }
    };
    Player.prototype.add_tile = function(pos, letter, animate) {
      if (animate == null) {
        animate = true;
      }
      if (pos === 'rack' || pos === 'r') {
        return this.rack.add_letters([letter]);
      } else {
        return this.board.add_letter_at_pos(letter, pos, false, animate);
      }
    };
    Player.prototype.online = function() {
      log("" + this.name + " is online!");
      show_notice("" + this.name + " has joined the game");
      this.name_div.addClass('online');
      return this.is_online = true;
    };
    Player.prototype.offline = function() {
      log("" + this.name + " is offline :(");
      show_notice("" + this.name + " has left the game");
      this.name_div.removeClass('online');
      return this.is_online = false;
    };
    Player.prototype.remove = function() {
      log("deleting player!");
      return this.player.remove();
    };
    return Player;
  })();
  Game = (function() {
    function Game() {
      this.add_player = __bind(this.add_player, this);;
      this.handle_member_removed = __bind(this.handle_member_removed, this);;
      this.handle_member_added = __bind(this.handle_member_added, this);;
      this.handle_online = __bind(this.handle_online, this);;
      this.handle_dump = __bind(this.handle_dump, this);;
      this.handle_chat = __bind(this.handle_chat, this);;
      this.handle_joined = __bind(this.handle_joined, this);;
      this.handle_bgram = __bind(this.handle_bgram, this);;
      this.handle_start = __bind(this.handle_start, this);;
      this.handle_peel = __bind(this.handle_peel, this);;
      this._add_tiles_for_players = __bind(this._add_tiles_for_players, this);;
      this.handle_update = __bind(this.handle_update, this);;
      this.handle_ready = __bind(this.handle_ready, this);;
      this.enable_interactions = __bind(this.enable_interactions, this);;
      this.start = __bind(this.start, this);;      log("constructing game");
      if (!_settings.logged_in) {
        log("not logged in, booting to login overlay");
        open_login_overlay(true, "gotta sign in to play");
        return;
      }
      this.player_id = _settings.player_id;
      this.players = {};
      init_csrf();
      this.chat = new Chat();
      this.board = new UserBoard();
      this.rack = new UserRack(this.board);
      this.pgram = new PgramButton();
      this.dump = new Dump(this.rack, this.board, this.pgram);
      this.ready_box = new ReadyBox();
      this.end_of_game = new EndOfGame();
      this.connect_to_pusher();
    }
    Game.prototype.connect_to_pusher = function() {
      Pusher.log = log;
      Pusher.channel_auth_endpoint = API_URL + 'pusher_auth';
      Pusher.csrf_token = _settings.token;
      this.pusher = new Pusher(_settings.api_key);
      this.pusher.subscribe(_settings.channel).bind('update', this.handle_update).bind('chat', this.handle_chat).bind('joined', this.handle_joined).bind('dump', this.handle_dump).bind('peel', this.handle_peel).bind('bgrams', this.handle_bgram).bind('start', this.handle_start).bind('player_ready', this.handle_ready).bind('update_lobby', this.handle_lobby_update).bind('pusher:subscription_succeeded', this.handle_online).bind('pusher:member_added', this.handle_member_added).bind('pusher:member_removed', this.handle_member_removed);
      return this.pusher.bind('pusher:connection_established', __bind(function(e) {
        $.ajaxSetup({
          data: {
            socket_id: e.socket_id,
            game_id: _settings.game_id
          }
        });
        if (_settings.game_state !== 0) {
          this.load_game();
        }
        return $(window).unload(__bind(function() {
          return this.board._send_update(false);
        }, this));
      }, this));
    };
    Game.prototype.load_game = function(data) {
      return $.ajax({
        url: API_URL + 'load_game',
        data: {
          game_id: _settings.game_id
        },
        error: __bind(function(data) {
          return msg_notice("unable to load game. error: " + (response_text(data.responseText)), "error");
        }, this),
        success: __bind(function(data) {
          var inc_playerid, rl;
          msg_notice("connected to the game!", "success");
          log("load_game: ", data);
          inc_playerid = data.id;
          if (inc_playerid !== this.player_id) {
            show_notice("failed consistency check! damn.", "error");
            return;
          }
          this.player_id = inc_playerid;
          this.board.initial_board_state(unserialize_board(data.board));
          rl = this.board.rack_letters(data.letters);
          log("rack letters", rl, " letters", data.letters);
          this.rack.add_letters(this.board.rack_letters(data.letters));
          log("loaded pgram", data.num_remain, data.players.length);
          this.pgram.init(data.num_remain, data.players.length + 1);
          _.each(data.players, __bind(function(e) {
            return this.add_player(e);
          }, this));
          return this.start();
        }, this)
      });
    };
    Game.prototype.start = function() {
      _settings.game_state = 1;
      this.ready_box.start();
      this.end_of_game.start();
      return this.enable_interactions();
    };
    Game.prototype.enable_interactions = function() {
      disable_selection($pgram_action);
      $pgramb.removeClass('disabled');
      return $pgramb.click(__bind(function(e) {
        var action;
        if ($pgramb.find('.loading').length) {
          return;
        }
        if (this.rack.letters.length > 0) {
          show_notice("you still have letters remaining in your rack!", "error");
          return;
        }
        log("about to send for pgram: ", this.board.the_board());
        action = this.pgram.is_bgram ? 'bgram' : 'peel';
        $pgramb.append('<div class="loading"></div>');
        $pgramb.addClass('disabled');
        return $.ajax({
          url: API_URL + 'pgram',
          data: {
            delta: serialize_delta(this.board.get_and_clear_queue())
          },
          success: __bind(function(data) {
            $pgramb.find('.loading').remove();
            $pgramb.removeClass('disabled');
            this.pgram.new_num_left(data.num_remain);
            if (action === 'peel') {
              this._add_tiles_for_players(data.new_letters);
              return show_notice("peel successful!", "success");
            } else {
              return this.handle_win(this.player_id);
            }
          }, this),
          error: __bind(function(data) {
            $pgramb.find('.loading').remove();
            $pgramb.removeClass('disabled');
            log("failed! ", data.responseText);
            return msg_notice("" + action + " failed. error: " + (response_text(data.responseText)), "error");
          }, this)
        });
      }, this));
    };
    Game.prototype.handle_ready = function(data) {
      var _ref;
      this.ready_box.update_ready(data.ready, data.total);
      if (data.player !== this.player_id) {
        return msg_notice("" + ((_ref = this.players[data.player]) != null ? _ref.name : void 0) + " is ready!");
      }
    };
    Game.prototype.handle_update = function(data) {
      log("update", data);
      return this.players[data.player].handle_delta(unserialize_delta(data.delta));
    };
    Game.prototype._add_tiles_for_players = function(tiles) {
      log("adding tiles", tiles);
      return _.each(tiles, __bind(function(v, k) {
        var _ref;
        log("adding stuff for player: ", k, " me: ", this.player_id);
        if (k === this.player_id) {
          return this.rack.add_letters(v);
        } else {
          return (_ref = this.players[k]) != null ? _ref.rack.add_letters(v) : void 0;
        }
      }, this));
    };
    Game.prototype.handle_peel = function(data) {
      var _ref;
      log("got peel", data);
      if (data.player !== this.player_id) {
        this.players[data.player].action("peel");
        this.pgram.new_num_left(data.num_remain);
        msg_notice("" + ((_ref = this.players[data.player]) != null ? _ref.name : void 0) + " just peeled!");
        return this._add_tiles_for_players(data.new_tiles);
      }
    };
    Game.prototype.handle_start = function(data) {
      this.pgram.init(data.num_remain, (_.keys(this.players).length) + 1);
      this._add_tiles_for_players(data.initial_tiles);
      this.start();
      return msg_notice("game started!", "success");
    };
    Game.prototype.handle_bgram = function(data) {
      log("handle_bgram ", data);
      if (data.player !== this.player_id) {
        msg_notice("" + this.players[data.player].name + " just did bgrams, game over :-(");
        return this.handle_win(data.player);
      }
    };
    Game.prototype.handle_joined = function(data) {
      this.add_player(data);
      return this.ready_box.update_ready(data.ready, data.total);
    };
    Game.prototype.handle_chat = function(data) {
      var _ref;
      if (data.player !== this.player_id) {
        return new_message(data.message, (_ref = this.players[data.player]) != null ? _ref.name : void 0);
      }
    };
    Game.prototype.handle_dump = function(data) {
      log("DUMP", data);
      this.pgram.new_num_left(_i(data.num_remain));
      if (data.player !== this.player_id) {
        this.players[data.player].action("dump");
        return this.players[data.player].rack.add_letters(data.letters);
      }
    };
    Game.prototype.handle_online = function(members) {
      log("other dudes in this game ", members);
      _.each(members, __bind(function(member, k) {
        var _ref;
        return (_ref = this.add_player(member)) != null ? _ref.online() : void 0;
      }, this));
      if (_settings.game_state === 0) {
        log("handling online", _.map(members, function(e) {
          return e.user_id;
        }));
        return $.ajax({
          url: API_URL + 'update_lobby',
          data: {
            players: _.map(members, function(e) {
              return e.user_id;
            })
          }
        });
      }
    };
    Game.prototype.handle_member_added = function(member) {
      var _ref;
      log("player " + member.user_id + " online");
      if ((_ref = this.add_player(member)) != null) {
        _ref.online();
      }
      if (_settings.game_state === 0) {
        return $.ajax({
          url: API_URL + 'add_to_lobby',
          data: {
            player: member.user_id
          }
        });
      }
    };
    Game.prototype.handle_member_removed = function(member) {
      var _ref, _ref2;
      log("player " + member.user_id + " offline");
      if (_settings.game_state === 0) {
        if ((_ref = this.players[member.user_id]) != null) {
          _ref.remove();
        }
        delete this.players[member.user_id];
        this.ready_box.update_total(_.keys(this.players).length + 1);
      } else {
        if ((_ref2 = this.players[member.user_id]) != null) {
          _ref2.offline();
        }
      }
      if (_settings.game_state === 0) {
        return $.ajax({
          url: API_URL + 'remove_from_lobby',
          data: {
            player: member.user_id
          }
        });
      }
    };
    Game.prototype.add_player = function(data) {
      if (!data.id) {
        data.id = data.user_id;
      }
      if (data.id === this.player_id) {
        return;
      }
      if (!this.players[data.id]) {
        log("adding player", data.name);
        this.players[data.id] = new Player(data.name);
      }
      if ((data.letters || data.board) && !this.players[data.id].did_init) {
        log("adding letters", data.letters, " board", data.board);
        this.players[data.id].init(data.letters, unserialize_board(data.board));
      }
      return this.players[data.id];
    };
    Game.prototype.handle_win = function(player_id) {
      var players;
      players = [];
      _.each(this.players, function(v, k) {
        players.push({
          name: v.name,
          board: v.board.board_state,
          id: k,
          won: k === player_id
        });
        return v.reset();
      });
      log("end of game", players, this.board, player_id === this.player_id, this.board.the_board(), this.board.board_state);
      this.end_of_game.end(players, this.board.board_state, player_id === this.player_id, this.player_id);
      _settings.ready = 0;
      _settings.game_state = 0;
      this.ready_box.update_ready(0, this.players.length);
      this.ready_box.init_ready();
      _.each(this.players, __bind(function(v, k) {
        if (!v.is_online) {
          v.remove();
        }
        if (!v.is_online) {
          return delete this.players[k];
        }
      }, this));
      this.board.reset();
      this.rack.reset();
      return this.pgram.reset();
    };
    return Game;
  })();
  $(function() {
    return _.defer(function() {
      common_init();
      return new Game;
    });
  });
}).call(this);
