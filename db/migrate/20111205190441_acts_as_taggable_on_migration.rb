class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name
    end

    add_index :tags, :name

    # Postgres only.
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute 'CREATE INDEX "lower_name_index" on tags (lower(name))'
    end

    create_table :taggings do |t|
      t.references :tag

      # You should make sure that the column created is
      # long enough to store the required class names.
      t.references :taggable, :polymorphic => true
      t.references :tagger, :polymorphic => true

      t.string :context

      t.datetime :created_at
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
    # TODO Probably need some additional indexes here.tables

  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
