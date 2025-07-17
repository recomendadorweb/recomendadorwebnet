module Jekyll
  module CapitalizeEachFilter
    def capitalize_each(input)
      input.to_s        # Aseguramos que sea string
           .gsub('-', ' ')               # Reemplaza guiones por espacios
           .split(' ')                   # Divide en palabras
           .map(&:capitalize)            # Capitaliza cada palabra
           .join(' ')                    # Junta de nuevo con espacios
    end
  end
end

Liquid::Template.register_filter(Jekyll::CapitalizeEachFilter)