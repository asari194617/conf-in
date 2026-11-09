class AddTwitterInfoToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :tw_uid, :integer
    add_column :users, :tw_name, :string
    add_column :users, :tw_token, :string
    add_column :users, :tw_secret, :string
  end
end
