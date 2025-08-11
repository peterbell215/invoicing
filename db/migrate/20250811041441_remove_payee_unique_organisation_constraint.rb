class RemovePayeeUniqueOrganisationConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the unique constraint on the payees table for the organisation_id column
    remove_index :payees, :organisation

    # Add a non-unique index on the organisation_id column
    add_index :payees, :organisation
  end
end
