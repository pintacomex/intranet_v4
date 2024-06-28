class Taskuser < ActiveRecord::Base
	validates_uniqueness_of :id_user, scope: :id_task
	attr_accessible :id_task, :id_user, :fecha_inicio, :fecha_limite, :creado_por, :fecha_termina, :porc_terminado, :fecha_procesado
end
