module DocumentosHelper

    def arma_Titulo(cveAnt)
      continua = "1"
      cveAnt = "*" if cveAnt == nil
      if params.has_key?(:regreso) && params[:regreso] == "1" and cveAnt != "*"
        sql = "SELECT CveAnt FROM documentos where Clave = '" + cveAnt + "'"
        sql = "SELECT CveAnt FROM documentos where CveAnt = '" + cveAnt + "'" if params.has_key?(:editado)
        @regresox = @dbEsta.connection.select_all(sql)
        cveAnt = @regresox[0]['CveAnt'] if (cveAnt != "" or cveAnt != "*") && !params.has_key?(:baja)
        continua = "0" if cveAnt == "*" or cveAnt == ""
      end

      if cveAnt != "*" and continua == "1"
        sql = "SELECT CveAnt,Nombre FROM documentos where Clave = '" + cveAnt + "'"
        @titulo = @dbEsta.connection.select_all(sql)
        @tituloArm = @titulo[0]['Nombre'] + " - " + @tituloArm if @tituloArm != ""
        @tituloArm = @titulo[0]['Nombre'] if @tituloArm == ""
        arma_Titulo(@titulo[0]['CveAnt'])
      end
    end

end
