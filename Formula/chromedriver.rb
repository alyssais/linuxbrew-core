class Chromedriver < Formula
  desc "Tool for automated testing of webapps across many browsers"
  homepage "https://sites.google.com/a/chromium.org/chromedriver/"
  if OS.mac?
    url "https://chromedriver.storage.googleapis.com/2.31/chromedriver_mac64.zip"
    sha256 "aab3fc8a4991cb406a907ca5621256cae937d520a164481e2ad3ffd54844db7f"
  elsif OS.linux?
    url "https://chromedriver.storage.googleapis.com/2.31/chromedriver_linux64.zip"
    sha256 "3e372ef676beb3a03aba72089ec0624bb9d3b52597635f907d4c23390fb485a0"
  end
  version "2.31"

  bottle :unneeded

  def install
    bin.install "chromedriver"
  end

  plist_options :manual => "chromedriver"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>homebrew.mxcl.chromedriver</string>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/chromedriver</string>
      </array>
      <key>ServiceDescription</key>
      <string>Chrome Driver</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/chromedriver-error.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/chromedriver-output.log</string>
    </dict>
    </plist>
    EOS
  end

  test do
    driver = fork do
      exec bin/"chromedriver", "--port=9999", "--log-path=#{testpath}/cd.log"
    end
    sleep 5
    Process.kill("TERM", driver)
    File.exist? testpath/"cd.log"
  end
end
