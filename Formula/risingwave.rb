class Risingwave < Formula
  RW_VERSION = "1.0.0".freeze
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v#{RW_VERSION}.tar.gz"
  sha256 "7e1339565ee85268f9b3415da4089d4bd9e33f494f6178189079d399e4d18a77"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "llvm" => :build
  depends_on "protobuf" => :build
  depends_on "rustup-init" => :build
  depends_on "openssl@3"
  depends_on "xz"

  def install
    # this will install the necessary cargo/rustup toolchain bits in HOMEBREW_CACHE
    system "#{Formula["rustup-init"].bin}/rustup-init",
           "-qy", "--no-modify-path",
           "--default-toolchain", "none"
    ENV.prepend_path "PATH", HOMEBREW_CACHE/"cargo_cache/bin"

    ENV.delete "RUSTFLAGS" # https://github.com/Homebrew/brew/pull/15544#issuecomment-1628639703
    system "cargo", "install",
           "--bin", "risingwave",
           "--features", "rw-static-link",
           *std_cargo_args(path: "src/cmd_all") # "--locked", "--root ..", "--path src/cmd_all"
  end

  test do
    system "#{bin}/risingwave", "--help"
  end
end
