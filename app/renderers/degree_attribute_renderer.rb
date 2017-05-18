class DegreeAttributeRenderer < Hyrax::Renderers::AttributeRenderer
  def attribute_value_to_html(value)
    %(<span itemprop="degree">#{::DegreesService.label(value)}</span>)
  end
end
