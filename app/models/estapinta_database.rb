class EstapintaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "estapinta"
end