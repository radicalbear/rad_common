module RadCommon
  class LikeFilter
    attr_reader :column
    def initialize(column:, type:)
      @column = column
    end

    def filter_view
      'like'
    end

    def searchable_name
      like_input
    end

    def like_value(params)
      params[like_input]
    end

    def like_input
      "#{column}_like"
    end

    # todo maybe remove these below
    def joins
      []
    end

    def multiple
      false
    end

    def apply_filter(results, params)
      value = like_value(params)

      results = results.where("lower(#{column}) like ?", "%#{value.downcase}%") if value.present?
      results
    end
  end
end