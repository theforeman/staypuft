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
//= require jquery.ui.draggable
//= require jquery.ui.droppable

$(function () {
  // Check all checkboxes in table
  $('.check_all').on('change', function (e) {
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
  });

  $('#hidden_password_toggle').click(function(e) {
    e.preventDefault();
    $(this).children('.glyphicon-eye-open, .glyphicon-eye-close').toggleClass('hide');
    $(this).siblings('.hidden_password, .shown_password').toggleClass('hide');
  });

  $('#ceph_notification_dismissal').click(function(e) {
    e.preventDefault();
    $('.ceph_notification').toggleClass('hide');
    var pathname = window.location.pathname
    var id = pathname.substring(pathname.lastIndexOf('/') + 1)
    var cephDeploymentNotification = readFromCookie();
    cephDeploymentNotification[id] = true
    $.cookie('ceph-deployment-notification', JSON.stringify(cephDeploymentNotification))
  });
  function readFromCookie() {
    if (r = $.cookie('ceph-deployment-notification'))
      return $.parseJSON(r);
    else
      return {};
  }

  var duration = 150;

  showPasswords();
  $("input[name='staypuft_deployment[passwords][mode]']").change(showPasswords);
  function showPasswords() {
    if ($('#staypuft_deployment_passwords_mode_single').is(":checked")) {
      $('.single_password').fadeIn(duration);
    }
    else {
      $('.single_password').fadeOut(duration)
    }
  }

  showNovaVlanRange();
  $("input[name='staypuft_deployment[nova][network_manager]']").change(showNovaVlanRange);
  function showNovaVlanRange() {
    if ($('#staypuft_deployment_nova_network_manager_vlanmanager').is(":checked")) {
      $('.nova_vlan_range').fadeIn(duration);
    }
    else {
      $('.nova_vlan_range').fadeOut(duration)
    }
  }

  showNeutronVlanRange();
  $("input[name='staypuft_deployment[neutron][network_segmentation]']").change(showNeutronVlanRange);
  function showNeutronVlanRange() {
    if ($('#staypuft_deployment_neutron_network_segmentation_vlan').is(":checked")) {
      $('.neutron_tenant_vlan_ranges').fadeIn(duration);
    }
    else {
      $('.neutron_tenant_vlan_ranges').fadeOut(duration)
    }
  }

  showNeutronExternalInterface();
  $("input[name='staypuft_deployment[neutron][use_external_interface]']").change(showNeutronExternalInterface);
  function showNeutronExternalInterface() {
    if ($('#staypuft_deployment_neutron_use_external_interface').is(":checked")) {
      $('.neutron_external_interface').fadeIn(duration);
    }
    else {
      $('.neutron_external_interface').fadeOut(duration)
    }
  }

  showGlanceNfsNetworkPath();
  $("input[name='staypuft_deployment[glance][driver_backend]']").change(showGlanceNfsNetworkPath);
  function showGlanceNfsNetworkPath() {
    if ($('#staypuft_deployment_glance_driver_backend_nfs').is(":checked")) {
      $('.glance_nfs_network_path').show();
    }
    else {
      $('.glance_nfs_network_path').hide();
    }
  }

  showCinderNfsUri();
  $("#staypuft_deployment_cinder_backend_nfs").change(showCinderNfsUri);
  function showCinderNfsUri() {
    if ($('#staypuft_deployment_cinder_backend_nfs').is(":checked")) {
      $('.cinder_nfs_uri').show();
    }
    else {
      $('.cinder_nfs_uri').hide();
    }
  }

  showCinderEquallogic();
  $("#staypuft_deployment_cinder_backend_eqlx").change(showCinderEquallogic);
  function showCinderEquallogic() {
    if ($('#staypuft_deployment_cinder_backend_eqlx').is(":checked")) {
      $('.cinder_equallogic').show();
      if($('#eqlxs').children().length == 0) {
        $('.add_another_server').click();
      }
    }
    else {
      $('.cinder_equallogic').hide();
    }
  }

  showNeutronMl2CiscoNexus();
  $("#staypuft_deployment_neutron_ml2_cisco_nexus").change(showNeutronMl2CiscoNexus);
  function showNeutronMl2CiscoNexus() {
    if ($('#staypuft_deployment_neutron_ml2_cisco_nexus').is(":checked")) {
      $('.neutron_cisco_nexus').show();
      if($('#nexuses').children().length == 0) {
        $('.add_another_switch').click();
      }
    }
    else {
      $('.neutron_cisco_nexus').hide();
    }
  }

  showCephNotification();
  function showCephNotification() {
    var cephDeploymentNotification = readFromCookie();
    var pathname = window.location.pathname;
    var id = pathname.substring(pathname.lastIndexOf('/') + 1);
    if (cephDeploymentNotification !== null && cephDeploymentNotification !== undefined) {
      if (cephDeploymentNotification[id]) {
        $('.ceph_notification').addClass('hide');
      }
    }
  }

  if ($('.configuration').length > 0) {
    $('.configuration').find('li').first().find('a')[0].click();
  }

  // add a hash to the URL when the user clicks on a tab
  $('a[data-toggle="tab"]').on('click', function(e) {
    if(!$(this).hasClass("sub-tab")){
      history.pushState(null, null, $(this).attr('href'));
    }
  });
  // navigate to a tab when the history changes
  window.addEventListener("popstate", function(e) {
    var activeTab = $('[href=' + location.hash + ']');
    if (activeTab.length) {
      activeTab.tab('show');
    } else {
      $('.nav-tabs a:first').tab('show');
    }
  });

  // Javascript to enable link to tab
  var hash = document.location.hash;
  var prefix = "tab_";
  if (hash) {
      $('.nav-tabs a[href='+hash.replace(prefix,"")+']').tab('show');
  }

  // Change hash for page-reload
  $('.nav-tabs a').on('shown', function (e) {
      window.location.hash = e.target.hash.replace("#", "#" + prefix);
  });

  $('#edit_staypuft_deployment_submit').click(function (e) {
    $('#edit_staypuft_deployment').submit();
    e.preventDefault();
  });


  $('#deploy_modal').on('shown.bs.modal', function(e) {
    $('#sub-navigation a[href="#overview"]').tab('show');
    window.location.hash = "#overview";
  });

  $('#role_modal').on('shown.bs.modal', function(e) {
    $('#sub-navigation a[href="#hosts"]').tab('show');
    $('#hosts-navigation a[href="#free-hosts"]').tab('show');
    window.location.hash = "#hosts";
  });

  $('#configure_networks_modal').on('shown.bs.modal', function(e) {
    var height = $(window).height() - 200;
    $(this).find(".modal-body").css("max-height", height);
    var to_assign = $("input:checkbox[name=host_ids[]]:checked").map(
      function() {
        return $(this).attr('value');
      }).get().join();
    /* remove the first if it's the select all */
    if(to_assign.substr(0,2) == 'on') {
      to_assign = to_assign.substr(3);
    }
    var to_path = $('#configure_networks_modal').data('path');
    $.ajax({
        url: to_path,
        type: "GET",
        //Pass in each variable as a parameter.
        data: {
          host_ids: to_assign
        },
        success: function(data){
          $('#interfaces').html(data).promise().done(function(){
            nics_assignment();
          });
        }
    });
  });

  var scrolled = false;

  $(window).scroll(function(){
    scrolled = true;
  });

  if ( window.location.hash && scrolled ) {
    $(window).scrollTop( 0 );
  }

  $('.dynamic-submit').click(function() {
    this.form.action = $(this).data('submit-to');
    this.form.method = $(this).data('method');
    this.form.submit();
    return false;
  })

  var free_host_checkboxes = $('#free-hosts table input:checkbox');
  free_host_checkboxes.click(function(){
    $("#assign_hosts_modal").attr("disabled", !free_host_checkboxes.is(":checked"));
  });

  var assigned_host_checkboxes = $('#assigned-hosts table input:checkbox');
  assigned_host_checkboxes.click(function(){
    $("#unassign_hosts_button").attr("disabled", !assigned_host_checkboxes.is(":checked"));
    $("#configure_networks_button").attr("disabled", !assigned_host_checkboxes.is(":checked"));
  });

  var deployed_host_checkboxes = $('#deployed-hosts table input:checkbox');
  deployed_host_checkboxes.click(function(){
    $("#undeploy_hosts_modal").attr("disabled", !deployed_host_checkboxes.is(":checked"));
  });

  var hosts_filter = $('.hosts_filter');
  hosts_filter.keyup(function () {
      var rex = new RegExp($(this).val(), 'i');
      $('.searchable tr').hide();
      $('.searchable tr').filter(function () {
          return rex.test($(this).text());
      }).show();
  });

  /* clear filter if switching */
  $('.inner-nav').click(function(){ hosts_filter.val("").keyup(); });

// add more highlighting for tabs with errors
  $(".tab-content").find(".form-group.has-error").each(function(index) {
    var id = $(this).parentsUntil(".tab-content").last().attr("id");
    $("a[href=#"+id+"]").parent().addClass("tab-error");
  })

  $("button.add_another_server").live("click", function() {
    var eqlx_form = function () {
      return $('#eqlx_form_template').text().replace(/NEW_RECORD/g, new Date().getTime());
    }
    $('#eqlxs').append(eqlx_form());
    if($('#eqlxs').children().length > 1) {
      var added_form_span = $('#eqlxs').children().last().find('h5').find('.server_number');
      var previous_span_number = $('#eqlxs').children().eq(-2).find('h5').find('.server_number');
      added_form_span.html(parseInt(previous_span_number.html(), 10) + 1);
    }
  })

  $("button.add_another_switch").live("click", function() {
    var nexus_form = function() {
      return $('#nexus_form_template').text().replace(/NEW_RECORD/g, new Date().getTime());
    }
    $('#nexuses').append(nexus_form());
    if($('#nexuses').children().length > 1) {
      var added_form_span = $('#nexuses').children().last().find('h5').find('.switch_number');
      var previous_span_number = $('#nexuses').children().eq(-2).find('h5').find('.switch_number');
      added_form_span.html(parseInt(previous_span_number.html(), 10) + 1);
    }
  })

  function remove_element_on_click(element_name) {
    $(element_name + " h5 a.remove").live("click", function(){
      $(this).parent().parent().remove();
    });
  }

  remove_element_on_click('.eqlx');
  remove_element_on_click('.nexus');
});
