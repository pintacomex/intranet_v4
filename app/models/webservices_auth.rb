class WebservicesAuth < ActiveRecord::Base
  attr_accessible :sucursal, :pc, :numAuth, :descripcion, :respuesta, :status, :fechaHora, :nivel, :empresa
end
