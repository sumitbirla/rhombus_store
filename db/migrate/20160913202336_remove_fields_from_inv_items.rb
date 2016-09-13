class RemoveFieldsFromInvItems < ActiveRecord::Migration
  def change
    remove_column :inv_items, :inventoriable_type, :string
    remove_column :inv_items, :inventoriable_id, :integer
  end
end
