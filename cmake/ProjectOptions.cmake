include(CMakeDependentOption)
include(CheckCXXCompilerFlag)

macro(myproject_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(myproject_setup_options)
  option(myproject_ENABLE_HARDENING "Enable hardening" ON)
  option(myproject_ENABLE_COVERAGE "Enable coverage reporting" ON)
  option(myproject_DISABLE_EXCEPTIONS "Disable C++ exceptions" ON)
  option(myproject_ENABLE_GPROF "Enable profiling with gprof (adds -pg flags)" ON)
  # for now disable global hardening, as it is not supported by all dependencies
  option(myproject_ENABLE_GLOBAL_HARDENING "Enable global hardening for all dependencies" OFF)
  if(myproject_ENABLE_GLOBAL_HARDENING)
    message(WARNING "Global hardening is enabled, but it is not supported by all dependencies.")
  else()
    message(STATUS "Global hardening is disabled")
  endif()
  
  # namely FUZZTEST
  # cmake_dependent_option(
  #   myproject_ENABLE_GLOBAL_HARDENING
  #   "Attempt to push hardening options to built dependencies"
  #   OFF
  #   myproject_ENABLE_HARDENING
  #   OFF)

  myproject_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR myproject_PACKAGING_MAINTAINER_MODE)
    option(myproject_ENABLE_IPO "Enable IPO/LTO" ON)
    option(myproject_ENABLE_STATIC_ANALYZER "Enable Static Analyzer" OFF)
    option(myproject_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(myproject_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ON)
    option(myproject_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(myproject_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(myproject_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(myproject_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(myproject_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(myproject_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(myproject_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(myproject_ENABLE_PCH "Enable precompiled headers" OFF)
    option(myproject_ENABLE_CACHE "Enable ccache" ON)
    option(myproject_ENABLE_IWYU "Enable IWYU" ON)
  else()
    option(myproject_ENABLE_IPO "Enable IPO/LTO" ON)
    option(myproject_ENABLE_STATIC_ANALYZER "Enable Static Analyzer" OFF)
    option(myproject_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(myproject_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF) # ${SUPPORTS_ASAN}
    option(myproject_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(myproject_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF) # ${SUPPORTS_UBSAN}
    option(myproject_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(myproject_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(myproject_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(myproject_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(myproject_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(myproject_ENABLE_PCH "Enable precompiled headers" OFF)
    option(myproject_ENABLE_CACHE "Enable ccache" ON)
    option(myproject_ENABLE_IWYU "Enable IWYU" ON)

  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      myproject_ENABLE_IPO
      myproject_ENABLE_STATIC_ANALYZER
      myproject_WARNINGS_AS_ERRORS
      myproject_ENABLE_SANITIZER_ADDRESS
      myproject_ENABLE_SANITIZER_LEAK
      myproject_ENABLE_SANITIZER_UNDEFINED
      myproject_ENABLE_SANITIZER_THREAD
      myproject_ENABLE_SANITIZER_MEMORY
      myproject_ENABLE_UNITY_BUILD
      myproject_ENABLE_CLANG_TIDY
      myproject_ENABLE_CPPCHECK
      myproject_ENABLE_COVERAGE
      myproject_ENABLE_PCH
      myproject_ENABLE_CACHE
      myproject_DISABLE_EXCEPTIONS)
  endif()

endmacro()

macro(myproject_global_options)

  # specify the C/C++ standard
  set(CMAKE_CXX_STANDARD 23)
  set(CMAKE_CXX_STANDARD_REQUIRED True)

  set(CMAKE_C_STANDARD 17)
  set(CMAKE_C_STANDARD_REQUIRED True)

  # Enable C++ modules only for Clang (disable for GCC/MSVC)
  if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    message(STATUS "Enabling experimental C++ modules for Clang")
    set(CMAKE_EXPERIMENTAL_CXX_MODULE_COVERAGE ON)
  else()
    message(STATUS "C++ modules support disabled for compiler: ${CMAKE_CXX_COMPILER_ID}")
    set(CMAKE_EXPERIMENTAL_CXX_MODULE_COVERAGE OFF)
  endif()
 
  
  # set build type specific flags
  if(MSVC AND NOT(CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /DEBUG /Od /std:c++23preview")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /GL /std:c++23preview")
    set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RROFILE} /O2 /std:c++23preview")
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html
    # https://gcc.gnu.org/onlinedocs/gcc/Option-Summary.html
    set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0 -std=c++23 -ggdb")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -std=c++23 -DNDEBUG")
    set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_PROFILE} -O3 -std=c++23 -DNDEBUG")
  # https://clang.llvm.org/docs/UsersManual.html
  # this is the clang-cl case
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND MSVC)
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Od /std:c++latest -fcolor-diagnostics -Wno-error=unused-command-line-argument -Wno-error=character-conversion")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /std:c++latest -DNDEBUG -fcolor-diagnostics -Wno-error=unused-command-line-argument -Wno-error=character-conversion")
    set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_PROFILE} /O2 /std:c++latest -DNDEBUG -fcolor-diagnostics -Wno-error=unused-command-line-argument -Wno-error=character-conversion")
    # https://clang.llvm.org/docs/ClangCommandLineReference.html
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g -ggdb -std=c++23 -fcolor-diagnostics") # -std=c++2a
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG -std=c++23 -fcolor-diagnostics")
    set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_PROFILE} -O3 -DNDEBUG -std=c++23 -fcolor-diagnostics") # -std=c++2a
  endif()

  # control where the static and shared libraries are built so that on windows
  # we don't need to tinker with the path to run the executable
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})

  set(CMAKE_LINK_WHAT_YOU_USE TRUE)

  if(myproject_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
	if(NOT(CMAKE_BUILD_TYPE STREQUAL "Debug"))
      myproject_enable_ipo()
	endif()
  endif()

  myproject_supports_sanitizers()

  if(myproject_ENABLE_HARDENING AND myproject_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN
       OR myproject_ENABLE_SANITIZER_UNDEFINED
       OR myproject_ENABLE_SANITIZER_ADDRESS
       OR myproject_ENABLE_SANITIZER_THREAD
       OR myproject_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    message("${myproject_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${myproject_ENABLE_SANITIZER_UNDEFINED}")
    myproject_enable_hardening(myproject_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(myproject_local_options)
  message("In the beginning of the local options functions.")
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(myproject_warnings INTERFACE)
  add_library(myproject_options INTERFACE)

  target_compile_features(myproject_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

  include(cmake/CompilerWarnings.cmake)
  myproject_set_project_warnings(
    myproject_warnings
    ${myproject_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")
  
  # Only when building with -DCMAKE_BUILD_TYPE=Profile,
  # on non-Windows and using GCC or Clang
  if (
    CMAKE_BUILD_TYPE STREQUAL "Profile"
    AND (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    AND NOT WIN32
  )

    find_library(PROFILER_LIB profiler)

    if (PROFILER_LIB)
      message(STATUS "Enabling CPU profiling with gperftools (libprofiler)")
      message(STATUS "Found libprofiler: ${PROFILER_LIB}")
      target_link_libraries(myproject_options INTERFACE -lprofiler)
    else()
      message(WARNING "libprofiler not found, falling back to gprof (-pg)")
      target_compile_options(myproject_options INTERFACE -pg)
      target_link_libraries(myproject_options INTERFACE -pg)
    endif()

  elseif(myproject_ENABLE_GPROF)
    message(MESSAGE "GProf should only be used with GCC on Linux using -DCMAKE_BUILD_TYPE=Profile")
  endif()

  if(myproject_DISABLE_EXCEPTIONS)
    if(MSVC AND NOT(CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
      target_compile_options(myproject_options INTERFACE /EHs-) # Disable exceptions
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND MSVC)
	  message(STATUS "Using clang-cl and disable exceptions with /GX-")
	  target_compile_options(myproject_options INTERFACE /EHs-) # Disable exceptions
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
      target_compile_options(myproject_options INTERFACE -fno-exceptions)
    else()
      message(WARNING "Disabling exceptions is not supported for this compiler.")
    endif()
  else()
    if(MSVC AND NOT(CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
      target_compile_options(myproject_options INTERFACE /EHs) # Enable exceptions
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND MSVC)
      target_compile_options(myproject_options INTERFACE /EHs) # Enable exceptions
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
      target_compile_options(myproject_options INTERFACE -fexceptions)
    else()
      message(WARNING "Enabling exceptions is not supported for this compiler.")
    endif()
  endif()

  if(NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    include(cmake/Sanitizers.cmake)
    myproject_enable_sanitizers(
      myproject_options
      ${myproject_ENABLE_SANITIZER_ADDRESS}
      ${myproject_ENABLE_SANITIZER_LEAK}
      ${myproject_ENABLE_SANITIZER_UNDEFINED}
      ${myproject_ENABLE_SANITIZER_THREAD}
      ${myproject_ENABLE_SANITIZER_MEMORY})
  endif()
  
  set_target_properties(myproject_options PROPERTIES UNITY_BUILD ${myproject_ENABLE_UNITY_BUILD})

  if(myproject_ENABLE_PCH)
    target_precompile_headers(
      myproject_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(myproject_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    myproject_enable_cache()
  endif()

  if(NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    include(cmake/StaticAnalyzers.cmake)
    if(myproject_ENABLE_CLANG_TIDY)
      myproject_enable_clang_tidy(myproject_options ${myproject_WARNINGS_AS_ERRORS})
    endif()

	if(myproject_ENABLE_CPPCHECK)
      myproject_enable_cppcheck(${myproject_WARNINGS_AS_ERRORS} "" # override cppcheck options
      )
    endif()
	
    if(myproject_ENABLE_COVERAGE)
      include(cmake/Tests.cmake)
      myproject_enable_coverage(myproject_options)
    endif()
  endif()

  if(myproject_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(myproject_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(myproject_ENABLE_HARDENING AND NOT myproject_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN
       OR myproject_ENABLE_SANITIZER_UNDEFINED
       OR myproject_ENABLE_SANITIZER_ADDRESS
       OR myproject_ENABLE_SANITIZER_THREAD
       OR myproject_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    myproject_enable_hardening(myproject_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

  if(NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    if(myproject_ENABLE_IWYU)
      if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        find_program(IWYU_PATH NAMES include-what-you-use iwyu)
        if(IWYU_PATH)
          set_target_properties(myproject_options PROPERTIES CXX_INCLUDE_WHAT_YOU_USE "${IWYU_PATH}")
          message(STATUS "Include-What-You-Use found: ${IWYU_PATH}")
        else()
          message(STATUS "Include-What-You-Use not found!")
        endif()
      endif()
    endif()

    include(cmake/Doxygen.cmake)
    enable_doxygen()

    if(myproject_ENABLE_STATIC_ANALYZER)
      if(MSVC)
        target_compile_options(${project_name} INTERFACE /analyze)
        target_link_libraries(${project_name} INTERFACE /analyze)
      elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(myproject_options INTERFACE -fanalyzer)
        target_link_libraries(myproject_options INTERFACE -fanalyzer)
        # https://clang.llvm.org/docs/UsersManual.html
      elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND MSVC)
        #target_compile_options(myproject_options INTERFACE --analyze)
        #target_link_libraries(myproject_options INTERFACE --analyze)
        # https://clang.llvm.org/docs/ClangCommandLineReference.html
      elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        #target_compile_options(myproject_options INTERFACE --analyze --analyzer-output html)
        #target_link_libraries(myproject_options INTERFACE --analyze --analyzer-output html)
      endif()
    endif()
  endif()

  include(cmake/Speedup.cmake)

endmacro()
