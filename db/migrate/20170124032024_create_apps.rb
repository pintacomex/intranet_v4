class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :nombre
      t.string :url
      t.string :bloque
      t.integer :activo,        :null => false, :default => 0

      t.timestamps null: false
    end

    App.new( url: "comprobantes_nomina", nombre: "Comprobantes de Nómina", bloque: "Personal", activo: 1 ).save
    App.new( url: "contrato_colectivo", nombre: "Contrato Colectivo de Trabajo", bloque: "Personal", activo: 1 ).save
    App.new( url: "ant_saldos", nombre: "Antiguedad de Saldos", bloque: "Auditoría", activo: 1 ).save
    App.new( url: "replicasuc", nombre: "Réplica de las Sucursales", bloque: "Soporte", activo: 1 ).save
    App.new( url: "http://pintacomex.com.mx/replicas/", nombre: "Status de las Réplicas", bloque: "Soporte", activo: 1 ).save
    App.new( url: "calc_objetivos", nombre: "Cálculo de Objetivos", bloque: "Operación", activo: 1 ).save
    App.new( url: "repobjetivos_zona", nombre: "Reporte Objetivos de Venta", bloque: "Operación", activo: 1 ).save
    App.new( url: "signos_vitales_zona", nombre: "Reporte Signos Vitales", bloque: "Operación", activo: 1 ).save
    App.new( url: "estaventas", nombre: "Estadísticas de Ventas", bloque: "Operación", activo: 1 ).save
    App.new( url: "claves_pdv", nombre: "Claves PDV", bloque: "Operación", activo: 1 ).save
    App.new( url: "documentos", nombre: "Documentos", bloque: "Operación", activo: 1 ).save
    App.new( url: "bajas", nombre: "Bajas de Mercancía", bloque: "Auditoría", activo: 1 ).save
    App.new( url: "webservices", nombre: "Webservices", bloque: "Sistemas", activo: 1 ).save
    App.new( url: "stock_sucursales", nombre: "Stock en Sucursales", bloque: "Operación", activo: 1 ).save
    App.new( url: "pdv", nombre: "Punto de Venta", bloque: "Operación", activo: 1 ).save
    App.new( url: "notificaciones/push_tokens", nombre: "Notificaciones", bloque: "General", activo: 1 ).save
    App.new( url: "obras", nombre: "Obras", bloque: "Auditoría", activo: 1 ).save
  end
end

