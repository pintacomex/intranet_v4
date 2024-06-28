class AuthLog < ActiveRecord::Base
  attr_accessible :empresa, :sucursal, :pc, :numAuth, :nivel, :fechaHora, :descripcion, :status, :respuesta, :pdvPrueba
end
