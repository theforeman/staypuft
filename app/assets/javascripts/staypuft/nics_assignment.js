var nics_assignment = (function() {
  var dropped = null;
  $("div.subnet-pull.active").draggable({
    start: function( event, ui ) {
      dropped = $(this);
      dropped.data.left = ui.originalPosition.left;
      dropped.data.top = ui.originalPosition.top;
    },
    helper: 'clone',
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

  $('#hosts_to_configure').on('show.bs.collapse', function() {
    $(this).prev('h3[data-toggle="collapse"]').addClass('active');
  });
  $('#hosts_to_configure').on('hide.bs.collapse', function() {
    $(this).prev('h3[data-toggle="collapse"]').removeClass('active');
  });

  $('.panel-heading > #bonding_mode > ul > li').on('click', function(event) {
    var dropdown = $($(event.target).parents('ul')[0]).prev();
    dropdown.prop('disabled', true);

    var to_assign = $('input:checkbox[name=host_ids[]]:checked').map(
      function() {
        return $(this).attr('value');
      }).get().join();
    /* remove the first if it's the select all */
    if(to_assign.substr(0, 2) == 'on') {
      to_assign = to_assign.substr(3);
    }

    var to_path = $('#bonding_mode').data('path');
    $.ajax({
      url: to_path,
      type: 'PUT',
      data: {
        mode: $(event.target).text(),
        host_ids: to_assign
      },
      success: function(data) {
        dropdown.text($(event.target).text());
        dropdown.prop('disabled', false);
      }
    });
  });
});
