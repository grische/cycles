###########################################################################
# Helper macros
macro(_set_default variable value)
	if(NOT ${variable})
		set(${variable} ${value})
	endif()
endmacro()

###########################################################################
# Hardcoded libraries for platforms where we've got precompiled libraries.

###########################################################################
# Path to the folder with precompiled libarries.
# We demand libraries folders to be called exactly the same for all platforms.
if(APPLE)
	set(_lib_DIR "${CMAKE_SOURCE_DIR}/../lib/darwin")
elseif(WIN32)
	if(CMAKE_CL_64)
		set(_lib_DIR "${CMAKE_SOURCE_DIR}/../lib/win64_vc15")
	else()
		message(FATAL_ERROR "Unsupported Visual Studio Version")
	endif()
else()
	# Path to a locally compiled libraries.
	set(LIBDIR_NAME ${CMAKE_SYSTEM_NAME}_${CMAKE_SYSTEM_PROCESSOR})
	string(TOLOWER ${LIBDIR_NAME} LIBDIR_NAME)
	set(LIBDIR_NATIVE_ABI ${CMAKE_SOURCE_DIR}/../lib/${LIBDIR_NAME})

	# Path to precompiled libraries with known CentOS 7 ABI.
	set(LIBDIR_CENTOS7_ABI ${CMAKE_SOURCE_DIR}/../lib/linux_centos7_x86_64)

	# Choose the best suitable libraries.
	if(EXISTS ${LIBDIR_NATIVE_ABI})
		set(_lib_DIR ${LIBDIR_NATIVE_ABI})
	elseif(EXISTS ${LIBDIR_CENTOS7_ABI})
		set(_lib_DIR ${LIBDIR_CENTOS7_ABI})
		set(WITH_CXX11_ABI OFF)

		if(CMAKE_COMPILER_IS_GNUCC AND
			 CMAKE_C_COMPILER_VERSION VERSION_LESS 9.3)
			message(FATAL_ERROR "GCC version must be at least 9.3 for precompiled libraries, found ${CMAKE_C_COMPILER_VERSION}")
		endif()
	endif()

	# Avoid namespace pollustion.
	unset(LIBDIR_NATIVE_ABI)
	unset(LIBDIR_CENTOS7_ABI)
endif()

###########################################################################
# Tips for where to find some packages.
# Don't overwrite if passed via command line arguments.

_set_default(OPENIMAGEIO_ROOT_DIR "${_lib_DIR}/openimageio")
_set_default(BOOST_ROOT "${_lib_DIR}/boost")
_set_default(LLVM_ROOT_DIR "${_lib_DIR}/llvm")
_set_default(OSL_ROOT_DIR "${_lib_DIR}/osl")
_set_default(OPENEXR_ROOT_DIR "${_lib_DIR}/openexr")
_set_default(TBB_ROOT_DIR "${_lib_DIR}/tbb")
_set_default(ZLIB_ROOT "${_lib_DIR}/zlib")
_set_default(EMBREE_ROOT_DIR "${_lib_DIR}/embree")

# Dependencies for OpenImageIO.
set(JPEG_LIBRARIES "${_lib_DIR}/jpeg/lib/libjpeg${CMAKE_STATIC_LIBRARY_SUFFIX}")
if(NOT UNIX)
    set(PNG_LIBRARIES "${_lib_DIR}/png/lib/libpng${CMAKE_STATIC_LIBRARY_SUFFIX}")
else()
    set(PNG_LIBRARIES "${_lib_DIR}/png/lib/libpng16${CMAKE_STATIC_LIBRARY_SUFFIX}")
endif()

if (MSVC)
	set(JPEG_LIBRARIES ${JPEG_LIBRARIES};${_lib_DIR}/openjpeg/lib/openjp2${CMAKE_STATIC_LIBRARY_SUFFIX})
else()
	set(JPEG_LIBRARIES ${JPEG_LIBRARIES};${_lib_DIR}/openjpeg/lib/libopenjp2${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

# TODO(sergey): Move naming to a consistent state.
set(TIFF_LIBRARY "${_lib_DIR}/tiff/lib/libtiff${CMAKE_STATIC_LIBRARY_SUFFIX}")

if(APPLE OR UNIX)
	# Precompiled PNG library depends on ZLib.
	find_package(ZLIB REQUIRED)
	list(APPEND PLATFORM_LINKLIBS ${ZLIB_LIBRARIES})

	# Glew
	_set_default(GLEW_ROOT_DIR "${_lib_DIR}/glew")
elseif(MSVC)
	set(ZLIB_INCLUDE_DIRS ${_lib_DIR}/zlib/include)
	set(ZLIB_LIBRARIES ${_lib_DIR}/zlib/lib/libz_st.lib)
	set(ZLIB_INCLUDE_DIR ${_lib_DIR}/zlib/include)
	set(ZLIB_LIBRARY ${_lib_DIR}/zlib/lib/libz_st.lib)
	set(ZLIB_DIR ${_lib_DIR}/zlib)
	find_package(ZLIB REQUIRED)
	list(APPEND PLATFORM_LINKLIBS ${ZLIB_LIBRARIES})

	# TODO(sergey): On Windows llvm-config doesn't give proper results for the
	# library names, use hardcoded libraries for now.
	file(GLOB LLVM_LIBRARIES_RELEASE ${LLVM_ROOT_DIR}/lib/*.lib)
	file(GLOB LLVM_LIBRARIES_DEBUG ${LLVM_ROOT_DIR}/debug/lib/*.lib)
	set(LLVM_LIBRARIES)
	foreach(_llvm_library ${LLVM_LIBRARIES_RELEASE})
		set(LLVM_LIBRARIES ${LLVM_LIBRARIES} optimized ${_llvm_library})
	endforeach()
	foreach(_llvm_library ${LLVM_LIBRARIES_DEBUG})
		set(LLVM_LIBRARIES ${LLVM_LIBRARIES} debug ${_llvm_library})
	endforeach()

	# On Windows we use precompiled GLEW and GLUT.
	_set_default(GLEW_ROOT_DIR "${_lib_DIR}/opengl")
	_set_default(CYCLES_GLUT "${_lib_DIR}/opengl")
	set(GLUT_LIBRARIES "${_lib_DIR}/opengl/lib/freeglut_static.lib")

	set(Boost_USE_STATIC_RUNTIME OFF)
	set(Boost_USE_MULTITHREADED ON)
	set(Boost_USE_STATIC_LIBS ON)

	# Special tricks for precompiled PThreads.
	set(PTHREADS_LIBRARIES "${_lib_DIR}/pthreads/lib/pthreadVC3.lib")
	include_directories("${_lib_DIR}/pthreads/include")

	# We need to tell compiler we're gonna to use static versions
	# of OpenImageIO and GL*, otherwise linker will try to use
	# dynamic one which we don't have and don't want even.
	add_definitions(
		# OIIO changed the name of this define in newer versions
		# we define both, so it would work with both old and new
		# versions.
		-DOIIO_STATIC_BUILD
		-DOIIO_STATIC_DEFINE
		-DGLEW_STATIC
		-DFREEGLUT_STATIC
		-DFREEGLUT_LIB_PRAGMAS=0
	)

	# Special exceptions for libraries which needs explicit debug version
	set(OPENIMAGEIO_LIBRARY
		optimized ${OPENIMAGEIO_ROOT_DIR}/lib/OpenImageIO.lib
		optimized ${OPENIMAGEIO_ROOT_DIR}/lib/OpenImageIO_Util.lib
		debug ${OPENIMAGEIO_ROOT_DIR}/lib/OpenImageIO_d.lib
		debug ${OPENIMAGEIO_ROOT_DIR}/lib/OpenImageIO_Util_d.lib
	)

	set(OSL_OSLCOMP_LIBRARY
		optimized ${OSL_ROOT_DIR}/lib/oslcomp.lib
		debug ${OSL_ROOT_DIR}/lib/oslcomp_d.lib
	)
	set(OSL_OSLEXEC_LIBRARY
		optimized ${OSL_ROOT_DIR}/lib/oslexec.lib
		debug ${OSL_ROOT_DIR}/lib/oslexec_d.lib
	)
	set(OSL_OSLQUERY_LIBRARY
		optimized ${OSL_ROOT_DIR}/lib/oslquery.lib
		debug ${OSL_ROOT_DIR}/lib/oslquery_d.lib
	)

	set(OPENEXR_IEX_LIBRARY
		optimized ${OPENEXR_ROOT_DIR}/lib/Iex_s.lib
		debug ${OPENEXR_ROOT_DIR}/lib/Iex_s_d.lib
	)
	set(OPENEXR_HALF_LIBRARY
		optimized ${OPENEXR_ROOT_DIR}/lib/Half_s.lib
		debug ${OPENEXR_ROOT_DIR}/lib/Half_s_d.lib
	)
	set(OPENEXR_ILMIMF_LIBRARY
		optimized ${OPENEXR_ROOT_DIR}/lib/IlmImf_s.lib
		debug ${OPENEXR_ROOT_DIR}/lib/IlmImf_s_d.lib
	)
	set(OPENEXR_IMATH_LIBRARY
		optimized ${OPENEXR_ROOT_DIR}/lib/Imath_s.lib
		debug ${OPENEXR_ROOT_DIR}/lib/Imath_s_d.lib
	)
	set(OPENEXR_ILMTHREAD_LIBRARY
		optimized ${OPENEXR_ROOT_DIR}/lib/IlmThread_s.lib
		debug ${OPENEXR_ROOT_DIR}/lib/IlmThread_s_d.lib
	)

	set(TBB_LIBRARY
		optimized ${TBB_ROOT_DIR}/lib/tbb.lib
		debug ${TBB_ROOT_DIR}/lib/debug/tbb_debug.lib
	)

	set(EMBREE_TASKING_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/tasking.lib
		debug  ${EMBREE_ROOT_DIR}/lib/tasking_d.lib
	)
	set(EMBREE_EMBREE3_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/embree3.lib
		debug  ${EMBREE_ROOT_DIR}/lib/embree3_d.lib
	)
	set(EMBREE_EMBREE_AVX_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/embree_avx.lib
		debug  ${EMBREE_ROOT_DIR}/lib/embree_avx_d.lib
	)
	set(EMBREE_EMBREE_AVX2_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/embree_avx2.lib
		debug  ${EMBREE_ROOT_DIR}/lib/embree_avx2_d.lib
	)
	set(EMBREE_EMBREE_SSE42_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/embree_sse42.lib
		debug  ${EMBREE_ROOT_DIR}/lib/embree_sse42_d.lib
	)
	set(EMBREE_LEXERS_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/lexers.lib
		debug  ${EMBREE_ROOT_DIR}/lib/lexers_d.lib
	)
	set(EMBREE_MATH_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/math.lib
		debug  ${EMBREE_ROOT_DIR}/lib/math_d.lib
	)
	set(EMBREE_SIMD_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/simd.lib
		debug  ${EMBREE_ROOT_DIR}/lib/simd_d.lib
	)
	set(EMBREE_SYS_LIBRARY
		optimized ${EMBREE_ROOT_DIR}/lib/sys.lib
		debug  ${EMBREE_ROOT_DIR}/lib/sys_d.lib
	)
elseif(UNIX)
    _set_default(GLEW_ROOT_DIR "${_lib_DIR}/glew")
endif()

unset(_lib_DIR)
