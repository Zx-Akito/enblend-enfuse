#!/bin/bash
# Script to build enfuse and enblend as universal binaries (x86_64 + arm64)
# All universal dependency libraries are expected in libs-universal/

set -e

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
LIBS_DIR="${PROJECT_ROOT}/libs-universal"

echo -e "${GREEN}=== Build enfuse/enblend Universal Binary ===${NC}"
echo ""

# Check if universal libraries exist
if [ ! -d "${LIBS_DIR}/lib" ]; then
    echo -e "${RED}Error: Universal libraries not found in ${LIBS_DIR}${NC}"
    echo "Make sure universal libraries are placed in libs-universal/ directory."
    exit 1
fi

echo -e "${YELLOW}Verifying universal libraries...${NC}"
for lib in libgsl.dylib liblcms2.dylib libtiff.dylib libjpeg.dylib libpng.dylib libvigraimpex.dylib; do
    if [ -f "${LIBS_DIR}/lib/${lib}" ]; then
        ARCH=$(lipo -info "${LIBS_DIR}/lib/${lib}" 2>/dev/null | grep -o "x86_64 arm64" || echo "")
        if [[ "$ARCH" == *"x86_64 arm64"* ]]; then
            echo -e "  ${GREEN}✓${NC} ${lib} (universal)"
        else
            echo -e "  ${YELLOW}⚠${NC} ${lib} (not universal)"
        fi
    else
        echo -e "  ${RED}✗${NC} ${lib} (not found)"
    fi
done
echo ""

# Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo -e "${YELLOW}Configuring CMake...${NC}"

# Set environment variables to ensure CMake finds libraries in libs-universal
export PKG_CONFIG_PATH="${LIBS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export CMAKE_LIBRARY_PATH="${LIBS_DIR}/lib:${CMAKE_LIBRARY_PATH}"
export CMAKE_INCLUDE_PATH="${LIBS_DIR}/include:${CMAKE_INCLUDE_PATH}"

echo -e "  Project root: ${PROJECT_ROOT}"
echo -e "  Using libraries from: ${LIBS_DIR}/lib"
echo -e "  Using headers from: ${LIBS_DIR}/include"
echo ""

# Convert to absolute paths for CMake
LIBS_DIR_ABS="$(cd "${LIBS_DIR}" && pwd)"
BUILD_DIR_ABS="$(cd "${BUILD_DIR}" && pwd)"

cmake "${PROJECT_ROOT}" \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_PREFIX_PATH="${LIBS_DIR_ABS}" \
    -DCMAKE_LIBRARY_PATH="${LIBS_DIR_ABS}/lib" \
    -DCMAKE_INCLUDE_PATH="${LIBS_DIR_ABS}/include" \
    -DCMAKE_INSTALL_PREFIX="${BUILD_DIR_ABS}/install" \
    -DCMAKE_BUILD_TYPE=Release

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: CMake configuration failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Building enfuse and enblend...${NC}"
make -j$(sysctl -n hw.ncpu)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""

# Verify universal binaries
echo -e "${YELLOW}Verifying universal binaries:${NC}"
if [ -f "${BUILD_DIR}/bin/enfuse" ]; then
    ARCH_ENFUSE=$(lipo -info "${BUILD_DIR}/bin/enfuse" 2>/dev/null | grep -o "x86_64 arm64" || echo "")
    if [[ "$ARCH_ENFUSE" == *"x86_64 arm64"* ]]; then
        echo -e "  ${GREEN}✓${NC} enfuse: universal binary (x86_64 + arm64)"
        file "${BUILD_DIR}/bin/enfuse" | grep -q "universal" && echo -e "    Location: ${BUILD_DIR}/bin/enfuse"
    else
        echo -e "  ${YELLOW}⚠${NC} enfuse: not a universal binary"
    fi
else
    echo -e "  ${RED}✗${NC} enfuse: not found"
fi

if [ -f "${BUILD_DIR}/bin/enblend" ]; then
    ARCH_ENBLEND=$(lipo -info "${BUILD_DIR}/bin/enblend" 2>/dev/null | grep -o "x86_64 arm64" || echo "")
    if [[ "$ARCH_ENBLEND" == *"x86_64 arm64"* ]]; then
        echo -e "  ${GREEN}✓${NC} enblend: universal binary (x86_64 + arm64)"
        file "${BUILD_DIR}/bin/enblend" | grep -q "universal" && echo -e "    Location: ${BUILD_DIR}/bin/enblend"
    else
        echo -e "  ${YELLOW}⚠${NC} enblend: not a universal binary"
    fi
else
    echo -e "  ${RED}✗${NC} enblend: not found"
fi

echo ""
echo -e "${GREEN}Universal binaries are located at:${NC}"
echo "  - ${BUILD_DIR}/bin/enfuse"
echo "  - ${BUILD_DIR}/bin/enblend"
echo ""

# Test run
if [ -f "${BUILD_DIR}/bin/enfuse" ]; then
    echo -e "${YELLOW}Testing enfuse executable:${NC}"
    "${BUILD_DIR}/bin/enfuse" --version 2>&1 | head -1
fi

echo ""
echo -e "${GREEN}Done!${NC}"

