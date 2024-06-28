class PdvhondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :pdvhonduras
end