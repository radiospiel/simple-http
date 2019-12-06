module Simple::HTTP::Helpers
  module BuildURL
    def build_url(base, *args)
      option_args, string_args = args.partition { |arg| arg.is_a?(Hash) }
      options = option_args.inject({}) { |hsh, option| hsh.update option }

      url = File.join([base] + string_args)

      query = build_query(options)
      url += url.index("?") ? "&#{query}" : "?#{query}" if query

      url
    end

    private

    def build_query(params)
      params = params.reject { |_k, v| v.blank? }
      return nil if params.blank?

      params.map { |k, value| "#{k}=#{escape(value.to_s)}" }.join("&")
    end
  end
end
