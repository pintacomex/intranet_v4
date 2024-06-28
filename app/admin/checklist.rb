ActiveAdmin.register Checklist do
  menu :priority => 20

  index do                            
    column :id
    column :nombre
    column :status do |ss|
      Checklist::STATUS.select{|k,v| v == ss.status }.keys[0] rescue "No encontrado"
    end
    actions  
  end  

  filter :nombre

  form do |f|
    f.inputs "Catalogo de Checklists" do
      f.input :nombre
      f.input :status, as: :select, collection: Checklist::STATUS, include_blank: false
    end
    f.actions
  end

end