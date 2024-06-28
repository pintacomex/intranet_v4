class ChecklistItem < ActiveRecord::Base
  attr_accessible :checklist_id, :texto, :orden, :status

  STATUS = { 'Inactivo' => 0, 'Activo' => 1 }

end
