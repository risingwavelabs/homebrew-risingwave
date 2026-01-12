class Risingwave < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v2.7.1.tar.gz"
  sha256 "c775587e3a95a5ae823e3271a45bd9de2893cc75cdeb3162ec0aa117e7099c35"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave-2.5.1_1"
    sha256 cellar: :any, arm64_ventura: "9b7d99be5d431d8a3947820a4a35060d165eb52ec8a61836364c96c4d4b0c8a7"
  end

  option "with-dev-profile", "Build with dev profile"

  depends_on "cmake" => :build
  depends_on "node@20" => :build
  depends_on "protobuf" => :build
  depends_on "rustup" => :build
  depends_on "java11"
  depends_on "openssl@3"
  depends_on "python@3.12"

  resource "connector" do
    url "https://github.com/risingwavelabs/risingwave/releases/download/v2.5.1/risingwave-connector-v2.5.1.tar.gz"
    sha256 "af582af8bc790f2b66d7d8feef84cb056e0e46d8c16b71440a60d23d9e3edd63"
  end

  # Mitigate "argument list too long" error when linking.
  patch :DATA

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
      s.gsub!(/"-Clink-arg=.*lld",?/, "")
    end

    # Enable building embedded dashboard.
    ENV["ENABLE_BUILD_DASHBOARD"] = "1" if build.without?("dev-profile")

    # Increase memory limit for Node.js for building dashboard.
    ENV["NODE_OPTIONS"] = "--max-old-space-size=8192"

    # Currently we don't support Python 3.13.
    ENV["PYO3_PYTHON"] = "python3.12"

    # Workaround for CMake 4 installed by Homebrew.
    ENV["CMAKE_POLICY_VERSION_MINIMUM"] = "3.5"

    # Will show "x.y.z (Homebrew)" in the version string.
    ENV["GIT_SHA"] = "Homebrew"
    ENV["GIT_SHA"] += ", dev" if build.with?("dev-profile")

    # Use `dev` profile if `--with-dev-profile` is passed.
    profile = build.with?("dev-profile") ? "dev" : "production"

    system "cargo", "install",
           "--profile", profile,
           "--bin", "risingwave",
           "--features", "rw-static-link",
           "--features", "udf",
           *std_cargo_args(root: libexec, path: "src/cmd_all")

    resource("connector").stage do
      # XXX: why `libs/*` doesn't work?
      (libexec/"libexec").install Dir["**/*.jar"]
    end

    (bin/"risingwave").write_env_script (libexec/"bin"/"risingwave"),
      CONNECTOR_LIBS_PATH: libexec/"libexec"
  end

  test do
    system "#{bin}/risingwave", "--help"
  end
end

__END__
diff --git a/Cargo.toml b/Cargo.toml
index 9319e18..b51a281 100644
--- a/Cargo.toml
+++ b/Cargo.toml
@@ -312,6 +312,7 @@ lto = "off"
 
 [profile.production]
 inherits = "release"
+codegen-units = 8 # mitigate "argument list too long" error when linking
 incremental = false
 lto = "thin"
 
