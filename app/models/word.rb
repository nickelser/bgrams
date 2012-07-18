class Word
  include Mongoid::Document
  
  field :word
  index :word, :unique => true
end
