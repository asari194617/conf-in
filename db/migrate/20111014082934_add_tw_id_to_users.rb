class AddTwIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :tw_id, :string
  end
end
