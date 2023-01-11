#!/usr/bin/env bash

# Lipo is a command line utility used to merge MacOS executable binary files, required by this script to merge the native LWJGL libraries.
# It's part of cctools, a collection of open-ish source MacOS development tools, and it's included with the xcode-select command line tools.
if ! command -v lipo &> /dev/null
then
  echo "Error: Lipo is not installed! Lipo is a command line tool which merges MacOS executable binary files."
  echo "If you are running MacOS, please install the xcode-select command line tools."
  echo "If you aren't, there may be a port of cctools for your operating system, which may include it."
  return 1 2> /dev/null || exit 1
fi

echo "Merging both LWJGL builds..."

# Delete the temp folders if they exist, along with the existing merged LWJGL.
rm -rf ./_merge/ ./merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar
# Create the temp folders.
mkdir -p ./_merge/{arm,x86_64,frankenstein}/

# Unzip both LWJGL versions into the temp folders.
unzip ./arm/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar -d ./_merge/arm
unzip ./x86_64/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar -d ./_merge/x86_64

# Use lipo to merge the builds of the native libraries for different architectures.
lipo -create ./_merge/x86_64/liblwjgl.dylib ./_merge/arm/liblwjgl.dylib -output ./_merge/frankenstein/liblwjgl.dylib  
lipo -create ./_merge/x86_64/openal.dylib ./_merge/arm/openal.dylib -output ./_merge/frankenstein/openal.dylib   

# Copy META-INF
cp -r ./_merge/x86_64/META-INF/ ./_merge/frankenstein/META-INF/

# Try to use the most efficient compression program if available.
if ! command -v 7z &> /dev/null
then
  (cd ./_merge/frankenstein/ && zip -o -X -9 -r ../../merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar ./*.* ./META-INF/*.*)
else
  7z a -mx=9 -tzip ./merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar ./_merge/frankenstein/*.* ./_merge/frankenstein/META-INF/*.*
fi

# Optimise file sizes further if possible.
if command -v advzip &> /dev/null
then
  advzip --shrink-extra -z ./merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar
  advzip --shrink-normal -z ./merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar
  advzip --shrink-fast -z ./merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar
fi

# Remove some zip metadata if possible.
if command -v strip-nondeterminism &> /dev/null
then
  strip-nondeterminism ./merged/lwjgl-platform-2.9.4-nightly-20150209-natives-osx.jar
fi

# Delete temp folder.
rm -rf ./_merge/

echo "It's alive!"
