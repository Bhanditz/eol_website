# NOTE that you use the show_* methods with a - not a = because it's writing
# to the stream directly, NOT building an output for you to show...
module TraitsHelper
  def show_metadata(trait)
    return unless trait[:meta] ||
      trait[:source] ||
      trait[:object_term] ||
      trait[:units]
    id = "hide_#{trait[:id]}".underscore.gsub(/:/, "")
    haml_tag(:a, %Q{<span class="uk-margin-small-right" uk-icon="icon: info"></span>}.html_safe, uk: { toggle: "target: ##{id}; animation: uk-animation-fade", tooltip: true }, title: t(:trait_toggle_details), class: "uk-float-right")
    haml_tag(:div, class: "meta_trait", id: id, hidden: true) do
      haml_tag(:table) do
        if trait[:metadata]
          trait[:metadata].each do |meta_trait|
            show_meta_trait(meta_trait)
          end
        end
        show_definition(trait[:units])
        show_definition(trait[:object_term]) if trait[:object_term]
        show_source(trait[:source]) if trait[:source]
      end
    end
  end

  def show_meta_trait(meta_trait)
    haml_tag :tr do
      haml_tag :th, meta_trait[:predicate][:name]
      haml_tag :td do
        show_trait_value(meta_trait)
      end
    end
  end

  # NOTE: yes, this is a long method. It *might* be worth breaking up, but I'm
  # not sure it would add to the clarity.
  def show_trait_value(trait)
    value = t(:trait_missing, keys: trait.keys.join(", "))
    if trait[:object_page_id] && defined?(@associations)
      target = @associations.find { |a| a.id == trait[:object_page_id] }
      # TODO: We want to use page icon here, not medium. ...but that's
      # slow. We need to re-think this: I believe it needs
      # denormalization.
      if target.medium
        haml_tag :script,
          "<cdata><div><img src=\"#{target.medium.medium_icon_url}\"/>"\
          "</div></cdata>",
          id: "image#{trait[:resource_pk]}.html",
          type: "text/ng-template"
        haml_tag :div, class: "obj_page" do
          haml_concat(link_to(target.name.html_safe, target,
            "popover-trigger" => "mouseenter",
            "popover-placement" => "right",
            "uib-popover-template" => "'image#{trait[:resource_pk]}.html'"))
        end
      else
        haml_concat(link_to(target.name.html_safe, target))
      end
    elsif trait[:measurement]
      if trait[:units] && trait[:units][:name]
        value = trait[:measurement].to_s + " "
        value += trait[:units][:name]
        haml_concat(value)
      else
        haml_concat("OOPS: ")
        haml_concat(trait.inspect)
      end
    elsif trait[:object_term] && trait[:object_term][:name]
      value = trait[:object_term][:name]
      haml_concat value
    elsif trait[:literal]
      haml_concat trait[:literal].html_safe
    else
      haml_concat "OOPS: "
      haml_concat value
    end
  end

  def show_definition(uri)
    return unless uri && uri[:definition]
    haml_tag(:tr) do
      haml_tag(:th, I18n.t(:trait_definition, trait: uri[:name]))
      haml_tag(:td) do
        haml_tag(:span, uri[:uri], class: "uri_defn")
        haml_tag(:br)
        if uri[:definition].empty?
          haml_concat(I18n.t(:trait_unit_definition_blank))
        else
          haml_concat(uri[:definition].html_safe)
        end
      end
    end
  end

  def show_source(src)
    haml_tag(:tr) do
      haml_tag(:th, I18n.t(:trait_source))
      haml_tag(:td, src.gsub(URI.regexp, '<a href="\0">\0</a>').html_safe)
    end
  end

  def show_source_col(trait)
    # TODO: make this a proper link
    haml_tag(:td, class: "table-source") do
      if @resources && resource = @resources[trait[:resource_id]]
        haml_concat(link_to(resource.name, "#", title: resource.name,
          data: { toggle: "tooltip", placement: "left" } ))
      else
        haml_concat(I18n.t(:resource_missing))
      end
    end
  end

  def show_trait_page_icon(page)
    if image = page.top_image
      haml_concat(link_to(image_tag(image.small_icon_url,
        alt: page.scientific_name.html_safe, size: "88x88"), page))
    end
  end

  def show_trait_page_name(page)
    haml_tag(:div, class: "names d-inline") do
      if page.name
        haml_concat(link_to(page.name.titlecase, page, class: "primary-name"))
        haml_tag(:br)
        haml_concat(link_to(page.scientific_name.html_safe, page, class: "secondary-name"))
      else
        haml_concat(link_to(page.scientific_name.html_safe, page, class: "primary-name"))
      end
    end
  end

  def show_trait_modifiers(trait)
    haml_tag(:br)
    [trait[:statistical_method], trait[:sex], trait[:lifestage]].compact.each do |type|
      haml_tag(:span, "(#{type})", class: "trait_type")
    end
  end
end
