class FacelebeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "facelebelice"
end