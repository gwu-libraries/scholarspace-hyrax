module Hyrax
    module QaSelectServicePatch
        def include_current_value(value, _index, render_options, html_options)
            unless value.blank? || active?(value)
                html_options[:class][-1] += ' force-select'
                render_options += [[label(value) { value }, value]]
            end
            [render_options, html_options]
        end
    end
end
Hyrax::QaSelectService.prepend Hyrax::QaSelectServicePatch