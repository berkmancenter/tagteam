$(document).ready(function() {
  if($('#admin_setting_require_admin_approval_for_all').size()) {
    var $checkbox = $('#admin_setting_require_admin_approval_for_all');
    $('div.domains input').attr('readonly', $checkbox.prop('checked'));
    $checkbox.change(function(e) {
      $('div.domains').toggleClass('disabled', $checkbox.prop('checked'));
      $('div.domains input').attr('readonly', $checkbox.prop('checked'));
    });
  }
});
