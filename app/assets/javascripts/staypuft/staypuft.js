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
      tr.toggleClass("danger", !this.checked);
    }
  });
});
