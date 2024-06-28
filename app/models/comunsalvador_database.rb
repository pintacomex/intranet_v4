class ComunsalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :comunsalvador
end