module RadCommon
  class SearchFilter
    attr_reader :options, :column, :joins, :scope_values, :multiple, :scope

    def initialize(column: nil, options:, scope_values: nil, joins: nil, input_label: nil, blank_value_label: nil, scope: nil, multiple: false)
      raise 'Input label is required when options are not active record objects' if input_label.blank? && !options.respond_to?(:table_name)

      @column = column
      @options = options
      @joins = joins
      @input_label = input_label
      @blank_value_label = blank_value_label
      @scope_values = scope_values
      @scope = scope
      @multiple = multiple
      @grouped = false #todo make group select work
    end

    def input_options
      if scope_values?
        scope_options = @scope_values.keys.map { |option| [option, option]}
        scope_options + options.map { |option| [option.to_s, option.id] }
      else
        options
      end
    end

    def scope_values?
      @scope_values.present?
    end

    def label_method
      @scope_values.present? || options.first.is_a?(Array) ? :first : :to_s
    end

    def apply_filter(results, value)
      if scope_search?
        apply_scope_filter(results, value)
      elsif scope_value?(value)
        apply_scope_value(results, value)
      elsif value.present?
        if value.is_a? Array
          values = value.select(&:present?).map(&:to_i)
          results.where("#{searchable_name} IN (?)", values) if values.present?
        else
          results.where("#{searchable_name} = ?", value)
        end
      end
    end

    def scope_search?
      scope.present?
    end

    def scope_value?(scope_name)
      @scope_values.present? && @scope_values.has_key?(scope_name)
    end

    def apply_scope_value(results, scope_name)
      scope = @scope_values[scope_name]
      if scope.is_a? Symbol
        results.send(scope)
      else
        scope_name = scope.keys.first
        scope_args = scope[scope_name]
        results.send(scope_name, scope_args)
      end
    end

    def apply_scope_filter(results, value)
      if scope.is_a? Hash
        scope_proc = scope.values.first
        scope_proc.call(results, value)
      else
        results.send(scope, value)
      end
    end

    def searchable_name
      scope_name || @column
    end

    def scope_name
      return if @scope.blank?

      @scope.is_a?(Hash) ? @scope.keys.first : @scope
    end

    def blank_value_label
      @blank_value_label || "All #{model_name.pluralize}"
    end

    def input_label
      @input_label || model_name
    end

    def model_name
      @input_label || options.table_name.titleize.singularize
    end

    def input_type
      @grouped ? :grouped_select : :select
    end
  end
end