RadCommon.setup do |config|
  # Enables/Disables user avatars being uploaded and displayed in the application
  config.use_avatar = true

  # Does not allow users to manually sign up
  # config.disable_sign_up = false

  # Allows users to be marked as external/client users, adjusts user filtering and seeds to account for this
  config.external_users = true

  # When two-factor authentication is enabled, allow users to opt in or out voluntarily
  # config.authy_user_opt_in = true

  # Only includes company name in email header if app logo does not include name
  # config.app_logo_includes_name = true

  # Set to namespace for portal users. This is needed to control authentication.
  # config.portal_namespace = nil

  # Determines which models should be included in the system_usages route
  config.system_usage_models = [['Division', 'status_pending', 'Pending Divisions'],
                                ['Division', 'status_active', 'Active Divisions'],
                                ['Division', 'status_inactive', 'Inactive Divisions'],
                                'User']

  # Determines which attributes should be hidden in the audits for non-admin users
  config.restricted_audit_attributes = [{ model: 'Division', attribute: 'hourly_rate' }]

  # allows for additional parameters to be passed into the users controller thus
  # avoiding the need to override the controller in many cases)
  # config.additional_user_params = []

  # Determines how ofter the global validity check will run
  # config.global_validity_days = 3

  # A notification email with a report of how long each item took will be sent if it runs beyond this timeout
  # There is a hard time out of 24 hours which will raise an exception and terminate the rake task
  # config.global_validity_timeout = 3.hours

  # Determines models to be excluded in the global validity check
  # config.global_validity_exclude = []

  # Allows for queries to be passed in, providing the ability to exclude records of specific class
  # This is typically used in combination with global_validity_exclude
  # config.global_validity_include = []

  # Allows for specific messages to be excluded from the global validity emailed result
  # config.global_validity_supress = []

  # Sets search scopes to be included in the navigation search bar
  config.global_search_scopes =
    [
      { name: 'user_name',
        model: 'User',
        description: 'Search user by name',
        columns: ['email'],
        methods: [:user_status],
        query_where: "last_name || ', ' || first_name ilike :search",
        query_order: 'last_name ASC, first_name ASC, created_at DESC' },

      { name: 'user_email',
        model: 'User',
        description: 'Search user by email',
        columns: ['email'],
        query_where: 'email ilike :search' },

      { name: 'user_name_with_no_where',
        model: 'User',
        description: 'Search user by name',
        columns: [],
        query_order: 'last_name ASC, first_name ASC, created_at DESC' },

      { name: 'division_name',
        model: 'Division',
        description: 'Search division by name',
        columns: ['name'],
        query_where: 'name ilike :search',
        query_order: 'name' },
      { name: 'user_by_division_name',
        model: 'User',
        description: 'Search user by division name',
        columns: [],
        joins: 'JOIN divisions on divisions.owner_id = users.id',
        query_where: 'divisions.name ilike :search',
        super_search_exclude: true }
    ]
end
