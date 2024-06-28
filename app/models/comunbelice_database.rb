class ComunbeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "comunbelice"
end