class Octave < Formula
  desc "High-level interpreted language for numerical computing"
  homepage "https://www.gnu.org/software/octave/index.html"
  url "https://ftp.gnu.org/gnu/octave/octave-4.2.1.tar.gz"
  mirror "https://ftpmirror.gnu.org/octave/octave-4.2.1.tar.gz"
  sha256 "80c28f6398576b50faca0e602defb9598d6f7308b0903724442c2a35a605333b"
  revision 4

  bottle do
    sha256 "8df6402ed13b6c6339221ab7ddfb7c69cda4c7e2074afca44e6df26e4c22dcb3" => :sierra
    sha256 "c3bd137bc515da259b584436a4ee76b1a0ebcf5056c425b07ff6f66ef6565a7f" => :el_capitan
    sha256 "ce9c87c1271da72a57ddc1acff3a045ed143c6f09eb052f7276f115cd2ea5a51" => :yosemite
    sha256 "36557574edd6f2d9e5a357627b0c8e0da800560fd02142a78979927e5522ad85" => :x86_64_linux
  end

  head do
    url "https://hg.savannah.gnu.org/hgweb/octave", :branch => "default", :using => :hg
    depends_on :hg => :build
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :build
    depends_on "icoutils" => :build
    depends_on "librsvg" => :build
  end

  depends_on "gnu-sed" => :build # https://lists.gnu.org/archive/html/octave-maintainers/2016-09/msg00193.html
  depends_on "pkg-config" => :build
  depends_on :fortran
  depends_on "arpack"
  depends_on "epstool"
  depends_on "fftw"
  depends_on "fltk"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "ghostscript"
  depends_on "gl2ps"
  depends_on "glpk"
  depends_on "gnuplot"
  depends_on "graphicsmagick"
  depends_on "hdf5"
  depends_on "libsndfile"
  depends_on "libtool" => :run
  depends_on "pcre"
  depends_on "portaudio"
  depends_on "pstoedit"
  depends_on "qhull"
  depends_on "qrupdate"
  depends_on "readline"
  depends_on "suite-sparse"
  depends_on "transfig"
  depends_on "openblas" => (OS.mac? ? :optional : :recommended)
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?

  # Dependencies use Fortran, leading to spurious messages about GCC
  cxxstdlib_check :skip

  # If GraphicsMagick was built from source, it is possible that it was
  # done to change quantum depth. If so, our Octave bottles are no good.
  # https://github.com/Homebrew/homebrew-science/issues/2737
  def pour_bottle?
    Tab.for_name("graphicsmagick").without?("quantum-depth-32") &&
      Tab.for_name("graphicsmagick").without?("quantum-depth-8")
  end

  # Work around the C++11 ABI issue.
  fails_with :gcc => "5" if OS.linux?

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j8" if ENV["CIRCLECI"]

    if build.stable?
      # Remove for > 4.2.1
      # Remove inline keyword on file_stat destructor which breaks macOS
      # compilation (bug #50234).
      # Upstream commit from 24 Feb 2017 https://hg.savannah.gnu.org/hgweb/octave/rev/a6e4157694ef
      inreplace "liboctave/system/file-stat.cc",
        "inline file_stat::~file_stat () { }", "file_stat::~file_stat () { }"
    end

    # Default configuration passes all linker flags to mkoctfile, to be
    # inserted into every oct/mex build. This is unnecessary and can cause
    # cause linking problems.
    inreplace "src/mkoctfile.in.cc", /%OCTAVE_CONF_OCT(AVE)?_LINK_(DEPS|OPTS)%/, '""'

    blas_args = []
    if build.with? "openblas"
      blas_args << "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas"
    elsif build.with? "veclibfort"
      blas_args << "--with-blas=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
    else
      blas_args << "--with-blas=-lblas -llapack"
    end

    system "./bootstrap" if build.head?
    system "./configure", "--prefix=#{prefix}",
                          "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--enable-link-all-dependencies",
                          "--enable-shared",
                          "--disable-static",
                          "--disable-docs",
                          "--disable-java",
                          "--without-OSMesa",
                          "--without-qt",
                          "--with-x=no",
                          "--with-portaudio",
                          "--with-sndfile",
                          *blas_args
    system "make", "all"
    system "make", "install"
  end

  test do
    system bin/"octave", "--eval", "(22/7 - pi)/pi"
    # this is supposed to crash octave if there is a problem with veclibfort
    system bin/"octave", "--eval", "single ([1+i 2+i 3+i]) * single ([ 4+i ; 5+i ; 6+i])"
  end
end
