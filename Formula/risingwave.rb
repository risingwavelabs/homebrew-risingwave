class Risingwave < Formula
  RW_VERSION = "0.19.0".freeze
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v#{RW_VERSION}.tar.gz"
  sha256 "b6a35dd32b773ab2405372286329b31b43cc86d7e7dd901f27c7b14de5a5a42d"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave-0.19.0"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "53dbae8abffe81daf69f5a831cf13a1d05590434f790e1c168484cf65bd7d4e3"
    sha256                               monterey:      "0310e2786879d77e3b3e7e36eacc09158fffcd95d7b3f8d8eaa12fae5981ed5b"
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
