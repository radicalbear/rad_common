module RadCommon
  module Filtering
    include FilterDefaulting
    attr_reader :filters

    def setup_filtering(filters:)
      @filters = build_search_filters(filters)
      @filter_hash = Hash[@filters.collect { |f| [f.searchable_name, f] }]

      setup_filter_defaults
    end

    def search_params
      search_params? ? params.require(:search).permit(permitted_searchable_columns) : {}
    end

    def searchable_columns_strings
      searchable_columns.map(&:to_s)
    end

    def permitted_searchable_columns
      # we need to make sure any params that are an array value ( multiple select ) go to the bottom for permit to work
      columns = @filters.sort_by { |f| f.multiple ? 1 : 0 }
      columns.map { |f|
        if f.multiple
          hash = {}
          hash[f.searchable_name] = []
          hash
        else
          f.searchable_name
        end
        }.flatten
    end

    def searchable_columns
      filters.map(&:searchable_name)
    end

    def selected_value(column)
      search_params[column]
    end

    private

    def apply_filtering
      apply_joins
      apply_filters
    end

    def apply_filters
      @filters.each do |filter|
        results = filter.apply_filter(@results, search_params)
        @results = results || @results
      end
    end

    def apply_joins
      @results = @results.joins(joins)
    end

    def build_search_filters(filters)
      filters.map do |filter|
        if filter.has_key? :type
          filter[:type].send(:new, filter)
        else
          SearchFilter.new(filter)
        end
      end
    end

    def joins
      filters.map(&:joins).compact
    end
  end
end