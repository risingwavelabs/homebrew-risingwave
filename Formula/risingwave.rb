class Risingwave < Formula
  RW_VERSION = "0.19.0-alpha.1".freeze
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v#{RW_VERSION}.tar.gz"
  sha256 "de3b3c4db3c9f8fc632abd93b5ef156061da4beb9dcc52988e839b2b129dc7cb"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave-0.19.0-alpha.1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ventura: "e0726cd4d83fc48f1f0362c056d859918b4b295a957297a225911777c8cf9e04"
    sha256                               monterey:      "96b020ddcde6363e9a92e59ca207259f3477547621a04522b47305a4f809426e"
  end

  depends_on "cmake" => :build
  depends_on "llvm" => :build
  depends_on "protobuf" => :build
  depends_on "rustup-init" => :build
  depends_on "xz"

  def install
    # this will install the necessary cargo/rustup toolchain bits in HOMEBREW_CACHE
    system "#{Formula["rustup-init"].bin}/rustup-init",
           "-qy", "--no-modify-path",
           "--default-toolchain", "none"
    ENV.prepend_path "PATH", HOMEBREW_CACHE/"cargo_cache/bin"

    system "cargo", "install",
           "--bin", "risingwave",
           "--features", "rw-static-link",
           *std_cargo_args(path: "src/cmd_all")
  end

  test do
    system "#{bin}/risingwave", "--help"
  end
end
