if [[ "$RUNTIME_DIR" = "" ]]; then
	echo "Error: RUNTIME_DIR must be set"
	exit 1
fi

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export CC=cc
export CXX=c++
export MACOSX_DEPLOYMENT_TARGET=`cat "$ROOTDIR/shared/definitions/macosx_deployment_target"`
export MACOSX_COMPATIBLE_DEPLOYMENT_TARGETS=`cat "$ROOTDIR/shared/definitions/macosx_compatible_deployment_targets"`
export PKG_CONFIG_PATH="$RUNTIME_DIR/pkgconfig"
export C_INCLUDE_PATH="$RUNTIME_DIR/include"
export CPLUS_INCLUDE_PATH="$RUNTIME_DIR/include"
export LIBRARY_PATH="$RUNTIME_DIR/lib"
export CPPFLAGS="-I$RUNTIME_DIR/include"
export LDPATHFLAGS="-L$RUNTIME_DIR/lib"
export LDFLAGS="$LDPATHFLAGS"

unset DYLD_LIBRARY_PATH
unset DYLD_INSERT_LIBRARIES
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS
unset RUBYOPT
unset RUBYLIB
unset GEM_HOME
unset GEM_PATH
unset SSL_CERT_DIR
unset SSL_CERT_FILE

export CCACHE_COMPRESS=true
export CCACHE_COMPRESSLEVEL=3
export CCACHE_SLOPPINESS=time_macros
export CCACHE_NOHASHDIR=true
unset CCACHE_DIR
unset CCACHE_HASHDIR
