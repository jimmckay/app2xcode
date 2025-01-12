class app2xcode < Formula
  desc "Add a signed app to XCode's organizer"
  homepage "https://github.com/jimmckay/app2xcode/"
  url "https://github.com/jimmckay/app2xcode/archive/v1.0.0.tar.gz"
  sha256 ""

  def install
    bin.install "app2xcode"
  end

  test do
    system "#{bin}/app2xcode", "-v"
  end
end
