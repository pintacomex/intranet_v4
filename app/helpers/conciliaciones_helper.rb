module ConciliacionesHelper
  def getTipoConc(t)
  	if t == 'F'
  	  'Factura'
  	elsif t == 'N'
  	  'Nómina'
  	else
  	  'Sin Tipo'
  	end
  end
   def getStatusConc(s)
  	if s == 'A'
  	  'Activo'
  	elsif s == 'C'
  	  'Cancelado'
  	else
  	  'Sin Status'
  	end
  end
   def getEstadoConc(a, b)
  	if a == b
  	  raw("<span class='glyphicon glyphicon-ok' aria-hidden='true'></span>")
  	else
  	  raw("<span class='glyphicon glyphicon-remove' aria-hidden='true'></span>")
  	  
  	end
  end
end