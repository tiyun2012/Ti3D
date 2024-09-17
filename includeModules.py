import os
import requests

# List of required files and their download URLs
imgui_required_files = {
    "imgui.h": "https://github.com/ocornut/imgui/raw/master/imgui.h",
    "imgui.cpp": "https://github.com/ocornut/imgui/raw/master/imgui.cpp",
    "imgui_draw.cpp": "https://github.com/ocornut/imgui/raw/master/imgui_draw.cpp",
    "imgui_widgets.cpp": "https://github.com/ocornut/imgui/raw/master/imgui_widgets.cpp",
    "imgui_demo.cpp": "https://github.com/ocornut/imgui/raw/master/imgui_demo.cpp",
    "imgui_impl_glfw.cpp": "https://github.com/ocornut/imgui/raw/master/backends/imgui_impl_glfw.cpp",
    "imgui_impl_opengl3.cpp": "https://github.com/ocornut/imgui/raw/master/backends/imgui_impl_opengl3.cpp",
    "imgui_impl_glfw.h": "https://github.com/ocornut/imgui/raw/master/backends/imgui_impl_glfw.h",
    "imgui_impl_opengl3.h": "https://github.com/ocornut/imgui/raw/master/backends/imgui_impl_opengl3.h"
}

# List of required files and their download URLs
glfw_required_files = {
    "glfw3.h": "https://github.com/glfw/glfw/raw/master/include/GLFW/glfw3.h",
    "glfw3native.h": "https://github.com/glfw/glfw/raw/master/include/GLFW/glfw3native.h",
    "glfw3.dll": "https://github.com/glfw/glfw/releases/download/3.3.4/glfw-3.3.4.bin.WIN32.zip",
    "glfw3.lib": "https://github.com/glfw/glfw/releases/download/3.3.4/glfw-3.3.4.bin.WIN32.zip",
    "glfw3dll.lib": "https://github.com/glfw/glfw/releases/download/3.3.4/glfw-3.3.4.bin.WIN32.zip"
}

# Directory to save the files
save_dirs = ["IMGUI","GLFW"]
all_required_files=[imgui_required_files, glfw_required_files]

# Create the directory if it doesn't exist
for save_dir in save_dirs:
    if not os.path.exists(save_dir):
        os.makedirs(save_dir)

# Function to download a file
def download_file(url, save_path):
    response = requests.get(url)
    with open(save_path, 'wb') as file:
        file.write(response.content)
    print(f"Downloaded: {save_path}")

# Check and download missing files
for required_files in all_required_files:
    for file_name, url in required_files.items():
        file_path = os.path.join(save_dirs[all_required_files.index(required_files)], file_name)
        if not os.path.exists(file_path):
            print(f"Missing: {file_name}")
            download_file(url, file_path)
        else:
            print(f"Already exists: {file_name}")

print("All required files are checked and downloaded if necessary.")
