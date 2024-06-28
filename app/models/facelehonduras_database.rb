class FacelehondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "facelehonduras"
end