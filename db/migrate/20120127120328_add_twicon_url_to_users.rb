class AddTwiconUrlToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :twicon_url, :string
  end
end
