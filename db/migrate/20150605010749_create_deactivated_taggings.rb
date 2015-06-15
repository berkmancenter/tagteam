class CreateDeactivatedTaggings < ActiveRecord::Migration
  def change
    create_table :deactivated_taggings do |t|
      t.references :tag

      # You should make sure that the column created is
      # long enough to store the required class names.
      t.references :taggable, :polymorphic => true
      t.references :tagger, :polymorphic => true
      t.references :deactivator, :polymorphic => true

      t.string :context

      t.datetime :created_at
    end

    add_index :deactivated_taggings, [:taggable_id, :taggable_type, :context],
      name: 'd_taggings_type_idx'
    add_index :deactivated_taggings, [:taggable_type, :context]
    add_index :deactivated_taggings, [:tag_id, :taggable_id, :taggable_type,
                          :context, :tagger_id, :tagger_type],
                            unique: true, name: 'd_taggings_idx'
    add_index :deactivated_taggings, [:deactivator_id, :deactivator_type],
      name: 'd_taggings_deactivator_idx'
  end
end
