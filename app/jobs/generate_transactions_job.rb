class GenerateTransactionsJob
  class << self
    def perform
      objects_needing_processing.each do |o|
        o.generate_transactions!
      end
    end

    def all_models
      RailsUtil.all(:models).select{|m| m.method_defined?(:generate_transactions!)}
    end

    def objects_needing_processing
      all_models.map(&:all).flatten.sort_by do |o|
        [o.date, priority(o), o.try(:created_at) || Date.today]
      end
    end

    def priority(obj)
      case obj.class
        when InvestmentSplit then -100
        when Contribution    then  -10
        else                         0
      end
    end
  end
end
