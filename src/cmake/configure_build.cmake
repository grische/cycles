###########################################################################
# Global generic CMake settings.

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

###########################################################################
# Per-compiler configuration.

if(CMAKE_COMPILER_IS_GNUCXX)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wno-sign-compare -fno-strict-aliasing")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-sign-compare -fno-strict-aliasing")
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wno-sign-compare -fno-strict-aliasing")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-sign-compare -fno-strict-aliasing")
endif()

if(APPLE)
	if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
		# 10.9 is our min. target, if you use higher sdk, weak linking happens.
		set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9" CACHE STRING "" FORCE)
	endif()

	if(NOT ${CMAKE_GENERATOR} MATCHES "Xcode")
		# force CMAKE_OSX_DEPLOYMENT_TARGET for makefiles, will not work else ( cmake bug ? )
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -std=c++11 -stdlib=libc++")
		add_definitions("-DMACOSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}")
	endif()
elseif(MSVC)
	set(CMAKE_CXX_FLAGS "/nologo /J /Gd /EHsc /MP" CACHE STRING "MSVC MD C++ flags " FORCE)
	set(CMAKE_C_FLAGS   "/nologo /J /Gd /MP"       CACHE STRING "MSVC MD C++ flags " FORCE)

	if(CMAKE_CL_64)
		set(CMAKE_CXX_FLAGS_DEBUG "/Od /RTC1 /MDd /Zi /MP" CACHE STRING "MSVC MD flags " FORCE)
	else()
		set(CMAKE_CXX_FLAGS_DEBUG "/Od /RTC1 /MDd /ZI /MP" CACHE STRING "MSVC MD flags " FORCE)
	endif()
	set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ob2 /MD /MP" CACHE STRING "MSVC MD flags " FORCE)
	set(CMAKE_CXX_FLAGS_MINSIZEREL "/O1 /Ob1 /MD /MP" CACHE STRING "MSVC MD flags " FORCE)
	set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/O2 /Ob1 /MD /Zi /MP" CACHE STRING "MSVC MD flags " FORCE)
	if(CMAKE_CL_64)
		set(CMAKE_C_FLAGS_DEBUG "/Od /RTC1 /MDd /Zi /MP" CACHE STRING "MSVC MD flags " FORCE)
	else()
		set(CMAKE_C_FLAGS_DEBUG "/Od /RTC1 /MDd /ZI /MP" CACHE STRING "MSVC MD flags " FORCE)
	endif()
	set(CMAKE_C_FLAGS_RELEASE "/O2 /Ob2 /MD /MP" CACHE STRING "MSVC MD flags " FORCE)
	set(CMAKE_C_FLAGS_MINSIZEREL "/O1 /Ob1 /MD /MP" CACHE STRING "MSVC MD flags " FORCE)
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "/O2 /Ob1 /MD /Zi /MP" CACHE STRING "MSVC MD flags " FORCE)

	list(APPEND PLATFORM_LINKLIBS psapi)
endif()
