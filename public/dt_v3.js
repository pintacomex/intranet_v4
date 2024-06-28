$(document).ready(function() {
  $('#example').dataTable({
    "bPaginate": false,
    "aaSorting": [],
    "oLanguage": {
      "sLengthMenu": "_MENU_ registros por página / records per page",
      "sSearch": "Buscar",
      "sInfo": "_START_ - _END_ de _TOTAL_",
      "sInfoFiltered": "",
      "sZeroRecords": "No se encontraron registros",
      "sInfoEmpty": "0 - 0 de 0 registros",
      "oPaginate": {
            "sNext": "",
            "sPrevious": ""
          }
    },
    "aoColumnDefs" : [ {
        "bSortable" : false,
        "aTargets" : [ "no-sort" ]
    } ]
  });
} );
