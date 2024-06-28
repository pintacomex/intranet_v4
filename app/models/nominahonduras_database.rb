class NominahondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominahonduras"
end