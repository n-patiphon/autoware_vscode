# Debugging Guide

This document explains how to debug Autoware code using the development environment.

## Prerequisites

- Autoware workspace set up with the Dev Containers
- Basic understanding of GDB or CUDA-GDB
- VS Code with the C/C++ extension installed (already in the container)

## Debug Types

There are several debugging approaches available:

1. **GDB Debugging**: For standard C++ code
2. **CUDA-GDB Debugging**: For NVIDIA CUDA code
3. **ROS 2 Node Debugging**: For debugging ROS 2 nodes
4. **Component Container Debugging**: For debugging component container nodes

## Building for Debugging

Before debugging, build your package in Debug mode:

1. Open VS Code command palette (`Ctrl+Shift+P`)
2. Type and select `Tasks: Run Task`
3. Select `Build: Package (Debug)`
4. Enter the package name you want to debug

Alternatively, use the terminal:

```bash
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=1 --packages-select your_package_name
```

Note: `-DCMAKE_CUDA_FLAGS="-g -G"` has to be added for CUDA packages if not specified in CMakeLists.txt.

## Debugging Process

### 1. Setting Breakpoints

1. Open the source file you want to debug
2. Click in the left margin next to the line number to set a breakpoint
3. A red dot will appear to indicate the breakpoint

### 2. Launching with GDB Server

To debug a ROS 2 node, you need to launch it with the GDB server:

```bash
# For standard C++ code
ros2 launch package_name launch_name --launch-prefix 'gdbserver localhost:4242' --launch-prefix-filter your_executable

# For component containers
ros2 launch package_name launch_name --launch-prefix 'gdbserver localhost:4242' --launch-prefix-filter component_container_mt

# For CUDA code
ros2 launch package_name launch_name --launch-prefix 'cuda-gdbserver localhost:4242' --launch-prefix-filter your_executable
```

### 3. Attaching the Debugger

1. Open VS Code command palette (`Ctrl+Shift+P`)
2. Type and select `View: Show Run and Debug`
3. From the dropdown, select "Launch gdb / cuda-gdb with server"
4. Press F5 to start debugging

## Additional Resources

- [GDB Documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [CUDA-GDB Documentation](https://docs.nvidia.com/cuda/cuda-gdb/index.html)
- [VS Code Debugging Documentation](https://code.visualstudio.com/docs/editor/debugging)
