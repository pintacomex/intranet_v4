class Task < ActiveRecord::Base
	attr_accessible :task_id, :descripcion
	validates :descripcion, presence: true 
end
