$(function() {
  $("div.subnet-type-pull").draggable({
    revert: 'invalid'
  });

  $("div.subnet-drop-zone").droppable({
    activeClass: "ui-state-default",
    hoverClass: "ui-state-hover",
    accept: "div.subnet-type-pull",
    drop: function(event, ui) {
      if(ui.draggable.hasClass('new')) {
        $.ajax({
          type: 'POST',
          url: ui.draggable.data('create-url'),
          data: 'subnet_type_id=' + ui.draggable.data('subnet-type-id') + '&subnet_id=' + $(this).data('subnet-id'),
          dataType: 'script'
        })
      } else {
        $.ajax({
          type: 'PUT',
          url: ui.draggable.data('update-url'),
          data: 'subnet_id=' + $(this).data('subnet-id'),
          dataType: 'script'
        })
      }
    }
  });
  $("#subnet_types").droppable({
    activeClass: "ui-state-default",
    hoverClass: "ui-state-hover",
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
