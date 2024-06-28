class Tableros::LayoutsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :find_layout, only: [:edit, :update, :show, :destroy]
  before_filter :obtiene_catalogos, only: [:new, :create, :edit, :update]

  def index
    sql = "SELECT TableroLayout.* FROM TableroLayout ORDER BY IdLayout, IdElemento"
    @layouts = @dbEsta.connection.select_all(sql)
  end

  def new
    @new = true
    @layout = {}
    @layout['IdLayout'] = get_id
    @layout['IdElemento'] = 1
    @layout['NombreElemento'] = ''
    @layout['TituloAdicional'] = ''
    @layout['Url'] = ''
    @layout['IdMedidor'] = 1
    @layout['Xini'] = 1
    @layout['Yini'] = 1
    @layout['Xfin'] = 1
    @layout['Yfin'] = 1
  end

  def edit
    @new = false
  end

  def create
    create_or_update
  end

  def update
    create_or_update
  end

  def show
    get_layout_params
    sql = "SELECT TableroLayout.*, '' as nombre, '' as adicional, '' as url, '' as TipoMedidor FROM TableroLayout WHERE IdLayout = #{User.sanitize(@id.first)}"
    @elementos = @dbEsta.connection.select_all(sql) rescue []
    @medidores = []
    @elementos.each do |layout|
      layout['nombre'] = get_layout_param(layout, 'NombreElemento')
      layout['adicional'] = get_layout_param(layout, 'TituloAdicional')
      layout['url'] = get_layout_param(layout, 'Url')
      sql = "SELECT TableroMedidores.* FROM TableroMedidores where IdMedidor = #{User.sanitize(layout['IdMedidor'].to_i)} limit 1"
      medidor = @dbEsta.connection.select_all(sql).first rescue false
      if medidor
        @medidores << medidor
        layout['TipoMedidor'] = medidor['TipoMedidor']
      end
    end
    @css_grid = get_css_grid
  end

  def destroy
    sql = "DELETE FROM TableroLayout WHERE IdLayout = #{User.sanitize(@id.first)} AND IdElemento = #{User.sanitize(@id.last)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      redirect_to "/tableros/layouts", alert: "No se ha podido borrar el layout. Error: #{exc.message}"
    end
    redirect_to "/tableros/layouts", notice: "Layout borrado exitosamente"
  end

  private

    def create_or_update
      @new = params[:new] == "true"
      @id_layout = params[:idlayout].to_i
      @id_layout = get_id if @new && @id_layout == 0
      @id_elemento = params[:idelemento].to_i
      @nombre_elemento = params[:nombreelemento].to_s
      @titulo_adicional = params[:tituloadicional].to_s
      @url = params[:url].to_s
      @id_medidor = params[:idmedidor].to_i
      @xini = params[:xini].to_i
      @yini = params[:yini].to_i
      @xfin = params[:xfin].to_i
      @yfin = params[:yfin].to_i
      @layout = {}
      @layout['IdLayout'] = @id_layout
      @layout['IdElemento'] = @id_elemento
      @layout['NombreElemento'] = @nombre_elemento
      @layout['TituloAdicional'] = @titulo_adicional
      @layout['Url'] = @url
      @layout['IdMedidor'] = @id_medidor
      @layout['Xini'] = @xini
      @layout['Yini'] = @yini
      @layout['Xfin'] = @xfin
      @layout['Yfin'] = @yfin
      if @nombre_elemento == ''
        flash[:alert] = "Nombre inválido"
        return render 'edit'
      end
      sql = "INSERT INTO TableroLayout (IdLayout, IdElemento, NombreElemento, TituloAdicional, Url, IdMedidor, Xini, Yini, Xfin, Yfin) VALUES ( #{@id_layout}, #{@id_elemento}, #{User.sanitize(@nombre_elemento)}, #{User.sanitize(@titulo_adicional)}, #{User.sanitize(@url)}, #{User.sanitize(@id_medidor)}, #{User.sanitize(@xini)}, #{User.sanitize(@yini)}, #{User.sanitize(@xfin)}, #{User.sanitize(@yfin)} ) ON DUPLICATE KEY UPDATE NombreElemento = #{User.sanitize(@nombre_elemento)}, TituloAdicional = #{User.sanitize(@titulo_adicional)}, Url = #{User.sanitize(@url)}, IdMedidor = #{User.sanitize(@id_medidor)}, Xini = #{User.sanitize(@xini)}, Yini = #{User.sanitize(@yini)}, Xfin = #{User.sanitize(@xfin)}, Yfin = #{User.sanitize(@yfin)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        flash[:alert] = "No se ha podido #{@new ? "crear" : "editar"} el layout. Error: #{exc.message}"
        return render 'edit'
      end
      redirect_to "/tableros/layouts/#{@id_layout}-#{@id_elemento}", notice: "Layout #{@new ? "creado" : "editado"} exitosamente"
    end

    def get_id
      id = 1
      ids = @dbEsta.connection.select_all("SELECT max(IdLayout) as mid FROM TableroLayout")
      id = ids.first['mid'].to_i + 1 if ids.count == 1
      id
    end

    def get_layout_params
      get_external_params
      @nombre_query = agregar_params(@layout['NombreElemento'])
      @nombre = @nombre_query.to_s
      if @nombre_query.upcase.start_with?('SELECT')
        @nombre = @dbEsta.connection.select_all("#{@nombre_query} AS Val").first['Val'] rescue ''
      end
      @adicional_query = agregar_params(@layout['TituloAdicional'])
      @adicional = @adicional_query.to_s
      if @adicional_query.upcase.start_with?('SELECT')
        @adicional = @dbEsta.connection.select_all("#{@titulo_adicional_query} AS Val").first['Val'] rescue ''
      end
      @url_query = agregar_params(@layout['Url'])
      @url = @url_query.to_s
      if @url_query.upcase.start_with?('SELECT')
        @url = @dbEsta.connection.select_all("#{@url_query} AS Val").first['Val'] rescue ''
      end
    end

    def find_layout
      @id = params[:id].to_s.split("-")
      sql = "SELECT TableroLayout.* FROM TableroLayout WHERE IdLayout = #{User.sanitize(@id.first)} AND IdElemento = #{User.sanitize(@id.last)} LIMIT 1"
      @layout = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @layout
    end

    def get_css_grid
      #// grid.layoutit.com?id=RjNs0yl
      #//   grid-template-areas: "area-1 area-2 area-3 area-4" "area-5 area-5 area-3 area-6" ". . . .";
      grid = [[".", ".",".", "."], [".", ".",".", "."], [".", ".",".", "."], [".", ".",".", "."]]
      @elementos.each do |layout|
        class_name = "medidor-#{layout['IdMedidor']}"
        xini = layout['Xini'] - 1
        yini = layout['Yini'] - 1
        xfin = layout['Xfin'] - 1
        yfin = layout['Yfin'] - 1
        (xini..xfin).each do |x|
          (yini..yfin).each do |y|
            grid[y][x] = class_name if grid[y][x] == "."
          end
        end
      end
      grid.select! { |row|  row != [".", ".",".", "."] }
      "\"#{grid.map{|row| row.join(" ")}.join("\" \"")}\""
    end

    def obtiene_catalogos
      @medidores = @dbEsta.connection.select_all("SELECT TableroMedidores.* FROM TableroMedidores ORDER BY IdMedidor").collect{|u| ["#{u['IdMedidor']} - #{u['Titulo'].truncate(40)}", u['IdMedidor']]}.uniq rescue []
    end
end

