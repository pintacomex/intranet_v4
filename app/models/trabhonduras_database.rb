class TrabhondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "trabhonduras"
end