class BloqueoTarjetasClubComexController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :set_filters, only: [:index]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  def index
    sql = "SELECT listaNegraClubComex.* FROM #{@nomDbShared}listaNegraClubComex WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY listaNegraClubComex.Idtc LIMIT 1000"
    @datos = @dbVentasonline.connection.select_all(sql)
  end

  def new
  end

  def create
    @id = params[:id].to_i if params.has_key?(:id)
    @id = params[:id] if @id > 0 # la ID puede tener un 0 al principio
    url = "/bloqueo_tarjetas_club_comex"
    @filtros = ["Idtc = #{User.sanitize(@id)}"]
    sql = "SELECT listaNegraClubComex.* FROM #{@nomDbShared}listaNegraClubComex WHERE Idtc = #{@id} LIMIT 1"
    @datos = @dbVentasonline.connection.select_all(sql)
    if @datos.one?
      return redirect_to url, alert: "La tarjeta ya existe"
    end
    @filtros = ["numtarjeta = #{User.sanitize(@id)}"]
    sql = "SELECT clicbcmx.* FROM #{@nomDbPdv}clicbcmx WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) LIMIT 1"
    @datos = @dbVentasonline.connection.select_all(sql)
    unless @datos.one?
      return redirect_to url, alert: "La tarjeta no existe en la tabla Clicbcmx"
    end
    sql = "INSERT INTO #{@nomDbShared}listaNegraClubComex (Idtc, StatusBloqueo) VALUES (#{User.sanitize(@id)}, 1)"
    begin
      @dbVentasonline.connection.execute(sql)
    rescue Exception => exc
      return redirect_to url, alert: "No se ha podido crear la tarjeta"
    end
    return redirect_to url, notice: "Tarjeta agregada exitosamente"
  end

  def show
    @id = params[:id].to_i if params.has_key?(:id)
    @id = params[:id] if @id > 0 # la ID puede tener un 0 al principio
    @filtros = ["Idtc = #{User.sanitize(@id)}"]
    sql = "SELECT listaNegraClubComex.* FROM #{@nomDbShared}listaNegraClubComex WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) LIMIT 1"
    @datos = @dbVentasonline.connection.select_all(sql)
    if @datos.one?
      @item = @datos.first
    else
      return redirect_to root_path
    end
  end

  def update
    @id = params[:id].to_i if params.has_key?(:id)
    @id = params[:id] if @id > 0 # la ID puede tener un 0 al principio
    @status = params[:status].to_i if params.has_key?(:status)
    @observaciones = params[:observaciones].to_s if params.has_key?(:observaciones)
    @filtros = ["Idtc = #{User.sanitize(@id)}"]
    sql = "SELECT listaNegraClubComex.* FROM #{@nomDbShared}listaNegraClubComex WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) LIMIT 1"
    @datos = @dbVentasonline.connection.select_all(sql)
    if @datos.one?
      url = "/bloqueo_tarjetas_club_comex_detalle?id=#{@id}"
      @item = @datos.first
      sql = "UPDATE #{@nomDbShared}listaNegraClubComex SET StatusBloqueo = #{User.sanitize(@status)}, Observaciones = #{User.sanitize(@observaciones).truncate(300)}, FechaActualizacion = now() WHERE Idtc = #{User.sanitize(@id)}"
      begin
        @dbVentasonline.connection.execute(sql)
      rescue Exception => exc
        return redirect_to url, alert: "No se ha podido guardar el Status"
      end
      return redirect_to url, notice: "Status guardado exitosamente"
    else
      return redirect_to root_path
    end
  end

  private

  def set_filters
    @filtros = ["1"]
  end
end
