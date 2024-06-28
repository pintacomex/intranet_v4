ActiveAdmin.register Permiso do
  menu :priority => 8

  index do    
    column :idUsuario
    column "Usuario" do |m|
      name = User.find(m.idUsuario).name rescue ""
    end
    column :permiso
    column :p1
    column :p2                     
    column :p3                     
    column :p4                     
    actions  
  end  

  filter :idUsuario
  filter :permiso

  form do |f|
    f.inputs "Detalles Permiso" do
      # f.input :idUsuario
      f.input :idUsuario, as: :select, collection: User.order(:id).collect{ |c| ["#{c.id} - #{c.name}", c.id] }
      # f.input :permiso
      f.input :permiso, as: :select, collection: CatRole.order(:nivel).collect{ |c| [c.nomPermiso, c.nomPermiso] }
      f.input :p1
      f.input :p2
      f.input :p3
      f.input :p4
    end
    f.actions
  end

end