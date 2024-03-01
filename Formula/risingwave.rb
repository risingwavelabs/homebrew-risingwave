class Risingwave < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "139d9b0947618ce711000b0a22bb05a0e3ce90f103e8f2f7e573dee485c2a6ad"
  license "Apache-2.0"
  revision 1
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave-1.7.0"
    sha256 cellar: :any, arm64_ventura: "806608d43ccb5cb84a2b540c87531985041c1a4db2f287b36210d40b5677a2f0"
    sha256 cellar: :any, ventura:       "388299a0f9cf8e2401438024a68976b6a9c435bd9d1f8cb704b51e4f1ae510a1"
    sha256 cellar: :any, monterey:      "60f44731045faa1f7fd28ea5a1eb66116bc238ea176ec413a62716c46b603d9e"
  end

  depends_on "cmake" => :build
  depends_on "protobuf" => :build
  depends_on "rustup-init" => :build
  depends_on "java11"
  depends_on "openssl@3"
  depends_on "xz"

  resource "connector" do
    url "https://github.com/risingwavelabs/risingwave/releases/download/v1.7.0/risingwave-v1.7.0-x86_64-unknown-linux-all-in-one.tar.gz"
    sha256 "aca4affd6fadf33b927d4945d9bfffb73ed4af528aa99b758903600352ac1321"
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
