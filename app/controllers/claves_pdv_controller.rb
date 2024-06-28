class ClavesPdvController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    get_zona_nivel
    if params.has_key?(:clave)
      @res = get_clave(params[:clave])
      @res = "Por favor revise que la zona y nivel estén dados de alta en la tabla Permisos.p2 y Permisos.p3 para su usuario" if @res == ""
    end
  end

  private

    def get_clave(c)
      ret = ""
      # Estas deben tomarse de parametros y ver si son correctos
      opCode     = c.strip.split("-")[0][1,2].to_i rescue 0
      aleatorio  = c.strip.split("-")[1].to_i      rescue 0
      pDescuento = 0
      if c.strip.split("-").length == 3
        pDescuento = c.strip.split("-")[1].to_i rescue 0
        aleatorio  = c.strip.split("-")[2].to_i rescue 0
      end
      if opCode > 0 and aleatorio > 0 and aleatorio < 1000
        where_zona = "zona = #{@zona}"
        where_zona = "1" if @zona < 0
        sql = "SELECT * FROM catconex WHERE #{where_zona} and idconexion = #{@nivel} order by zona LIMIT 1"
        # raise sql.inspectm
        catconex = @dbPdv.connection.select_all(sql)
        if catconex.length == 1
          conexion   = catconex[0]['Conexion']
          conexion   = desencripta(@nivel, catconex[0]['Conexion'])
          pPasswords = []
          pos        = 2
          (0..6).step(1) do |ii|
            pPasswords.push(conexion[pos,2].to_i)
            pos = pos + 2
          end
          ret = calcula_password(@zona, @nivel, opCode, pDescuento, aleatorio,
                                   pPasswords)
        end
      end
      return ret
    end

    def get_zona_nivel
      permiso = Permiso.where("idUsuario = #{current_user.id} AND ( permiso = 'Contralor' OR permiso = 'Director') and p1 = #{@sitio[0].idEmpresa}").first
      @zona  = permiso.p2.to_i rescue 0
      @zona  = -1 if permiso.p2 == "" 
      @nivel = permiso.p3.to_i rescue 0
    end

    def desencripta(renglon,s)
      ss = ""
      j  = 0
      (0..s.length-1).step(3) do |i|
        j = j + 1
        s2 = s[i,3]
        x0 = s2[0].ord - 68
        x1 = s2[1].ord - 76
        x2 = s2[2].ord - 88
        s2 = x0.to_s + x1.to_s + x2.to_s
        ss = ss + (s2.to_i - j - 120 - (renglon*2)).chr
      end
      return ss
    end

    def calcula_password(zona, nivel, opCode, pDescuento, llave, pPasswords)
      # p "calcula_password(zona, nivel, opCode, pDescuento, llave, pPasswords)"
      # p "calcula_password(#{zona.inspect}, #{nivel.inspect}, #{opCode.inspect}, #{pDescuento.inspect}, #{llave.inspect}, #{pPasswords.inspect})"

      ret = op = tipparam = 0
      opp = opAux = tippara = 0.0
      (1..4).step(1) do |i|
        if i == 1
          op = 1
        else
          op = pPasswords[ i + 2 ]
        end

        tipparam = pPasswords[ i - 1 ]
        opp = op.to_f;
        tippara = tipparam.to_f;
        opAux = op.to_f if op  > 0

        case tipparam
        when 1 # digito 1
          param = ( llave / 100 ).to_i
        when 2 # digito 2
          param = ( llave / 10 ).to_i
          param = param - ( ( param / 10 ).to_i * 10 )
        when 3 # digito 3
          param = llave - ( ( llave / 10 ).to_i * 10 ) 
        when 4 # digito 1 y 2
          param = ( llave / 10 ).to_i
        when 5 # digito 1 y 3
          param = ( llave / 100 ).to_i
          param = ( param * 10 ) + ( llave - ( ( llave / 10 ).to_i * 10 ) )
        when 6 # digito 2 y 3
          param = llave - ( ( llave / 100 ).to_i * 100 )
        when 7 # dia
          param = Date.today.day.to_i
        when 8 # mes
          param = Date.today.month.to_i
        when 19 # codigo de operacion
          param = opCode 
        when 20 # descuento
          param = pDescuento 
        when 21 # OpCode+ Descuento
          param = opCode + pDescuento 
        when 22 # OpCode - Descuento
          param = opCode - pDescuento 
        else
          if tipparam >= 9 && tipparam <= 18 # del 1 al 10
            param = tipparam - 8
          else
            param = 0
          end
        end

        op = opAux if op == 0
               
        case op
        when 1 # +
          ret = ret + param
        when 2 # -
          ret = ret - param
        when 3 # *
          ret = ret * param
        when 4 # /
          if param != 0
          ret = ( ret / param ).to_i
          else
            ret = 0
          end
        end

        # p "param: #{param.inspect} op: #{op.inspect}"
        # p "ret: #{ret.inspect}"

      end
      ret = ret.abs
      r2  = 10
      while r2 <= ret
        r2 = r2 * 10
      end
      ret = ( ret ).to_i + nivel * r2 ;
      return ret
    end

end
