require "cgi"

module ObsidianCompat
  DISPLAY_MATH = /^[ \t]*\$\$(?<body>.*?)(?:\$\$)[ \t]*$/m.freeze

  IMAGE_EMBED = /!\[\[(?<target>[^\]]+)\]\]/.freeze
  WIKI_LINK = /(?<!!)\[\[(?<target>[^\]]+)\]\]/.freeze

  module_function

  def process(content, page)
    return content unless content.is_a?(String)

    site = page.site
    math_blocks = []
    text = protect_display_math(content, math_blocks)
    text = normalize_markdown_images(text)
    text = convert_image_embeds(text, page)
    text = convert_wiki_links(text, site)
    restore_display_math(text, math_blocks)
  end

  def protect_display_math(text, math_blocks)
    text.gsub(DISPLAY_MATH) do
      body = Regexp.last_match[:body].strip
      token = "OBSIDIAN_DISPLAY_MATH_#{math_blocks.length}"
      safe_body = body.gsub(%r{</script}i, '<\/script')
      safe_body = safe_body.gsub(/\\\\(?=\s*(?:\r?\n|&|$))/) { "\\\\\\\\" }
      math_blocks << %({::nomarkdown}\n<script type="math/tex; mode=display">\n#{safe_body}\n</script>\n{:/nomarkdown})
      "\n\n#{token}\n\n"
    end
  end

  def restore_display_math(text, math_blocks)
    math_blocks.each_with_index do |html, index|
      text = text.gsub("OBSIDIAN_DISPLAY_MATH_#{index}", html)
    end
    text
  end

  def normalize_markdown_images(text)
    text.gsub(/(!\[[^\]]*\]\([^)]+\))(?=\S)/, "\\1\n")
  end

  def convert_image_embeds(text, page)
    text.gsub(IMAGE_EMBED) do
      target, label, width = split_embed_target(Regexp.last_match[:target])
      src = resolve_image_src(target, page)
      alt = CGI.escapeHTML(label || File.basename(target, ".*"))
      width_attr = width ? %( width="#{CGI.escapeHTML(width)}") : ""
      %(\n\n<img src="#{CGI.escapeHTML(src)}" alt="#{alt}" class="obsidian-embed-image"#{width_attr}>\n\n)
    end
  end

  def convert_wiki_links(text, site)
    index = document_index(site)
    text.gsub(WIKI_LINK) do
      target, label, = split_embed_target(Regexp.last_match[:target])
      slug = target.split("#", 2).first.strip
      anchor = target.include?("#") ? "##{slugify(target.split("#", 2).last)}" : ""
      title = (label || slug).strip
      url = index[normalize_key(slug)]
      url ? "[#{title}](#{url}#{anchor})" : title
    end
  end

  def split_embed_target(raw)
    parts = raw.split("|").map(&:strip)
    target = parts[0]
    label = parts[1]
    width = nil
    if label&.match?(/\A\d+(?:x\d+)?\z/)
      width = label.split("x", 2).first
      label = parts[2]
    end
    [target, label, width]
  end

  def resolve_image_src(target, page)
    clean = target.strip
    return clean if clean.match?(/\A(?:https?:)?\/\//) || clean.start_with?("/")

    base = image_base_from_page(page)
    if base
      candidate = "#{base}/#{clean}"
      return encode_url_path(candidate) if file_exists_for_url?(candidate, page.site)
    end

    found = find_asset_by_basename(clean, page.site)
    return encode_url_path(found) if found

    encode_url_path(base ? "#{base}/#{clean}" : clean)
  end

  def image_base_from_page(page)
    img = page.data["img"].to_s.strip
    return nil if img.empty?

    "/assets/img/#{File.dirname(img).tr("\\", "/")}"
  end

  def file_exists_for_url?(url, site)
    path = File.join(site.source, url.sub(%r{\A/}, "").split("/"))
    File.file?(path)
  end

  def find_asset_by_basename(target, site)
    name = File.basename(target).downcase
    root = File.join(site.source, "assets", "img")
    return nil unless Dir.exist?(root)

    Dir.glob(File.join(root, "**", "*")).find do |path|
      File.file?(path) && File.basename(path).downcase == name
    end&.then do |path|
      "/" + path.sub(site.source, "").tr("\\", "/").sub(%r{\A/+}, "")
    end
  end

  def document_index(site)
    docs = site.posts.docs + site.collections.values.flat_map(&:docs) + site.pages
    docs.each_with_object({}) do |doc, index|
      url = doc.respond_to?(:url) ? doc.url : doc.url
      next if url.to_s.empty?

      [doc.data["title"], document_basename(doc)].compact.each do |key|
        index[normalize_key(key)] ||= url
      end
    end
  end

  def document_basename(doc)
    return doc.basename_without_ext if doc.respond_to?(:basename_without_ext)
    return File.basename(doc.path, File.extname(doc.path)) if doc.respond_to?(:path) && doc.path

    nil
  end

  def normalize_key(value)
    value.to_s.strip.downcase
  end

  def slugify(value)
    value.to_s.strip.downcase.gsub(/[^\p{Alnum}\p{Han}\s-]/, "").gsub(/\s+/, "-")
  end

  def encode_url_path(path)
    path.split("/").map { |part| CGI.escape(part).gsub("+", "%20") }.join("/")
  end
end

Jekyll::Hooks.register [:documents, :pages], :pre_render do |page|
  page.content = ObsidianCompat.process(page.content, page)
end
