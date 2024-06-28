class TrabbeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "trabbelice"
end