function find_network_interface_field(fieldset, field, html_input_type) {
  label = fieldset.find("label[for='" + field + "']");
  html_input = label.parent().find(html_input_type);

  return html_input;
};


$(document).ready(function() {
  update_fencing_form();
  // NOTE: setTimeout is required to make sure this code runs after all event
  //       handlers are set, so they can be overridden.
  setTimeout(function() {
    override_ajax_submit();
  }, 1);
});

function override_ajax_submit() {
  // NOTE: method defined in app/assets/javascripts/host_edit.js but modified
  //       so the URL points to staypuft/hosts controller.
  function submit_host(){
    var url = window.location.pathname.replace(/\/edit$|\/new$/,'');
    url = url.replace(/\/hosts/,'\/staypuft/hosts')
    if(/\/clone$/.test(window.location.pathname)){ url = foreman_url('/staypuft/hosts'); }
    $('#host_submit').attr('disabled', true);
    stop_pooling = false;
    $("body").css("cursor", "progress");
    clear_errors();
    animate_progress();

    $.ajax({
      type:'POST',
      url: url,
      data: $('form').serialize(),
      success: function(response){
        if(response.redirect){
          window.location.replace(response.redirect);
        }
        else{
          $("#host-progress").hide();
          $('#content').replaceWith($("#content", response));
          $(document.body).trigger('ContentLoad');
          if($("[data-history-url]").exists()){
              history.pushState({}, "Host show", $("[data-history-url]").data('history-url'));
          }
        }
      },
      error: function(response){
        $('#content').html(response.responseText);
      },
      complete: function(){
        stop_pooling = true;
        $("body").css("cursor", "auto");
        $('#host_submit').attr('disabled', false);
      }
    });
    return false;
  }

  $(document).off('submit').on('submit',"[data-submit='progress_bar']", function() {
    submit_host();
    return false;
  });
};


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
  $('#host_fencing_attrs_fence_ipmilan_address').val(ip);
  username = find_network_interface_field(bmc_fieldset, 'username', 'input').val();
  $('#host_fencing_attrs_fence_ipmilan_username').val(username);
  password = find_network_interface_field(bmc_fieldset, 'password', 'input').val();
  $('#host_fencing_attrs_fence_ipmilan_password').val(password);
};

function disable_fencing_form() {
  $('#fencing_form').hide();
  $('#fencing_disabled_notice').show();
};

function enable_fencing_form() {
  $('#fencing_disabled_notice').hide();
  $('#fencing_form').show();
};


$(document).on('change', '#fencing', function() { update_bmc_interface_form(); });
function update_bmc_interface_form() {
  bmc_fieldset = get_bmc_interface_form();
  selected_provider = find_network_interface_field(bmc_fieldset, 'provider', 'select');

  ip = $('#host_fencing_attrs_fence_ipmilan_address').val();
  find_network_interface_field(bmc_fieldset, 'ip', 'input').val(ip);
  username = $('#host_fencing_attrs_fence_ipmilan_username').val();
  find_network_interface_field(bmc_fieldset, 'username', 'input').val(username);
  password = $('#host_fencing_attrs_fence_ipmilan_password').val();
  find_network_interface_field(bmc_fieldset, 'password', 'input').val(password);
};

function get_bmc_interface_form() {
  return $('fieldset#interface').filter(function(index, fieldset){
    type = find_network_interface_field($(fieldset), 'type', 'select');
    return type.val() == 'Nic::BMC';
  });
};


$(document).ready(function() {
  $('fieldset#interface').each(function(idx, fieldset) {
    update_subnet_types(fieldset);
  });
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
};