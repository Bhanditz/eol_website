module I18nHelper
  # separated_list([a, b, c]) == "(a, b, c)" for en
  def separated_list(sources)
    items = sources.map { |s| s.is_a?(Hash) && s[:name] ? s[:name] : s }
    # Override in locale file, e.g., config/locales/custom_support/en.yml
    default_strs = {
      :join => ', ',
      :open => '(',
      :close => ')'
    }

    i18n_strs = I18n.translate(:'custom_support.separated_list', :default => {})
    puts i18n_strs
    default_strs.merge!(i18n_strs)

    "#{default_strs[:open]}#{items.join(default_strs[:join])}#{default_strs[:close]}"
  end
end
