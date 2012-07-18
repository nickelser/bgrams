class Player
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, #:token_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :fb_id
  validates_uniqueness_of :fb_id, :allow_blank => true, :allow_nil => true
  validates_format_of :username, :with => /^\w+$/i
  validates_uniqueness_of :username, :case_sensitive => false
  validates :username, :presence => true, :length => { :within => 4..22 }
  
  #references_many :player_sessions, :inverse_of => :player, :index => true
  # bleh?
  field :player_session_ids, :type => Array, :default => []
  field :username
  field :email
  field :current_sign_in_at, :type => Time
  field :current_sign_in_ip
  field :encrypted_password
  field :fb_id
  field :last_sign_in_at, :type => Time
  field :last_sign_in_ip
  field :remember_created_at, :type => Time
  field :remember_token
  field :reset_password_token
  field :sign_in_count, :type => Integer, :default => 0
  field :updated_at, :type => Time
  
  def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
    data = access_token['extra']['user_hash']
    Rails.logger.info "got back: "+data.inspect
    if player = Player.where(:fb_id => data["id"]).first
      player
    else # Create an user with a stub password
      Player.create!(:username => data['name'].gsub(/[^\w]/, ''), :password => Devise.friendly_token[0,20], :fb_id => data["id"])
    end
  end
  
  protected
  
  def email_required?
    false
  end
end
