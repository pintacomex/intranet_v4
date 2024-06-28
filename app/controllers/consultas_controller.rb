class ConsultasController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :admin_only, only: [:reportes]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def index
    # get_filtros_from_user
    sql = "SELECT * from ReportesIntranet order by seccion, subseccion, orden"
    @reportes = @dbEsta.connection.select_all(sql)
    @reporte = @reportes.first

    reporte_seleccionado = params[:r].to_i if params.has_key?(:r)
    unless reporte_seleccionado.nil?
      @reporte = @reportes.select { |item| item['id'] == reporte_seleccionado }.first
    end
    if @reporte.nil?
      return redirect_to "/", alert: "No se han encontrado reportes en ReportesIntranet"
    end

    sql = @reporte['query']

    @titulo_filtros = {}
    @filtros = {}
    @seleccion_filtros = {}
    @titulo_seleccion_filtros = {}
    parm = []
    (1..9).each do |index|
      break if @reporte["TituloFiltro#{index}"].to_s.strip == ''
      @titulo_filtros[index] = @reporte["TituloFiltro#{index}"]
      filtrosql = @reporte["Filtro#{index}"]
      @filtros[index] = @dbEsta.connection.select_all(filtrosql) rescue []
      @seleccion_filtros[index] = @filtros[index].first['id'] rescue "id no encontrado"
      @titulo_seleccion_filtros[index] = @filtros[index].first['dato'] rescue "titulo no encontrado"
      curr = "f#{index}".to_sym
      parm[index] = params[curr] if params.has_key?(curr)
      if parm[index]
        @seleccion_filtros[index] = parm[index]
        @titulo_seleccion_filtros[index] = @filtros[index].select{ |item| item['id'].to_s == parm[index].to_s }.first['dato'] rescue "titulo seleccionado no encontrado"
      end
      sql = sql.gsub("__f#{index}__", @seleccion_filtros[index].to_s)
    end

    has_params = params[:p1] if params.has_key?(:p1)
    if has_params
      parm = []
      (1..9).each do |index|
        curr = "p#{index}".to_sym
        parm[index] = params[curr] if params.has_key?(curr)
        break unless parm[index]
        sql = sql.gsub("__p#{index}__", parm[index])
      end
    end

    @consulta = @dbEsta.connection.select_all(sql) rescue []

    respond_to do |format|
      format.html
      format.csv do
          out_arr = []
          line = []
          @consulta.first.keys.each do |k|
            line.push(k.underscore.titleize)
          end
          out_arr.push(line.join(","))
          @consulta.each do |m|
            line = []
            m.keys.each do |k|
              if k.include?("fecha")
                line.push(fix_show_date_int(m[k]))
              elsif k.downcase.include?("mes")
                line.push(fix_show_date_mes(m[k]).to_s)
              elsif k.downcase.include?("valua") ||
                    k.downcase.include?("venta") ||
                    k.downcase.include?("costo") ||
                    k.downcase.include?("importe")
                line.push(fix_num_to_money(m[k]).to_s.gsub(",", "").gsub("$",""))
              else
                line.push(m[k])
              end
            end
            out_arr.push(line.join(","))
          end
          csv_file = "/tmp/#{@reporte['titulo'].to_s.gsub(" ", "_")}_#{DateTime.now.to_i}.csv"
          dump_to_file(csv_file,out_arr.join("\n"))
          send_file csv_file
          return
      end
    end
  end

  def reportes
    sql = "SELECT * from ReportesIntranet order by id ASC"
    @reportes = @dbEsta.connection.select_all(sql)
  end

  private

  def dump_to_file(filename, txt, modo="w")
    File.open(filename, modo) {|f| f.write(txt) }
  end
end