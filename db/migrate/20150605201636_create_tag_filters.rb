class CreateTagFilters < ActiveRecord::Migration
  def up
    create_table :tag_filters do |t|
      t.references :hub, null: false
      t.references :tag, null: false
      t.references :new_tag
      t.references :scope, polymorphic: true

      t.boolean :applied, default: false
      t.string :type
      t.timestamps
    end
    add_index :tag_filters, :hub_id
    add_index :tag_filters, :tag_id
    add_index :tag_filters, :new_tag_id
    add_index :tag_filters, [:scope_type, :scope_id]
    add_index :tag_filters, :type
  end

  def down
    drop_table :tag_filters
  end
end
