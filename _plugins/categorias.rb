# _plugins/categorias.rb
module Jekyll
  class CategoriaGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Reunir pages + todas las colecciones
      docs = site.pages.dup
      site.collections.each_value { |c| docs.concat(c.docs) }

      categorias = {} # { slug => { "name"=>, "slug"=>, "items"=>[] } }

      docs.each do |doc|
        next if doc.data["excluir_de_categoria"]

        cats = doc.data["categoria"]
        next if cats.nil? || (cats.respond_to?(:empty?) && cats.empty?)

        # Acepta string, lista y strings con comas
        cats = [cats] unless cats.is_a?(Array)
        cats = cats.compact
                   .flat_map { |c| c.to_s.split(/\s*,\s*/) }  # "hogar, cocina" => ["hogar","cocina"]
                   .map! { |c| c.strip }
                   .reject!(&:empty?) || cats

        # Normaliza en el propio doc
        doc.data["categoria"]       = cats
        doc.data["categoria_slugs"] = cats.map { |n| Utils.slugify(n) }

        cats.each do |name|
          slug = Utils.slugify(name)
          categorias[slug] ||= { "name" => name, "slug" => slug, "items" => [] }
          categorias[slug]["items"] << doc
        end
      end

      pattern = site.config["categoria_permalink"] || "/categorias/:slug/"
      layout  = site.config["categoria_layout"]     || "categoria"
      meta    = site.data["categorias_meta"] || {}

      # Exponer índice de categorías a Liquid
      site.data["categorias"] = categorias.values.map { |cat|
        {
          "name"  => cat["name"],
          "slug"  => cat["slug"],
          "count" => cat["items"].size,
          "url"   => pattern.gsub(":slug", cat["slug"])
        }
      }.sort_by { |h| h["name"].downcase }

      # Generar /categorias/:slug/index.html
      categorias.each_value do |cat|
        url  = pattern.gsub(":slug", cat["slug"])
        dir  = url.sub(%r!^/!, "")
        page = Jekyll::PageWithoutAFile.new(site, site.source, dir, "index.html")

        # Meta opcional desde _data/categorias_meta.yml
        m = meta[cat["slug"]] || {}

        page.data["layout"]           = layout
        page.data["title"]            = (m["title"] || cat["name"])
        page.data["intro"]            = m["intro"] if m["intro"]
        page.data["image"]            = m["image"] if m["image"]
        page.data["seo_description"]  = m["seo_description"] if m["seo_description"]

        page.data["categoria_name"]   = cat["name"]
        page.data["categoria_slug"]   = cat["slug"]
        page.data["items"]            = cat["items"]

        site.pages << page
      end

      Jekyll.logger.info "CategoriaGenerator:", "creadas #{categorias.keys.size} categorías"
    end
  end
end
