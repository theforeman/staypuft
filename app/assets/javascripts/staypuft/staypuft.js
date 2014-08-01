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
  $("input[name='staypuft_deployment[cinder][driver_backend]']").change(showCinderNfsUri);
  function showCinderNfsUri() {
    if ($('#staypuft_deployment_cinder_driver_backend_nfs').is(":checked")) {
      $('.cinder_nfs_uri').show();
    }
    else {
      $('.cinder_nfs_uri').hide();
    }
  }

  showCinderEquallogic();
  $("input[name='staypuft_deployment[cinder][driver_backend]']").change(showCinderEquallogic);
  function showCinderEquallogic() {
    if ($('#staypuft_deployment_cinder_driver_backend_equallogic').is(":checked")) {
      $('.cinder_equallogic').show();
    }
    else {
      $('.cinder_equallogic').hide();
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
  })

});
