ActiveAdmin.register ChecklistItem do
  menu :priority => 21

  config.sort_order = 'checklist_id, orden, id'

  index do                            
    column "Checklist" do |m|
      name = Checklist.find(m.checklist_id).nombre rescue ""
    end    
    column :texto
    column :orden
    column :status do |ss|
      Checklist::STATUS.select{|k,v| v == ss.status }.keys[0] rescue "No encontrado"
    end
    actions  
  end  

  form do |f|
    f.inputs "Catalogo de Checklist Items" do
      f.input :checklist_id, as: :select, collection: Checklist.order(:id).collect{ |c| ["#{c.nombre}", c.id] }, include_blank: false
      f.input :texto
      f.input :orden
      f.input :status, as: :select, collection: Checklist::STATUS, include_blank: false
    end
    f.actions
  end

end