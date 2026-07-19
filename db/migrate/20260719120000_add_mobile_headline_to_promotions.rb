class AddMobileHeadlineToPromotions < ActiveRecord::Migration[8.0]
  def change
    add_column :promotions, :mobile_headline, :string
  end
end
