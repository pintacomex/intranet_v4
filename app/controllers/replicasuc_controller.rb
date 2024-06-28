#!/bin/env ruby
# encoding: utf-8
class ReplicasucController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  
  include ActionView::Helpers::NumberHelper

  def replicasuc 
    sql = "select " +
            "tRepl.*, " +
            "tSuc.Nombre as NomSuc, " +
            "tZon.NomZona as NomZona " +
          "from replicasuc as tRepl " +
            "left join #{@nomDbComun}sucursal as tSuc " +
            "on " +
              "tSuc.Num_suc = tRepl.Num_suc " +
            "left join #{@nomDbComun}zonas as tZon " +
            "on " +
              "tZon.NumZona = tSuc.ZonaAsig " +
          "order by " +
            "tSuc.ZonaAsig, tRepl.Nombre "
    @antsaldos = @dbPdv.connection.select_all(sql)
    @modo_grafico = false
    @modo_grafico = true if params.has_key?(:modo_grafico)
    respond_to do |format|
      format.html
    end    
  end

end
