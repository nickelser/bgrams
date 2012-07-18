Bgrams::Application.routes.draw do
  root :to => 'home#index'
  match 'play/:id' => 'game#play', :as => :join_game
  match 'private_game' => 'home#new_private_game', :as => :new_private_game
  match '/game/:action', :controller => :game, :as => :game
  devise_for :players, :controllers => { :sessions => "players/sessions", 
                                         :registrations => "players/registrations",
                                         :omniauth_callbacks => "players/omniauth_callbacks" }
  
  devise_scope :player do
    get "/login" => "devise/sessions#new"
    get "/logout" => "devise/sessions#destroy"
  end
end
