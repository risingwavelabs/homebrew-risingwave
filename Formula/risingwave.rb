class Risingwave < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v1.10.0.tar.gz"
  sha256 "3ecb95e792bd16afa7404b74e3b624b798f4824cbad668fb38d536dabbb8f5e3"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave-1.10.0"
    sha256 cellar: :any, arm64_ventura: "a95b45b787575db3c7d1a1002d110293ebf6560bc679f537c6f338e7cb20f95d"
    sha256 cellar: :any, ventura:       "a79efdd151b969247cd82407c119a28101905a784092eaac81678f2f9b00b586"
  end

  depends_on "cmake" => :build
  depends_on "node@20" => :build
  depends_on "protobuf" => :build
  depends_on "rustup" => :build
  depends_on "java11"
  depends_on "openssl@3"

  resource "connector" do
    url "https://github.com/risingwavelabs/risingwave/releases/download/v1.10.0/risingwave-v1.10.0-x86_64-unknown-linux-all-in-one.tar.gz"
    sha256 "cf4927c62c2234567a2d87256fee217ae853300e12a2f7e9b28a0c873d823129"
  end

  def install
    # this will install the necessary cargo/rustup toolchain bits in HOMEBREW_CACHE
    system "#{Formula["rustup"].bin}/rustup-init",
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

    # Enable building embedded dashboard.
    ENV["ENABLE_BUILD_DASHBOARD"] = "1"

    system "cargo", "install",
           # "--profile", "production", # since the upcoming release 1.11 (or 2.0)
           "--bin", "risingwave",
           "--features", "rw-static-link",
           *std_cargo_args(root: libexec, path: "src/cmd_all")

    resource("connector").stage do
      (libexec/"libexec").install Dir["libs/*"]
    end

    (bin/"risingwave").write_env_script (libexec/"bin"/"risingwave"),
      CONNECTOR_LIBS_PATH: libexec/"libexec"
  end

  test do
    system "#{bin}/risingwave", "--help"
  end
end
