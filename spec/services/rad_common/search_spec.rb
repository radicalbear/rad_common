require 'rails_helper'

RSpec.describe RadCommon::Search, type: :service do
  let(:user) { create(:user) }

  describe 'results' do
    subject(:search) do
      described_class.new(query: query,
                          filters: filters,
                          current_user: user,
                          search_name: 'divisions_search',
                          params: params).results
    end

    let!(:division) { create :division }

    context 'when using a like filter' do
      let!(:role_1) { create(:security_role, name: 'foo') }
      let!(:role_2) { create(:security_role, name: 'bar') }
      let(:query) { SecurityRole }
      let(:filters) { [{ column: :name, type: RadCommon::LikeFilter }] }
      let(:params) { ActionController::Parameters.new(search: { name_like: 'foo' }) }

      it 'filters results' do
        expect(search).to include role_1
        expect(search).not_to include role_2
      end
    end

    context 'when using a date filter' do
      let(:query) { User.joins(:security_roles) }
      let(:user_1) { create :user, confirmed_at: 2.days.ago }
      let(:user_2) { create :user, confirmed_at: 3.days.from_now }
      let!(:user_3) { create :user, confirmed_at: DateTime.current.end_of_day }
      let!(:user_4) { create :user, confirmed_at: 2.days.ago, security_roles: [] }
      let(:filters) { [{ column: :confirmed_at, type: RadCommon::DateFilter }] }
      let(:params) do
        ActionController::Parameters.new(search: { confirmed_at_start: 3.days.ago.strftime('%Y-%m-%d'),
                                                   confirmed_at_end: DateTime.current.strftime('%Y-%m-%d') })
      end

      it 'filters results' do
        expect(search).to include user_1
        expect(search).to include user_3
        expect(search).not_to include user_4
        expect(search).not_to include user_2
      end
    end

    context 'when using a select filter' do
      let(:query) { User }
      let(:user_active) { create :user, user_status: UserStatus.default_active_status }
      let(:user_pending) { create :user, user_status: UserStatus.default_pending_status }
      let(:filters) { [{ column: :user_status_id, options: UserStatus.by_id }] }
      let(:params) { ActionController::Parameters.new(search: { user_status_id: UserStatus.default_active_status.id }) }

      it 'filters results' do
        expect(search).to include user_active
        expect(search).not_to include user_pending
      end
    end

    context 'when a filter has a default value' do
      let(:query) { Division }
      let(:filters) { [{ column: :owner_id, options: User.by_name, default_value: user.id }] }
      let(:user) { create :admin }
      let!(:other_division) { create(:division) }
      let!(:default_division) { create(:division, owner: user) }

      context 'when in a blank query' do
        let(:params) { ActionController::Parameters.new }

        it 'filters results using default value' do
          expect(search).to include default_division
          expect(search).not_to include other_division
        end
      end

      context 'when in a date filter' do
        let(:params) { ActionController::Parameters.new }

        it 'filters results using default value'
      end

      context 'when in a query where value is selected' do
        let(:params) { ActionController::Parameters.new(search: { owner_id: other_division.owner_id }) }

        it 'filters results using selected value' do
          expect(search).to include other_division
          expect(search).not_to include default_division
        end
      end

      context 'with a boolean filter' do
        it 'filters results using selected value'
      end
    end

    describe 'authorized' do
      let(:query) { Division }
      let(:filters) { [{ input_label: 'Owner', column: :owner_id, options: User.by_name }] }
      let(:params) { ActionController::Parameters.new }

      context 'when authorized' do
        let(:user) { create :admin }

        it { is_expected.to eq [division] }
      end

      context 'when not authorized' do
        let(:user) { create :user }

        it { is_expected.not_to eq [division] }
      end
    end
  end

  describe 'user filter_defaults' do
    subject(:search) do
      described_class.new(query: query,
                          filters: filters,
                          current_user: user,
                          search_name: 'divisions_search',
                          sticky_filters: sticky_filters,
                          params: params).results
    end

    let(:sticky_filters) { true }
    let(:query) { User }
    let!(:user_active) { create :user, user_status: UserStatus.default_active_status }
    let!(:user_pending) { create :user, user_status: UserStatus.default_pending_status }
    let(:filters) { [{ column: :user_status_id, options: UserStatus.by_id }] }
    let(:params) { ActionController::Parameters.new }

    before do
      default_values = { 'divisions_search': { user_status_id: UserStatus.default_active_status.id } }
      user.update!(filter_defaults: default_values)
    end

    context 'when no params are passed' do
      context 'with sticky filters' do
        it 'filters from stored user default values' do
          expect(search).to include user_active
          expect(search).not_to include user_pending
        end
      end

      context 'without sticky filters' do
        let(:sticky_filters) { false }

        it 'filters from stored user default values' do
          expect(search).to include user_active
          expect(search).to include user_pending
        end
      end
    end

    context 'when clear_filters params are passed in' do
      let(:params) { ActionController::Parameters.new(clear_filters: true) }

      it 'resets stored user default values' do
        expect { search }.to change { user.filter_defaults['divisions_search']['user_status_id'] }
          .from(UserStatus.default_active_status.id).to(nil)
        expect(search).to include user_active
        expect(search).to include user_pending
      end
    end
  end

  describe 'custom date filter' do
    subject(:search) do
      described_class.new(query: query,
                          filters: filters,
                          search_name: 'divisions_search',
                          current_user: user,
                          params: params)
    end

    let(:query) { User.joins(:security_roles) }
    let(:filters) { [{ column: :custom_column, type: RadCommon::DateFilter, custom: true }] }

    let(:params) do
      ActionController::Parameters.new(search: { custom_column_start: 3.days.from_now.beginning_of_day,
                                                 custom_column_end: 3.days.from_now.end_of_day })
    end

    before do
      create :user, confirmed_at: 1.day.ago
      create :user, confirmed_at: 3.days.from_now
    end

    it 'is included in search params' do
      expect(search.search_params.keys).to include 'custom_column_start'
      expect(search.search_params.keys).to include 'custom_column_end'
    end

    it 'runs query using custom value' do
      expect(search.results.where('confirmed_at >= ? AND confirmed_at <= ?',
                                  search.search_params['custom_column_start'],
                                  search.search_params['custom_column_end']).count).to eq 1
    end
  end

  describe 'valid?' do
    subject(:valid) { search.valid? }

    let(:search) do
      described_class.new(query: query,
                          filters: filters,
                          search_name: 'divisions_search',
                          current_user: user,
                          params: params)
    end
    let(:query) { User.joins(:security_roles) }
    let(:filters) { [{ column: :confirmed_at, type: RadCommon::DateFilter }] }

    context 'with invalid date params' do
      let(:params) do
        ActionController::Parameters.new(search: { confirmed_at_start: '2019-13-01',
                                                   confirmed_at_end: '2019-12-02' })
      end

      it 'returns false and displays error message' do
        expect(valid).to eq false
        expect(search.error_messages).to eq 'Invalid date entered for confirmed_at'
      end
    end

    context 'when start date after end date' do
      let(:params) do
        ActionController::Parameters.new(search: { confirmed_at_start: '2019-12-03',
                                                   confirmed_at_end: '2019-12-02' })
      end

      it 'returns false and displays error message' do
        expect(valid).to eq false
        expect(search.error_messages).to eq 'Start at date must before end date'
      end
    end
  end

  describe 'scope value filters' do
    subject(:search) do
      described_class.new(query: query,
                          filters: filters,
                          search_name: 'divisions_search',
                          current_user: user,
                          params: params).filters
    end

    context 'when using mixed scope_values' do
      let(:query) { Division }
      let(:filters) { [{ column: :owner_id, options: User.by_name, scope_values: { 'Pending Values': :pending } }] }
      let(:params) { ActionController::Parameters.new }

      it 'has both scope and normal options' do
        expect(search.first.input_options).to include ['Pending Values', 'Pending Values']
        expect(search.first.input_options).to include [User.by_name.first.to_s, User.by_name.first.id]
      end
    end

    context 'when using only scope_values' do
      let(:query) { Division }
      let(:filters) { [{ input_label: 'Type', name: :external, scope_values: %i[internal external] }] }
      let(:params) { ActionController::Parameters.new }

      it 'has both scope  optins' do
        expect(search.first.input_options.map(&:first)).to eq %w[Internal External]
      end
    end

    context 'when using scope_value in grouped options' do
      let(:query) { Division }
      let(:filters) do
        [{ column: :owner_id, input_label: 'Users', grouped: true,
           options: [['...', [user, { scope_value: :unassigned }]],
                     ['Active', User.active.by_name],
                     ['Inactive', User.inactive.by_name]] }]
      end
      let(:params) { ActionController::Parameters.new }
      let(:group_values) { search.first.input_options.map(&:last) }

      it 'has both scope and normal options' do
        expect(group_values).to include [[user.to_s, user.id], %w[Unassigned unassigned]]
      end
    end
  end

  describe 'search_params' do
    context 'when using default params' do
      it 'uses default params when params are not present'
      it 'overrides defaults params when params are present'
    end
  end
end
