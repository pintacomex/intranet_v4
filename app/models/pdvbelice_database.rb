class PdvbeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :pdvbelice
end