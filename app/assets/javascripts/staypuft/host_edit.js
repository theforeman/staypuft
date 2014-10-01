$(function() {
  function find_network_interface_field(fieldset, field, html_input_type) {
    label = fieldset.find("label[for='" + field + "']");
    html_input = label.parent().find(html_input_type);

    return html_input;
  }


  function get_bmc_interface_form() {
    return $('fieldset#interface').filter(function(index, fieldset){
      type = find_network_interface_field($(fieldset), 'type', 'select');
      return type.val() == 'Nic::BMC';
    });
  }

  update_fencing_form();
  $(document).on('change', 'fieldset#interface', function() { update_fencing_form(); });
  function update_fencing_form() {
    bmc_fieldset = get_bmc_interface_form();
    if (bmc_fieldset.length == 0) {
      disable_fencing_form();
      return;
    } else {
      enable_fencing_form();
    }

    selected_provider = find_network_interface_field(bmc_fieldset, 'provider', 'select');

    ip = find_network_interface_field(bmc_fieldset, 'ip', 'input').val();
    $('#host_fencing_fence_ipmilan_address').val(ip);
    username = find_network_interface_field(bmc_fieldset, 'username', 'input').val();
    $('#host_fencing_fence_ipmilan_username').val(username);
    password = find_network_interface_field(bmc_fieldset, 'password', 'input').val();
    $('#host_fencing_fence_ipmilan_password').val(password);
  }

  $(document).on('click', 'fieldset#interface a.remove_nested_fields', function() { check_existence_of_bmc_interface(); });
  function check_existence_of_bmc_interface() {
    visible_bmc_forms = $.grep(get_bmc_interface_form(), function(fieldset) {
      // NOTE: The second part of the condition is necessary because Foreman
      //       inserts the form to the DOM tree incorrectly after the second
      //       time
      return $(fieldset).parent().is(':visible') && $(fieldset).find(':first').is(':visible');
    });

    if(visible_bmc_forms.length == 0) {
      disable_fencing_form();
    }
  }

  function disable_fencing_form() {
    $('#fencing_form').hide();
    $('#fencing_disabled_notice').show();
  }

  function enable_fencing_form() {
    $('#fencing_disabled_notice').hide();
    $('#fencing_form').show();
  }


  $(document).on('change', '#fencing', function() { update_bmc_interface_form(); });
  function update_bmc_interface_form() {
    bmc_fieldset = get_bmc_interface_form();
    selected_provider = find_network_interface_field(bmc_fieldset, 'provider', 'select');

    ip = $('#host_fencing_fence_ipmilan_address').val();
    find_network_interface_field(bmc_fieldset, 'ip', 'input').val(ip);
    username = $('#host_fencing_fence_ipmilan_username').val();
    find_network_interface_field(bmc_fieldset, 'username', 'input').val(username);
    password = $('#host_fencing_fence_ipmilan_password').val();
    find_network_interface_field(bmc_fieldset, 'password', 'input').val(password);
  }


  $('fieldset#interface').each(function(idx, fieldset) {
    update_subnet_types(fieldset);
  });
  $(document).on('change', 'fieldset#interface select.interface_subnet', function(event) {
    fieldset = $(event.target).parents('fieldset#interface');
    update_subnet_types(fieldset);
  });
  function update_subnet_types(fieldset) {
    subnet_select = find_network_interface_field($(fieldset), 'subnet_id', 'select');
    subnet_types = subnet_select.data('types');
    help_message = subnet_types[subnet_select.val()];

    if (!help_message || help_message == '') {
      subnet_select.parent().next().empty();
      return;
    }

    subnet_select.parent().next().empty().append(
      '<div><i class="glyphicon glyphicon-info-sign" /> ' + help_message + '</div>');
  }
});