class UserSearch < RadCommon::Search
  def initialize(params, current_user)
    @current_user = current_user

    super(query: User.joins(:user_status).includes(:user_status, :security_roles),
          filters: filters_def,
          sort_columns: sort_columns_def,
          params: params,
          current_user: current_user)
  end

  private

    def filters_def
      items = [{ input_label: 'Status',
                 column: :user_status_id,
                 options: UserStatus.not_pending.by_id,
                 default_value: UserStatus.default_active_status.id }]

      if RadCommon.external_users && current_user.internal?
        items.push({ input_label: 'Type', name: :external, scope_values: %i[internal external] })
      end

      items
    end

    def sort_columns_def
      items = [{ label: 'Name', column: 'first_name, last_name' },
               { column: 'email' },
               { label: 'Signed In', column: 'current_sign_in_at' },
               { label: 'Created', column: 'users.created_at', direction: 'desc', default: true },
               { label: 'Status', column: 'user_statuses.name' },
               { label: 'Roles' }]

      items.push(label: 'Client?', column: 'external') if RadCommon.external_users

      items
    end
end
