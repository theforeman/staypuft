$(function() {
  $("div.subnet-type-pull").draggable({
    start: function( event, ui ) {
      dropped = $(this);
      dropped.data.left = ui.originalPosition.left;
      dropped.data.top = ui.originalPosition.top;
    },
    revert: 'invalid'
  });

  $("div.subnet-drop-zone").droppable({
    activeClass: "panel-droppable",
    hoverClass: "panel-success",
    accept: "div.subnet-type-pull",
    drop: function(event, ui) {
      if(ui.draggable.hasClass('new')) {
        $.ajax({
          type: 'POST',
          url: ui.draggable.data('create-url'),
          data: 'subnet_type_id=' + ui.draggable.data('subnet-type-id') + '&subnet_id=' + $(this).data('subnet-id'),
          dataType: 'script',
          success: function(data, event){
            if(data.indexOf("error =") > -1){
              dropped.animate({
                left: dropped.data.left,
                top: dropped.data.top
              }, 1000, 'swing');
            }
          }          
        })
      } else {
        $.ajax({
          type: 'PUT',
          url: ui.draggable.data('update-url'),
          data: 'subnet_id=' + $(this).data('subnet-id'),
          dataType: 'script',
          success: function(data, event){
            if(data.indexOf("error =") > -1){
              dropped.animate({
                left: dropped.data.left,
                top: dropped.data.top
              }, 1000, 'swing');
            }
          }          
        })
      }
    }
  });
  $("#subnet_types").droppable({
    activeClass: "panel-droppable",
    hoverClass: "panel-success",
    accept: "div.subnet-type-pull",
    accept: "div.subnet-type-pull.existing",
    drop: function(event, ui) {
      $.ajax({
        type: 'DELETE',
        url: ui.draggable.data('delete-url'),
        dataType: 'script'
      });
    }
  });
});
