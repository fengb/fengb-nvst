class Event < ActiveRecord::Base
  extend Enumerize
  include GenerateTransactions

  belongs_to :src_investment, class_name: 'Investment'
  has_and_belongs_to_many :transactions

  enumerize :category, in: {'interest'                   => 'int',
                            'tax'                        => 'tax',
                            'dividend - ordinary'        => 'dvo',
                            'dividend - qualified'       => 'dvq',
                            'dividend - tax-exempt'      => 'dve',
                            'capital gains - short-term' => 'cgs',
                            'capital gains - long-term'  => 'cgl'}

  scope :year, ->(year){where('EXTRACT(year FROM date) = ?', year)}

  def to_raw_transactions_data
    [{investment: Investment.cash,
      date:       date,
      shares:     amount,
      price:      1}]
  end
end
