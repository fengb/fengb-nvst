class Transfer < ActiveRecord::Base
  include GenerateOwnerships
  include Scopes::Year

  belongs_to :from_user, class_name: 'User'
  has_and_belongs_to_many :ownerships

  def from_ownership
    ownerships.find_by('units < 0')
  end

  def to_ownership
    ownerships.find_by('units > 0')
  end

  def raw_ownerships_data
    [{user: from_user,
      date: date,
      units: -effective_units},
     {user: User.fee_collector,
      date: date,
      units: effective_units}
    ]
  end

  def effective_units
    amount * Ownership.new_unit_per_amount_multiplier_at(date)
  end
end