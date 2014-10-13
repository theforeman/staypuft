var new_subnet = (function() {
  $('#staypuft_simple_subnet_dhcp_server').on('change', function(event) {
    if($(event.target).find(":selected").val() == 'none') {
      $('#no_existing_dhcp_fields').show();
    } else {
      $('#no_existing_dhcp_fields').hide();
    }
  });
});
