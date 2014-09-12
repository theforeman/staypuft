var nics_assignment = (function() {
  var dropped = null;
  $("div.subnet-pull.active").draggable({
    start: function( event, ui ) {
      dropped = $(this);
      dropped.data.left = ui.originalPosition.left;
      dropped.data.top = ui.originalPosition.top;
    },
    revert: 'invalid'
  });

  $("div.interface").droppable({
    activeClass: "panel-droppable",
    hoverClass: "panel-success",
    accept: "div.subnet-pull",
    drop: function(event, ui) {
      dropped = $(ui.draggable);
      $.ajax({
        type: 'POST',
        url: dropped.data('create-url'),
        data: 'interface=' + $(this).data('interface'),
        dataType: 'script',
        success: function(data, event){
          if(data.indexOf("error =") > -1){
            dropped.animate({
              left: dropped.data.left,
              top: dropped.data.top
            }, 1000, 'swing');
          }
        }
      });
    }
  });
  $("#subnets").droppable({
    activeClass: "panel-droppable",
    hoverClass: "panel-success",
    accept: "div.subnet-pull.existing",
    drop: function(event, ui) {
      $.ajax({
        type: 'DELETE',
        url: ui.draggable.data('delete-url'),
        data: 'interface=' + ui.draggable.closest('div.interface').data('interface'),
        dataType: 'script'
      });
    }
  });
});
