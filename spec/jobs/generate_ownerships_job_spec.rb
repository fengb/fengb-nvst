require 'spec_helper'

describe GenerateOwnershipsJob do
  describe '.classes_needing_processing' do
    it 'includes everything we need' do
      expect(GenerateOwnershipsJob.classes_needing_processing).to include(
        Contribution, Expense, Transfer
      )
    end
  end

  describe '.perform' do
    it 'runs' do
      GenerateOwnershipsJob.classes_needing_processing.each do |model|
        FactoryGirl.create model
      end

      allow(PortfolioPresenter).to receive(:all) { double(value_at: 1, cashflow_at: 0) }

      GenerateOwnershipsJob.perform
    end
  end
end
