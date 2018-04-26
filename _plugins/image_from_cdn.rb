module ImageFromCdn
  def image_from_cdn(path, alt='Image')
    "![#{alt}](https://res.cloudinary.com/turaku/image/upload/#{path})"
  end
end

Liquid::Template.register_filter(ImageFromCdn)
