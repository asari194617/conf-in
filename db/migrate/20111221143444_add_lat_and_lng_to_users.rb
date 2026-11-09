class AddLatAndLngToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :lat, :float
    add_column :users, :lng, :float
  end
end
