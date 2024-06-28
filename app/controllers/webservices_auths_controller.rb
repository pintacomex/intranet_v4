class WebservicesAuthsController < InheritedResources::Base

  private

    def webservices_auth_params
      params.require(:webservices_auth).permit(:sucursal, :descripcion, :respuesta, :status, :fechaHora)
    end
end

