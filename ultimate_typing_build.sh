dir=`pwd`
echo $dir

cd ~/godot4Projects/typing_practice
rm -rf ./build/linux
mkdir -p ./build/linux
godot --headless --export-debug "Linux/X11"
cp -rf Texts build/linux/
cd build/linux
zip -r ultimate-myanmar-typing-wizard-linux.zip *

read -p "Build Windows? (yes/no): " build_windows
build_windows=${build_windows:-no}
if [[ $build_windows =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
  echo "Building for Windows..."
     
    cd ~/godot4Projects/typing_practice
    rm -rf ./build/windows
    mkdir -p ./build/windows
    godot --headless --export-debug "Windows Desktop"
    cp -rf Texts build/windows/
    cd build/windows
    zip -r ultimate-myanmar-typing-wizard-windows.zip *

else
  echo "Not building for Windows."
fi

