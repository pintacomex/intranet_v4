class MedidoresController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :obtiene_catalogos
  before_filter :find_medidor, only: [:edit, :update, :show, :destroy, :medidores_display_medidor]

  def index
    sql = "SELECT TableroMedidores.* FROM TableroMedidores ORDER BY NivelZona, NombreMedidor"
    @medidores = @dbEsta.connection.select_all(sql)
  end

  def edit
  end

  def show
    @medidor_params = get_medidor_params
  end

  def medidores_display_medidor
    @medidor_params = get_medidor_params
  end

  private

    def medidore_params
      # esto usaba active model pero ya no
      # params.require(:medidore).permit(:tipo, :valor, :minimo, :maximo, :simbolo, :opciones, :activado, roles: [])
    end

    def obtiene_catalogos
      @tipos = [ [ "Gauge Porcentual", "GaugePorcentual" ] ]
      @activados = [ [ "Activado", 1 ], [ "Desactivado", 0 ] ]
      @roles = CatRole.order(:nivel).collect{ |c| [c.nomPermiso, c.nivel] }
    end

    def get_medidor_params
      get_external_params
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
      @valor = @valor_query.to_i
      if @valor_query.upcase.start_with?('SELECT')
        @valor = @dbEsta.connection.select_all("#{@valor_query} AS Val").first['Val'].to_i rescue 20
      end
      @etiqueta_query = agregar_params(@medidor['Etiqueta'])
      @etiqueta = ''
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

      {
        id: "g#{@id.to_s.gsub("-", "")}",
        value: @valor,
        min: @majorTicks.first,
        max: @majorTicks.last,
        symbol: "#{@medidor['SimboloUnidades']}",
        title: "#{@medidor['Titulo']}",
        label: "#{@etiqueta}",
        pointer: @medidor['PonerAguja'].to_i == 0 ? false : true,
        gaugeWidthScale: 0.6,
        customSectors: @colores,
        counter: true,
        hideMinMax: true
      }.merge(@opciones).to_json
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
    
    def agregar_params(query)
      query
        .gsub("__p2__", @p2)
        .gsub("__p3__", @p3)
        .gsub("__me__", Date.today.to_s.gsub("-","")[0..5])
        .gsub("__fe__", Date.today.to_s.gsub("-","")[0..7])
    end

    def get_external_params
      @p2 = ''
      @p3 = ''
      @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
      if @permiso && @permiso.count == 1
        if @permiso[0].p2 != "" # && @permiso[0].p2 != "0"
          @p2 = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort.join(",")
        end
        if @permiso[0].p3 != "" # && @permiso[0].p3 != "0"
          @p3 = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort.join(",")
        end
      end
    end

    def find_medidor
      @id = params[:id]
      sql = "SELECT TableroMedidores.* FROM TableroMedidores WHERE NivelZona = #{User.sanitize(@id)} ORDER BY NivelZona, NombreMedidor"
      @medidor = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @medidor
    end
end

