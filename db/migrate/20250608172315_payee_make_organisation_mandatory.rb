class PayeeMakeOrganisationMandatory < ActiveRecord::Migration[8.0]
  def change
    change_column_null :payees, :organisation, false
  end
end
