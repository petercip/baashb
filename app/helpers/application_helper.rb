module ApplicationHelper
  # Darken a hex color by a given percentage (0-100).
  # Returns the original color if it can't be parsed.
  #
  # darken_color("#c8a96e", 10)  →  "#b4986a"
  def darken_color(hex, percent)
    hex = hex.delete_prefix("#")
    return "##{hex}" unless hex.match?(/\A[0-9a-fA-F]{6}\z/)

    r = (hex[0, 2].to_i(16) * (1 - percent / 100.0)).clamp(0, 255).round
    g = (hex[2, 2].to_i(16) * (1 - percent / 100.0)).clamp(0, 255).round
    b = (hex[4, 2].to_i(16) * (1 - percent / 100.0)).clamp(0, 255).round

    "#%02x%02x%02x" % [ r, g, b ]
  end
end
