class Risingwave < Formula
  desc "Distributed SQL database for stream processing"
  homepage "https://github.com/risingwavelabs/risingwave"
  url "https://github.com/risingwavelabs/risingwave/archive/refs/tags/v2.4.2.tar.gz"
  sha256 "d689086870b672553cc2da027a656400ecd8ef79b4a34f715edcf226c3e8e8d1"
  license "Apache-2.0"
  head "https://github.com/risingwavelabs/risingwave.git", branch: "main"

  bottle do
    root_url "https://github.com/risingwavelabs/homebrew-risingwave/releases/download/risingwave-2.2.0"
    sha256 cellar: :any, arm64_ventura: "044f7efc2f53108ca6845fa80ff092cfa63abcc7fb1eb32d12d89e34ced702ca"
    sha256 cellar: :any, ventura:       "bd0befef6e73e6325ca43452ede96db5e99d365805ef1604176207b957a13dc3"
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
    url "https://github.com/risingwavelabs/risingwave/releases/download/v2.4.2/risingwave-connector-v2.4.2.tar.gz"
    sha256 "24592c66622ed5a489c59141d34cc902ee7e2647010306142c404706b6c1fe56"
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

    # Currently we don't support Python 3.13.
    ENV["PYO3_PYTHON"] = "python3.12"

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
      (libexec/"libexec").install Dir["libs/*"]
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
 
