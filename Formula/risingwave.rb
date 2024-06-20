class Risingwave < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://docker.risingwave.com/risingwave/archive/refs/tags/v1.9.1.tar.gz"
  sha256 "a2ad286cde11891906082f54ca5edb997382df639acee83e096b921b0d29a642"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://docker.risingwave.com/homebrew-risingwave/releases/download/risingwave-1.9.1"
    sha256 cellar: :any, arm64_ventura: "baa9110de5d75b63215f814c5b7cf1a5b3e43a73096b5f0448feaee03b402bc6"
    sha256 cellar: :any, ventura:       "96d5d26656e47e848344750adf93eed030c77eb1d1030b0a69a46965fc5ccdb3"
  end

  depends_on "cmake" => :build
  depends_on "node@20" => :build
  depends_on "protobuf" => :build
  depends_on "rustup-init" => :build
  depends_on "java11"
  depends_on "openssl@3"

  resource "connector" do
    url "https://docker.risingwave.com/risingwave/releases/download/v1.9.1/risingwave-v1.9.1-x86_64-unknown-linux-all-in-one.tar.gz"
    sha256 "8f88a4754aebd94196e49f67300180ddf2236d88d93da96cd9e053b2f7487fc8"
  end

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

    # Enable building embedded dashboard.
    ENV["ENABLE_BUILD_DASHBOARD"] = "1"

    system "cargo", "install",
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
