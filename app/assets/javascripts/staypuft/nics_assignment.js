$(function() {
  $("div.subnet-pull.active").draggable({
    revert: 'invalid'
  });

  $("div.interface").droppable({
    activeClass: "ui-state-default",
    hoverClass: "ui-state-hover",
    accept: "div.subnet-pull",
    drop: function(event, ui) {
      $.ajax({
        type: 'POST',
        url: ui.draggable.data('create-url'),
        data: 'interface=' + $(this).data('interface'),
        dataType: 'script'
      });
    }
  });
  $("#subnets").droppable({
    activeClass: "ui-state-default",
    hoverClass: "ui-state-hover",
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
