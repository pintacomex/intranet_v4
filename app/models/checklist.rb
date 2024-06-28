class Checklist < ActiveRecord::Base
  attr_accessible :nombre, :status

  STATUS = { 'Inactivo' => 0, 'Activo' => 1 }
end
