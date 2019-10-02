module ImageFromCdn
  def image_from_cdn(path, alt='Image')
    "![#{alt}](https://res.cloudinary.com/harigopal/image/upload/v1541686088/blog/#{path})"
  end
end

Liquid::Template.register_filter(ImageFromCdn)
