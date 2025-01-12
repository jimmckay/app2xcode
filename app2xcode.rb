class app2xcode < Formula
  desc "Add a signed app to XCode's organizer"
  homepage "https://github.com/jimmckay/app2xcode/"
  url "https://github.com/jimmckay/app2xcode/archive/refs/tags/1.0.0.tar.gz"
  sha256 "22a52001efe7f81c050eeae093e745797d66dc78d10702508e0519ebffcd04a9"

  def install
    bin.install "app2xcode"
  end

  test do
    system "#{bin}/app2xcode", "-v"
  end
end
