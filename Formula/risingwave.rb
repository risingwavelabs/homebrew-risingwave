class Risingwave < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v0.19.0-alpha.tar.gz"
  sha256 "01cfc33813200cb3db1823963a6ab15ebf24b85e1ed0329c963885a4c726226d"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "protobuf" => :build
  depends_on "rustup-init" => :build
  depends_on "xz"
  uses_from_macos "llvm" => :build

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
    system "#{bin}/risingwave", "frontend", "--help"
  end
end
