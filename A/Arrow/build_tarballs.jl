# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arrow"
version = v"0.17.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/apache/arrow/archive/apache-arrow-0.17.0.tar.gz", "4db2233c25d1ef14f90f9de8e9d808a2d386c67e7116405ddd22d8f981fe66c1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/arrow-apache-arrow-0.17.0/cpp

sed -i 's/Ws2_32/ws2_32/g' CMakeLists.txt
sed -i 's/Ws2_32/ws2_32/g' src/arrow/flight/CMakeLists.txt

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-DARROW_CXXFLAGS="-mmacosx-version-min=10.9")
fi

if [[ ${target} == arm-* ]]; then
    FLAGS+=(-DARROW_SIMD_LEVEL=NONE)
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DARROW_JEMALLOC=OFF -DARROW_PARQUET=ON ${FLAGS[@]}

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libparquet", :libparquet),
    LibraryProduct("libarrow", :libarrow)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
