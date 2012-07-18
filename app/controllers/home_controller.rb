class HomeController < ApplicationController
  before_filter :authenticate_player!, :only => [:new_private_game]
  
  def index
    the_games = Game.where(:state => Game::WAITING_FOR_START, :dirty => false, 
                           :private => false, :created_at.gte => (Time.now.utc - 1.hour)).desc(:short_id).limit(15)
    @games = []
    has_empty = false
    
    the_games.each do |g|
      np = g.lobby_players.length
      @games.push({ :game => g, :players => np })
      has_empty = true if np == 0
    end
    
    unless has_empty
      g = Game.create!
      @games.unshift({ :game => g, :players => 0})
    end
    
    if player_signed_in?
      #@your_games = current_player.player_session_ids.where(:state => Game::IN_PROGRESS)
    end
  end
  
  def new_private_game
    g = Game.create!(:private => true)
    redirect_to "/play/#{g.id.to_s}"
  end
end
