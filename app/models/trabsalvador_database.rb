class TrabsalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :trabsalvador
end