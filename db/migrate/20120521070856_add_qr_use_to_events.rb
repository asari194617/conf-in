class AddQrUseToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :qr_use, :boolean

  end
end
