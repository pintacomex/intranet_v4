class SupImagensController < ApplicationController
  before_filter :authenticate_user!

  def create
    @sup_imagen = SupImagen.create( sup_imagen_params )
    url = "/supervisiones/supervision_en_curso_aci?sucursal=#{params[:sup_imagen][:Sucursal]}&id_visita=#{params[:sup_imagen][:IdVisita]}&id_checklist=#{params[:sup_imagen][:IdChecklist]}&id_cat_checklist=#{params[:sup_imagen][:IdCatChecklist]}&id_campo=#{params[:sup_imagen][:IdCampo]}"
    if @sup_imagen.save
    	return redirect_to url, notice: "Imagen agregada correctamente"
    else
    	return redirect_to url, alert: "Error al agregar la imagen"
    end
  end

  private

    def sup_imagen_params
      params.require(:sup_imagen).permit(:Sucursal, :IdVisita, :IdChecklist, :IdCatChecklist, :IdCampo, :Usuario, :img)
    end

end

