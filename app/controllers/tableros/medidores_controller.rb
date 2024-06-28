class Tableros::MedidoresController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :obtiene_catalogos
  before_filter :find_medidor, only: [:edit, :update, :show, :destroy, :medidores_display_medidor]

  def index
    sql = "SELECT TableroMedidores.* FROM TableroMedidores ORDER BY IdMedidor"
    @medidores = @dbEsta.connection.select_all(sql)
  end

  def new
    @new = true
    @medidor = {}
    @medidor['IdMedidor'] = get_id
    @medidor['TipoMedidor'] = 'column'
    @medidor['Titulo'] = ''
    @medidor['Etiqueta'] = ''
    @medidor['SimboloUnidades'] = ''
    @medidor['ValorActual'] = ''
    @medidor['IndexLabel'] = ''
    @medidor['ValorMin'] = '0'
    @medidor['ValorMax'] = ''
    @medidor['PonerAguja'] = 0
    @medidor['Color1'] = ''
    @medidor['lo1'] = ''
    @medidor['hi1'] = ''
    @medidor['Color2'] = ''
    @medidor['lo2'] = ''
    @medidor['hi2'] = ''
    @medidor['Color3'] = ''
    @medidor['lo3'] = ''
    @medidor['hi3'] = ''
    @medidor['Color4'] = ''
    @medidor['lo4'] = ''
    @medidor['hi4'] = ''
    @medidor['Color5'] = ''
    @medidor['lo5'] = ''
    @medidor['hi5'] = ''
    @medidor['Comentario'] = ''
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
    @medidor_params = get_medidor_params
  end

  def medidores_display_medidor
    @medidor_params = get_medidor_params
  end

  def destroy
    sql = "DELETE FROM TableroMedidores WHERE IdMedidor = #{User.sanitize(@id)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      redirect_to "/tableros/medidores", alert: "No se ha podido borrar el medidor. Error: #{exc.message}"
    end
    redirect_to "/tableros/medidores", notice: "Medidor borrado exitosamente"
  end

  private

    def medidore_params
      # esto usaba active model pero ya no
      # params.require(:medidore).permit(:tipo, :valor, :minimo, :maximo, :simbolo, :opciones, :activado, roles: [])
    end

    def obtiene_catalogos
      @tipos = [ [ "Gauge Porcentual", "GaugePorcentual" ],
      ["Pie", "pie"],
      ["Columna", "column"],
      ["Linea", "line"],
      ["Barras", "bar"],
      ["Area", "area"],
      ["Spline", "spline"],
      ["Spline Area", "splineArea"],
      ["Step Line", "stepLine"],
      ["Scatter", "scatter"],
      ["Bubble", "bubble"],
      ["Stacked Column", "stackedColumn"],
      ["Stacked Bar", "stackedBar"],
      ["Stacked Area", "stackedArea"],
      ["Dona", "doughnut"] ]
      @activados = [ [ "Activado", 1 ], [ "Desactivado", 0 ] ]
      @roles = CatRole.order(:nivel).collect{ |c| [c.nomPermiso, c.nivel] }
    end

    def get_medidor_params
      get_external_params
      @titulo_query = agregar_params(@medidor['Titulo'])
      @titulo = @titulo_query.to_s
      if @titulo_query.upcase.start_with?('SELECT')
        @titulo = @dbEsta.connection.select_all("#{@titulo_query} AS Val").first['Val'] rescue ''
      end
      @minimo_query = agregar_params(@medidor['ValorMin'])
      @minimo = @minimo_query.to_i
      if @minimo_query.upcase.start_with?('SELECT')
        @minimo = @dbEsta.connection.select_all("#{@minimo_query} AS Val").first['Val'].to_i rescue 10
      end
      @maximo_query = agregar_params(@medidor['ValorMax'])
      @maximo = @maximo_query.to_i
      if @maximo_query.upcase.start_with?('SELECT')
        @maximo = @dbEsta.connection.select_all("#{@maximo_query} AS Val").first['Val'].to_i rescue 30
      end
      @valor_query = agregar_params(@medidor['ValorActual'])
      @valor = @valor_query.to_f
      if @valor_query.upcase.start_with?('SELECT')
        @valor = @dbEsta.connection.select_all("#{@valor_query} AS Val").first['Val'].to_f rescue 20
      end
      @valor = "%g" % @valor
      @etiqueta_query = agregar_params(@medidor['Etiqueta'])
      @etiqueta = @etiqueta_query.to_s
      if @etiqueta_query.upcase.start_with?('SELECT')
        @etiqueta = @dbEsta.connection.select_all("#{@etiqueta_query} AS Val").first['Val'] rescue ''
      end
      @colores = []
      unless @medidor['Color1'].blank?
        @color1 = @medidor['Color1']
        @lo1_query = agregar_params(@medidor['lo1'])
        @lo1 = @lo1_query.to_i
        if @lo1_query.upcase.start_with?('SELECT')
          @lo1 = @dbEsta.connection.select_all("#{@lo1_query} AS Val").first['Val'].to_i rescue 0
        end
        @hi1_query = agregar_params(@medidor['hi1'])
        @hi1 = @hi1_query.to_i
        if @hi1_query.upcase.start_with?('SELECT')
          @hi1 = @dbEsta.connection.select_all("#{@hi1_query} AS Val").first['Val'].to_i rescue 0
        end
        agregar_color(@color1, @lo1, @hi1)
      end
      unless @medidor['Color2'].blank?
        @color2 = @medidor['Color2']
        @lo2_query = agregar_params(@medidor['lo2'])
        @lo2 = @lo2_query.to_i
        if @lo2_query.upcase.start_with?('SELECT')
          @lo2 = @dbEsta.connection.select_all("#{@lo2_query} AS Val").first['Val'].to_i rescue 0
        end
        @hi2_query = agregar_params(@medidor['hi2'])
        @hi2 = @hi2_query.to_i
        if @hi2_query.upcase.start_with?('SELECT')
          @hi2 = @dbEsta.connection.select_all("#{@hi2_query} AS Val").first['Val'].to_i rescue 0
        end
        agregar_color(@color2, @lo2, @hi2)
      end
      unless @medidor['Color3'].blank?
        @color3 = @medidor['Color3']
        @lo3_query = agregar_params(@medidor['lo3'])
        @lo3 = @lo3_query.to_i
        if @lo3_query.upcase.start_with?('SELECT')
          @lo3 = @dbEsta.connection.select_all("#{@lo3_query} AS Val").first['Val'].to_i rescue 0
        end
        @hi3_query = agregar_params(@medidor['hi3'])
        @hi3 = @hi3_query.to_i
        if @hi3_query.upcase.start_with?('SELECT')
          @hi3 = @dbEsta.connection.select_all("#{@hi3_query} AS Val").first['Val'].to_i rescue 0
        end
        agregar_color(@color3, @lo3, @hi3)
      end
      unless @medidor['Color4'].blank?
        @color3 = @medidor['Color4']
        @lo4_query = agregar_params(@medidor['lo4'])
        @lo4 = @lo4_query.to_i
        if @lo4_query.upcase.start_with?('SELECT')
          @lo4 = @dbEsta.connection.select_all("#{@lo4_query} AS Val").first['Val'].to_i rescue 0
        end
        @hi4_query = agregar_params(@medidor['hi4'])
        @hi4 = @hi4_query.to_i
        if @hi4_query.upcase.start_with?('SELECT')
          @hi4 = @dbEsta.connection.select_all("#{@hi4_query} AS Val").first['Val'].to_i rescue 0
        end
        agregar_color(@color4, @lo4, @hi4)
      end
      unless @medidor['Color5'].blank?
        @color3 = @medidor['Color5']
        @lo5_query = agregar_params(@medidor['lo5'])
        @lo5 = @lo5_query.to_i
        if @lo5_query.upcase.start_with?('SELECT')
          @lo5 = @dbEsta.connection.select_all("#{@lo5_query} AS Val").first['Val'].to_i rescue 0
        end
        @hi5_query = agregar_params(@medidor['hi5'])
        @hi5 = @hi5_query.to_i
        if @hi5_query.upcase.start_with?('SELECT')
          @hi5 = @dbEsta.connection.select_all("#{@hi5_query} AS Val").first['Val'].to_i rescue 0
        end
        agregar_color(@color5, @lo5, @hi5)
      end
      @opciones = {}
      @majorTicks = get_ticks

      if @medidor['TipoMedidor'] == 'GaugePorcentual'
        {
          id: "g#{@id.to_s.gsub("-", "")}",
          value: @valor,
          decimals: 2,
          min: @majorTicks.first,
          max: @majorTicks.last,
          symbol: "#{@medidor['SimboloUnidades']}",
          title: "#{@titulo}",
          label: "#{@etiqueta}",
          pointer: @medidor['PonerAguja'].to_i == 0 ? false : true,
          gaugeWidthScale: 0.6,
          customSectors: @colores,
          counter: true,
          hideMinMax: true
        }.merge(@opciones).to_json
      else
        @valor_query = agregar_params(@medidor['ValorActual'])
        @valor = [{ 'Valor': 0, 'Titulo': 'Insertar datos'}]
        if @valor_query.upcase.start_with?('SELECT')
          @valor = @dbEsta.connection.select_all("#{@valor_query}")
        end
        @valores = get_valores(@valor)
        {
          animationEnabled: true,
          theme: "light2",
          backgroundColor: "#F5F5F5",
          title: {
            text: "#{@titulo}",
            fontFamily: "sans-serif",
            fontColor: "#999999",
            fontSize: 16,
            fontStyle: "bold",
          },
          subtitles: [
            {
              text: "#{@etiqueta}",
              verticalAlign: "bottom",
              fontFamily: "Arial",
              fontColor: "#b3b3b3",
              fontSize: 12,
            }
          ],
          data: @valores,
        }.merge(@opciones).to_json
      end
    end

    def get_valores(arr)
      return [] if arr.length == 0
      num_series = arr[0].length - 1
      series_data = {}
      arr.each do |v|
        for i in 1..num_series do
          series_data[i - 1]  = [] if !series_data[i - 1]
          series_data[i - 1].push({label: v['Titulo'], y: v[get_valor_nom(i)].to_i})
        end
      end
      series_data.map do |v|
        {
          type: @medidor['TipoMedidor'].to_s,
          startAngle: 240,
          yValueFormatString: "#{@medidor['SimboloUnidades'] ? @medidor['SimboloUnidades'] : ""}",
          indexLabel: "#{@medidor['IndexLabel'] ? @medidor['IndexLabel'] : ""}",
          dataPoints: v.last
        }
      end
    end

    def get_valor_nom(index)
      return 'Valor' if index == 1
      "Valor#{index}"
    end

    def agregar_color(color, lo, hi)
      hi = lo if hi < lo
      @colores.push({
        color: color,
        lo: lo,
        hi: hi
      })
    end

    def get_ticks
      min = [0, @minimo].max
      # min = ((@minimo.to_f - 1) / 10).floor * 10 if @minimo >= 10

      max = [10, @maximo].max
      # max = ((@maximo.to_f + 1) / 10).ceil * 10 if @maximo >= 10

      [min, max]
    end

    def find_medidor
      @id = params[:id].to_i
      sql = "SELECT TableroMedidores.* FROM TableroMedidores WHERE IdMedidor = #{User.sanitize(@id.to_s)} LIMIT 1"
      @medidor = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @medidor
    end

    def create_or_update
      @new = params[:new] == "true"
      @id_medidor = params[:idmedidor].to_i
      @id_medidor = get_id if @new && @id_medidor == 0
      @tipo_medidor = params[:tipomedidor].to_s
      @titulo = params[:titulo].to_s
      @etiqueta = params[:etiqueta].to_s
      @comentario = params[:comentario].to_s
      @simbolo_unidades = params[:simbolounidades].to_s
      @valor_actual = params[:valoractual].to_s
      @index_label = params[:indexlabel].to_s
      @valor_min = params[:valormin].to_i
      @valor_max = params[:valormax].to_i
      @poner_aguja = params[:poneraguja].to_i
      @color1 = params[:color1].to_s
      @lo1 = params[:lo1].to_i
      @hi1 = params[:hi1].to_i
      @color2 = params[:color2].to_s
      @lo2 = params[:lo2].to_i
      @hi2 = params[:hi2].to_i
      @color3 = params[:color3].to_s
      @lo3 = params[:lo3].to_i
      @hi3 = params[:hi3].to_i
      @color4 = params[:color4].to_s
      @lo4 = params[:lo4].to_i
      @hi4 = params[:hi4].to_i
      @color5 = params[:color5].to_s
      @lo5 = params[:lo5].to_i
      @hi5 = params[:hi5].to_i
      @medidor = {}
      @medidor['IdMedidor'] = @id_medidor
      @medidor['TipoMedidor'] = @tipo_medidor
      @medidor['Titulo'] = @titulo
      @medidor['Etiqueta'] = @etiqueta
      @medidor['Comentario'] = @comentario
      @medidor['SimboloUnidades'] = @simbolo_unidades
      @medidor['ValorActual'] = @valor_actual
      @medidor['IndexLabel'] = @index_label
      @medidor['ValorMin'] = @valor_min
      @medidor['ValorMax'] = @valor_max
      @medidor['PonerAguja'] = @poner_aguja
      @medidor['Color1'] = @color1
      @medidor['lo1'] = @lo1
      @medidor['hi1'] = @hi1
      @medidor['Color2'] = @color2
      @medidor['lo2'] = @lo2
      @medidor['hi2'] = @hi2
      @medidor['Color3'] = @color3
      @medidor['lo3'] = @lo3
      @medidor['hi3'] = @hi3
      @medidor['Color4'] = @color4
      @medidor['lo4'] = @lo4
      @medidor['hi4'] = @hi4
      @medidor['Color5'] = @color5
      @medidor['lo5'] = @lo5
      @medidor['hi5'] = @hi5
      if @titulo == ''
        flash[:alert] = "Título inválido"
        return render 'edit'
      end
      sql = "INSERT INTO TableroMedidores (IdMedidor, TipoMedidor, Titulo, Etiqueta, Comentario, SimboloUnidades, ValorActual, IndexLabel, ValorMin, ValorMax, PonerAguja, Color1, lo1, hi1, Color2, lo2, hi2, Color3, lo3, hi3, Color4, lo4, hi4, Color5, lo5, hi5) VALUES ( #{User.sanitize(@id_medidor)}, #{User.sanitize(@tipo_medidor)}, #{User.sanitize(@titulo)}, #{User.sanitize(@etiqueta)}, #{User.sanitize(@comentario)}, #{User.sanitize(@simbolo_unidades)}, #{User.sanitize(@valor_actual)}, #{User.sanitize(@index_label)}, #{User.sanitize(@valor_min)}, #{User.sanitize(@valor_max)}, #{User.sanitize(@poner_aguja)}, #{User.sanitize(@color1)}, #{User.sanitize(@lo1)}, #{User.sanitize(@hi1)}, #{User.sanitize(@color2)}, #{User.sanitize(@lo2)}, #{User.sanitize(@hi2)}, #{User.sanitize(@color3)}, #{User.sanitize(@lo3)}, #{User.sanitize(@hi3)}, #{User.sanitize(@color4)}, #{User.sanitize(@lo4)}, #{User.sanitize(@hi4)}, #{User.sanitize(@color5)}, #{User.sanitize(@lo5)}, #{User.sanitize(@hi5)} ) ON DUPLICATE KEY UPDATE TipoMedidor = #{User.sanitize(@tipo_medidor)}, Titulo = #{User.sanitize(@titulo)}, Etiqueta = #{User.sanitize(@etiqueta)}, Comentario = #{User.sanitize(@comentario)}, SimboloUnidades = #{User.sanitize(@simbolo_unidades)}, ValorActual = #{User.sanitize(@valor_actual)}, IndexLabel = #{User.sanitize(@index_label)}, ValorMin = #{User.sanitize(@valor_min)}, ValorMax = #{User.sanitize(@valor_max)}, PonerAguja = #{User.sanitize(@poner_aguja)}, Color1 = #{User.sanitize(@color1)}, lo1 = #{User.sanitize(@lo1)}, hi1 = #{User.sanitize(@hi1)}, Color2 = #{User.sanitize(@color2)}, lo2 = #{User.sanitize(@lo2)}, hi2 = #{User.sanitize(@hi2)}, Color3 = #{User.sanitize(@color3)}, lo3 = #{User.sanitize(@lo3)}, hi3 = #{User.sanitize(@hi3)}, Color4 = #{User.sanitize(@color4)}, lo4 = #{User.sanitize(@lo4)}, hi4 = #{User.sanitize(@hi4)}, Color5 = #{User.sanitize(@color5)}, lo5 = #{User.sanitize(@lo5)}, hi5 = #{User.sanitize(@hi5)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        flash[:alert] = "No se ha podido #{@new ? "crear" : "editar"} el medidor. Error: #{exc.message}"
        return render 'edit'
      end
      redirect_to "/tableros/medidores/#{@id_medidor}", notice: "Medidor #{@new ? "creado" : "editado"} exitosamente"
    end

    def get_id
      id = 1
      ids = @dbEsta.connection.select_all("SELECT max(IdMedidor) as mid FROM TableroMedidores")
      id = ids.first['mid'].to_i + 1 if ids.count == 1
      id
    end
end

