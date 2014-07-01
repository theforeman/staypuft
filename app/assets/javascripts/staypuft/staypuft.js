// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require_tree .

$(function () {
  // Check all checkboxes in table
  $('#check_all').on('change', function (e) {
    var table = $(e.target).closest('table');
    $('td input:checkbox', table).attr('checked', e.target.checked);
    $('td input:checkbox', table).closest("tr").toggleClass("info", this.checked);
  });

  $("tr.checkbox_highlight input:checkbox").on('change', function (e) {
    var tr = $(this).closest("tr");
    tr.toggleClass("info", this.checked);
    if (tr.hasClass("deployed")) {
      tr.toggleClass("danger", this.checked);
    }
  });

  // Workaround to properly activate and deactivate tabs in tabbed_side_nav_table
  // Should be probably done properly by extending Bootstrap Tab
  $(".tabbed_side_nav_table").on('click.bs.tab.data-api', '[data-toggle="tab"], [data-toggle="pill"]', function (e) {
    e.preventDefault();
    $(this).closest('ul').find('.activated').removeClass('activated');
    $(this).addClass("activated");
    $(this).closest('li').addClass('activated');
  });

  $('.tabbed_side_nav_table').on('click', 'button.close', function() {
    $(this).closest('.tab-pane.active').removeClass('active');
    $(this).closest('.tabbed_side_nav_table').find('.activated').removeClass('activated');
  })

  showPasswords();
  $("input[name='staypuft_deployment[passwords][mode]']").change(showPasswords);
  function showPasswords() {
    if ($('#staypuft_deployment_passwords_mode_single').is(":checked")) {
      $('.single_password').show();
    }
    else {
      $('.single_password').hide();
    }
  }

  if($('.configuration').length > 0){
    $('.configuration').find('li').first().find('a')[0].click();
  }

});
