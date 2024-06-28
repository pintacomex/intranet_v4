class ComunhondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "comunhonduras"
end