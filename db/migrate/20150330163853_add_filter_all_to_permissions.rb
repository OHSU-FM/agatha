class AddFilterAllToPermissions < ActiveRecord::Migration
    def up
      add_column :user_externals, :filter_all, :boolean, :default => false
    end

    def down
      remove_column :user_externals, :filter_all
    end
end
