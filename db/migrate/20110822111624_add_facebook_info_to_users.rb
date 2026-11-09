class AddFacebookInfoToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :fb_token, :string
  end
end
