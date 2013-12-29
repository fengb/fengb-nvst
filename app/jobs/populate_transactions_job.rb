class PopulateTransactionsJob
  class << self
    def perform
      self.new(objects_needing_processing).run!
    end

    private
    def models_needing_processing
      [].tap do |ret|
        ActiveRecord::Base.connection.tables.each do |table|
          str = table.singularize.camelize
          begin
            klass = Object.const_get(str)
          rescue NameError
            next
          end

          ret << klass if klass.method_defined?(:to_raw_transactions_data)
        end
      end
    end

    def objects_needing_processing
      models_needing_processing.map do |model|
        table = model.table_name
        join_table = model.reflections[:transactions].join_table
        ids = ActiveRecord::Base.connection.select_rows(<<-END).flatten
          SELECT t.id
            FROM #{table} t
            LEFT JOIN #{join_table} jt
                   ON jt.#{table.singularize}_id = t.id
           WHERE jt.id IS NULL
        END
        ids.empty? ? [] : model.find(ids)
      end.flatten
    end
  end

  def initialize(objects)
    @objects = objects.sort_by{|o| [o.date, o.created_at]}
  end

  def run!
    @objects.each do |object|
      next if object.transactions.count > 0

      object.to_raw_transactions_data.each do |transaction_data|
        transactions = transact!(transaction_data)
        object.transactions.concat(transactions)
      end
    end
  end

  def transact!(transaction_data)
    shared_data = transaction_data.slice(:date, :price)
    investment = transaction_data[:investment]
    remaining_shares = transaction_data[:shares]
    transactions = []
    outstanding_lots(investment, remaining_shares).each do |lot|
      if lot.outstanding_shares.abs >= remaining_shares.abs
        transactions << lot.transactions.create!(shared_data.merge shares: remaining_shares)
        return transactions
      else
        remaining_shares += lot.outstanding_shares
        transactions << lot.transactions.create!(shared_data.merge shares: -lot.outstanding_shares)
      end
    end

    # Shares remaining with no lot
    lot = Lot.new(investment: investment)
    transactions << Transaction.create!(shared_data.merge lot: lot, shares: remaining_shares)
    transactions
  end

  def outstanding_lots(investment, new_shares)
    # Shares +new fill -outstanding, -new fill +outstanding
    direction = new_shares > 0 ? '-' : '+'
    Lot.outstanding(direction).where(investment: investment).order_by_purchase do |trans|
      [-trans.price, trans.date, trans.id]
    end
  end
end
