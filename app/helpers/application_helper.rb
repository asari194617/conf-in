require 'base64'
require 'rqrcode'
require 'uri'

module ApplicationHelper
  SIZE = {
    mini: { size: '24x24', def_url: '/images/24.png' },
    normal: { size: '48x48', def_url: '/images/48.png' },
    bigger: { size: '73x73', def_url: '/images/73.png' }
  }.freeze

  def title
    @page_title ? "#{@page_title} | カンファイン" : 'カンファイン'
  end

  def qrimg_tag(value, **options)
    src = "data:image/png;base64,#{Base64.strict_encode64(qr_png_binary(value))}"
    image_tag src, **{ width: 150, alt: '受付用QRコード' }.merge(options)
  end

  def qr_png_binary(value)
    RQRCode::QRCode.new(value).as_png(size: 320, color_mode: ChunkyPNG::COLOR_GRAYSCALE).to_s
  end

  def twicon_tag(user, size = :normal)
    icon = SIZE.fetch(size)
    path = user.twicon_url.present? ? icon_user_path(user, size: size) : icon[:def_url]
    image_tag path, alt: user.name, size: icon[:size]
  end

  def twicon_url_with_size(url, size)
    uri = URI.parse(url)
    return unless %w[https http].include?(uri.scheme) && uri.host.present? && uri.path.present?

    extension = File.extname(uri.path)
    uri.path = "#{uri.path.delete_suffix(extension)}_#{size}#{extension}"
    uri.to_s
  rescue URI::Error
    nil
  end

  def link_to_remove_fields(name, form, html_options = {})
    form.hidden_field(:_destroy) +
      button_tag(name, type: 'button', data: { remove_fee: true }, **html_options)
  end

  def link_to_add_fields(name, form, association, html_options = {})
    new_object = form.object.class.reflect_on_association(association).klass.new
    fields = form.fields_for(association, new_object, child_index: "new_#{association}") do |builder|
      render "#{association.to_s.singularize}_fields", f: builder
    end
    tag.template(fields, id: 'event-fee-template') +
      button_tag(name, type: 'button', data: { add_fee: true }, **html_options)
  end

  def form_errors(record)
    return if record.errors.empty?

    content_tag(:ul, class: 'alert-message danger', role: 'alert') do
      safe_join(record.errors.full_messages.map { |message| tag.li(message) })
    end
  end

  def hbr(value)
    safe_join(value.to_s.split(/\r\n|\r|\n/, -1), tag.br)
  end

  def google_maps_url(address)
    "https://www.google.com/maps/search/?#{URI.encode_www_form(api: 1, query: address)}"
  end

  def website_link(value, **options)
    return if value.blank?

    uri = URI.parse(value)
    return value unless %w[http https].include?(uri.scheme) && uri.host.present?

    link_to value, value, **options
  rescue URI::InvalidURIError
    value
  end
end
