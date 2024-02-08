class RisingwaveAT17SingleNode < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v1.7.0-single-node-2.tar.gz"
  version "1.7.0-single-node"
  sha256 "b2bc8ecf645cece604f88b7fc4e927ea655f3d4dc68938e6021bbd3567e780ff"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave@1.7-single-node-1.7.0-single-node"
    sha256 cellar: :any, arm64_ventura: "23a2b72ed6b1f6ff3b416ecd6b4800cf9a6dbd1ed25de7af68e0fcfbfe8d1e7e"
    sha256 cellar: :any, ventura:       "9f8b2819dbdb9f10fbd4174b0c681127c7a559138da47a81d1dac327b8e5bba6"
    sha256 cellar: :any, monterey:      "999e4308dd43c94e90f538bc2af391af551f4344a58f28f16321fbc37ef3dc1e"
  end

  depends_on "cmake" => :build
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

    # Remove `RUSTFLAGS` env var set by Homebrew, or it will override the one specified
    # in `.cargo/config.toml`.
    #
    # https://github.com/Homebrew/brew/pull/15544#issuecomment-1628639703
    ENV.delete "RUSTFLAGS"

    # Homebrew changes cxx flags, and CMake doesn't pick them up, so rdkafka-sys build fails.
    # We cannot pass CMake flags (`std_cmake_args`) because it's in their build.rs.
    #
    # Some refs that might be useful:
    # https://github.com/Homebrew/homebrew-core/pull/51949#issuecomment-601943075
    # https://github.com/Homebrew/brew/pull/7134
    ENV["SDKROOT"] = MacOS.sdk_path_if_needed

    # Remove `"-Clink-arg=xxx/ld64.lld"` to avoid dependency on LLVM.
    # If we `depends_on "llvm" => :build`, it will somehow corrupt the resolution of the C++
    # compiler when building `cxx` crate. Didn't investigate further.
    inreplace ".cargo/config.toml" do |s|
      s.gsub!(/"-Clink-arg=.*ld64.lld",?/, "")
    end

    system "cargo", "install",
           "--bin", "risingwave",
           "--features", "rw-static-link",
           *std_cargo_args(path: "src/cmd_all") # "--locked", "--root ...", "--path src/cmd_all"
  end

  test do
    system "#{bin}/risingwave", "--help"
  end
end
