# Filename: Python.cmake
#
# Description: This file provides support functions for building/installing
#   Python extension modules and/or pure-Python packages.
#
# Functions:
#   add_python_target(target [source1 [source2 ...]])
#

#
# Function: add_python_target(target [EXPORT exp] [COMPONENT comp]
#                                    [source1 [source2 ...]])
# Build the provided source(s) as a Python extension module, linked against the
# Python runtime library.
#
# Note that this also takes care of installation, unlike other target creation
# commands in CMake.  The EXPORT and COMPONENT keywords allow passing the
# corresponding options to install(), but default to "Python" otherwise.
#
function(add_python_target target)
  if(NOT HAVE_PYTHON)
    return()
  endif()

  string(REGEX REPLACE "^.*\\." "" basename "${target}")
  set(sources)
  set(component "Python")
  set(export "Python")
  foreach(arg ${ARGN})
    if(arg STREQUAL "COMPONENT")
      set(keyword "component")

    elseif(arg STREQUAL "EXPORT")
      set(keyword "export")

    elseif(keyword)
      set(${keyword} "${arg}")
      unset(keyword)

    else()
      list(APPEND sources "${arg}")

    endif()
  endforeach(arg)

  string(REGEX REPLACE "\\.[^.]+$" "" namespace "${target}")
  string(REPLACE "." "/" slash_namespace "${namespace}")

  if(CMAKE_VERSION VERSION_LESS "3.26")
    add_library(${target} ${MODULE_TYPE} ${sources})
    target_link_libraries(${target} PKG::PYTHON)
  else()
    if(MODULE_TYPE STREQUAL "MODULE")
      Python_add_library(${target} MODULE USE_SABI 3.3 ${sources})
    else()
      Python_add_library(${target} ${MODULE_TYPE} ${sources})
    endif()
  endif()

  if(BUILD_SHARED_LIBS)
    set(_outdir "${PANDA_OUTPUT_DIR}/${slash_namespace}")

    set_target_properties(${target} PROPERTIES
      LIBRARY_OUTPUT_DIRECTORY "${_outdir}"
      OUTPUT_NAME "${basename}"
      PREFIX ""
      SUFFIX "${PYTHON_EXTENSION_SUFFIX}")

    # This is explained over in CompilerFlags.cmake
    foreach(_config ${CMAKE_CONFIGURATION_TYPES})
      string(TOUPPER "${_config}" _config)
      set_target_properties(${target} PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${_config} "${_outdir}")
    endforeach(_config)

    if(PYTHON_ARCH_INSTALL_DIR)
      install(TARGETS ${target} EXPORT "${export}" COMPONENT "${component}" DESTINATION "${PYTHON_ARCH_INSTALL_DIR}/${slash_namespace}")
    endif()

  else()
    set_target_properties(${target} PROPERTIES
      OUTPUT_NAME "${basename}"
      PREFIX "libpy.${namespace}.")

    install(TARGETS ${target} EXPORT "${export}" COMPONENT "${component}" DESTINATION ${CMAKE_INSTALL_LIBDIR})

  endif()

endfunction(add_python_target)
