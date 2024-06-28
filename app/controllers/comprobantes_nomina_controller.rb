class ComprobantesNominaController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_datos_empleado, only: [:index, :comprobantes_nomina_descarga]

  def index

    sub_sql = "NumEmpleado = #{@numEmpleado}"
    sub_sql = "RegFedCont = #{User.sanitize(@rfc_posible)}" if @rfc_posible.size == 13
    sql = "SELECT * FROM #{@dbFacEmpresa}.hrecibossat WHERE #{sub_sql} AND EstatusTimbrado = 'A' ORDER BY FechaFinalPago DESC, NumPeriodo DESC LIMIT 150"

    @comprobantes = @dbFacEle.connection.select_all(sql)

  end

  def comprobantes_nomina_descarga

    @anoFiscal = @numPeriodo = @consec = 0

    @anoFiscal  = params[:AnoFiscal]  if params.has_key?(:AnoFiscal)
    @numPeriodo = params[:NumPeriodo] if params.has_key?(:NumPeriodo)
    @consec     = params[:Consec]     if params.has_key?(:Consec)

    return redirect_to "/", alert: "Comprobante no Encontrado. Se ha notificado al Administrador" if @anoFiscal.to_i < 1 || @numPeriodo.to_i < 1 || @anoFiscal.to_i < 1 

    sql = "SELECT * FROM #{@dbFacEmpresa}.hrecibossat WHERE AnoFiscal = #{@anoFiscal} AND NumPeriodo = #{@numPeriodo} AND NumEmpleado = #{@numEmpleado} AND Consec = #{@consec} AND EstatusTimbrado = 'A' LIMIT 1"    
    @comprobantes = @dbFacEle.connection.select_all(sql)

    respond_to do |format|
      
      format.xml { send_data @comprobantes[0]['ContXML'] }
      format.pdf do
        pdf = ComprobantesNominaPdf.new(@comprobantes[0])
        send_data pdf.render
      end          
    end        

  end

  def ayuda
  end

  def contrato_colectivo
    return redirect_to '/contrato_colectivo_de_trabajo.pdf'
  end

  private

   def get_datos_empleado
      @idEmpresa = @numEmpleado = @rfc_posible = @dbFacEmpresa = ""

      get_modulos_usuario 

      @idEmpresa   = @user_permisos[:idEmpresa] rescue 0
      @numEmpleado = @user_permisos[:numEmpleado] rescue 0
      
      @rfc_posible = current_user.email.upcase rescue ""

      @dbFacEmpresa = Sitio.where("idEmpresa = #{@idEmpresa}").first.baseFacEle rescue ""

      return redirect_to "/", alert: "El empleado no tiene datos completos" if @idEmpresa.to_i < 1 || @numEmpleado.to_i < 1 
      return redirect_to "/", alert: "El empleado no tiene empresa con datos completos" if @dbFacEmpresa.length < 3

    end
end
