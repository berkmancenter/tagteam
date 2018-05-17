class AddRequireAdminApprovalToSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_settings, :require_admin_approval_for_all, :boolean, nil: false, default: true, after: :signup_description
  end
end
