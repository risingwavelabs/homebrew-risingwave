class RisingwaveAT12 < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "8dc4e3997941a31b3ff08ac0be760cbdcb840b8e40dcc99b40c2eafe346e034c"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave@1.2-1.2.0"
    sha256 cellar: :any, arm64_ventura: "cd346ac1dc5ceb6bc546d0fb7a4ae02e6bf4c46e074a8e7fe06fff21110381ef"
    sha256 cellar: :any, ventura:       "2776cfe511e6a636f69ab3863919576ead455f794074b968ba57156b62eaa08a"
  end

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
    # Homebrew changes cxx flags, and CMake doesn't pick them up, so rdkafka-sys build fails.
    # We cannot pass CMake flags (`std_cmake_args`) because it's in their build.rs.
    #
    # Some refs that might be useful:
    # https://github.com/Homebrew/homebrew-core/pull/51949#issuecomment-601943075
    # https://github.com/Homebrew/brew/pull/7134
    ENV["SDKROOT"] = MacOS.sdk_path_if_needed
    system "cargo", "install",
           "--bin", "risingwave",
           "--features", "rw-static-link",
           *std_cargo_args(path: "src/cmd_all") # "--locked", "--root ...", "--path src/cmd_all"
  end

  test do
    system "#{bin}/risingwave", "--help"
  end
end
