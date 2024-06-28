class FacelesalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "facelesalvador"
end