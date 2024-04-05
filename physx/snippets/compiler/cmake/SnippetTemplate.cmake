## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
##  * Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
##  * Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
##  * Neither the name of NVIDIA CORPORATION nor the names of its
##    contributors may be used to endorse or promote products derived
##    from this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ''AS IS'' AND ANY
## EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
## CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
## PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
## PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
## OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
## OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
## Copyright (c) 2008-2023 NVIDIA Corporation. All rights reserved.

#
# Build Snippet common template
#

# Include here after the directories are defined so that the platform specific file can use the variables.
INCLUDE(${PHYSX_ROOT_DIR}/snippets/${PROJECT_CMAKE_FILES_DIR}/${TARGET_BUILD_PLATFORM}/SnippetTemplate.cmake)

STRING(TOLOWER ${SNIPPET_NAME} SNIPPET_NAME_LOWER)
FILE(GLOB SnippetCppSources ${PHYSX_ROOT_DIR}/snippets/snippet${SNIPPET_NAME_LOWER}/*.cpp)
FILE(GLOB SnippetSwiftSources ${PHYSX_ROOT_DIR}/snippets/snippet${SNIPPET_NAME_LOWER}/*.swift)
FILE(GLOB SnippetHeaders ${PHYSX_ROOT_DIR}/snippets/snippet${SNIPPET_NAME_LOWER}/*.h)

ADD_EXECUTABLE(Snippet${SNIPPET_NAME} ${SNIPPET_BUNDLE}
	${SNIPPET_PLATFORM_SOURCES}

	${SnippetCppSources}
	${SnippetSwiftSources}
	${SnippetHeaders}
)

if (SnippetSwiftSources)
	include(AddSwift.cmake)
	_swift_generate_cxx_header_target(
		snippet_${SNIPPET_NAME_LOWER}_swift_h
		Swift${SNIPPET_NAME}
		${CMAKE_CURRENT_BINARY_DIR}/include/SwiftModule/${SNIPPET_NAME_LOWER}.h
		SOURCES ${SnippetSwiftSources}
		SEARCH_PATHS "${SnippetHeaders}" "${PHYSX_ROOT_DIR}/include" "${PHYSX_ROOT_DIR}/source/physxextensions/src"
	)
	set(CMAKE_Swift_FLAGS "${CMAKE_Swift_FLAGS} -cxx-interoperability-mode=default -parse-as-library -swift-version 6")
	get_target_property(CXX_DEFINES Snippet${SNIPPET_NAME} COMPILE_DEFINITIONS)

	foreach(d ${CXX_DEFINES})
		message(STATUS "CXX_FLAGS: ${d}")
		set(CMAKE_Swift_FLAGS "${CMAKE_Swift_FLAGS} -Xcc ${d}")
	endforeach()

	# mangling結果とgenerate headerで使われるmodule名が一致しないとリンクエラーになる
	target_compile_options(Snippet${SNIPPET_NAME} PRIVATE $<$<COMPILE_LANGUAGE:Swift>:-module-name> $<$<COMPILE_LANGUAGE:Swift>:Swift${SNIPPET_NAME}>)
	add_dependencies(Snippet${SNIPPET_NAME} snippet_${SNIPPET_NAME_LOWER}_swift_h)
	target_include_directories(Snippet${SNIPPET_NAME} PUBLIC ${PHYSX_ROOT_DIR}/snippets/snippet${SNIPPET_NAME_LOWER}/swiftinclude)
endif()

TARGET_INCLUDE_DIRECTORIES(Snippet${SNIPPET_NAME}
	PRIVATE ${SNIPPET_PLATFORM_INCLUDES}

	PRIVATE ${PHYSX_ROOT_DIR}/include
	PRIVATE ${PHYSX_ROOT_DIR}/source/physxextensions/src
	PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/include
)

TARGET_COMPILE_DEFINITIONS(Snippet${SNIPPET_NAME}
	PRIVATE ${SNIPPET_COMPILE_DEFS}
)

SET_TARGET_PROPERTIES(Snippet${SNIPPET_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PX_EXE_OUTPUT_DIRECTORY_DEBUG}${EXE_PLATFORM_DIR}
    RUNTIME_OUTPUT_DIRECTORY_PROFILE ${PX_EXE_OUTPUT_DIRECTORY_PROFILE}${EXE_PLATFORM_DIR}
    RUNTIME_OUTPUT_DIRECTORY_CHECKED ${PX_EXE_OUTPUT_DIRECTORY_CHECKED}${EXE_PLATFORM_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PX_EXE_OUTPUT_DIRECTORY_RELEASE}${EXE_PLATFORM_DIR}

    OUTPUT_NAME Snippet${SNIPPET_NAME}${EXE_SUFFIX}
)

IF(PVDRuntimeBuilt)
	SET(PVDRuntime_Lib "PVDRuntime")
ELSE()
	SET(PVDRuntime_Lib "")
ENDIF()

TARGET_LINK_LIBRARIES(Snippet${SNIPPET_NAME}
	PUBLIC PhysXExtensions PhysXPvdSDK PhysX PhysXVehicle PhysXVehicle2 PhysXCharacterKinematic PhysXCooking PhysXCommon PhysXFoundation SnippetUtils ${PVDRuntime_Lib}
	PUBLIC ${SNIPPET_PLATFORM_LINKED_LIBS})

IF(CUSTOM_SNIPPET_TARGET_PROPERTIES)
	SET_TARGET_PROPERTIES(Snippet${SNIPPET_NAME} PROPERTIES
	   ${CUSTOM_SNIPPET_TARGET_PROPERTIES}
	)
ENDIF()

IF(PX_GENERATE_SOURCE_DISTRO)
	LIST(APPEND SOURCE_DISTRO_FILE_LIST ${SNIPPET_PLATFORM_SOURCES})
	LIST(APPEND SOURCE_DISTRO_FILE_LIST ${SnippetCppSources})
	LIST(APPEND SOURCE_DISTRO_FILE_LIST ${SnippetSwiftSources})
	LIST(APPEND SOURCE_DISTRO_FILE_LIST ${SnippetHeaders})
ENDIF()
