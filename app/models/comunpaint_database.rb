class ComunpaintDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "comunpaint"
end