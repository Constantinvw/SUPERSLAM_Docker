FROM nvidia/cuda:12.1.1-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------
RUN apt-get update && apt-get install -y \
    git wget curl unzip xauth x11-apps libboost-all-dev libssl-dev libopencv-dev\
    build-essential cmake \
    libgl1-mesa-dev libglew-dev libpython3-dev \
    libeigen3-dev pkg-config \
    python3 python3-pip python3-numpy \
    libjpeg-turbo8 libpng16-16 libtiff5 \
    libavcodec-dev libavformat-dev libswscale-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgtk-3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# cuDNN über das bereits vorkonfigurierte NVIDIA-Repo installieren
RUN apt-get update && \
    apt-get install -y libcudnn8 libcudnn8-dev && \
    rm -rf /var/lib/apt/lists/*


# RUN cd /opt && \
#     wget https://github.com/Kitware/CMake/releases/download/v3.27.6/cmake-3.27.6-linux-x86_64.sh && \
#     chmod +x cmake-3.27.6-linux-x86_64.sh && \
#     ./cmake-3.27.6-linux-x86_64.sh --skip-license --prefix=/usr/local && \
#     rm cmake-3.27.6-linux-x86_64.sh

# OpenCV 4.4.0
COPY src/opencv /tmp/opencv
RUN cd /tmp/opencv && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release \
          -D BUILD_EXAMPLES=OFF -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF -D BUILD_DOCS=OFF \
          -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j"$(nproc)" && make install && \
    rm -rf /tmp/opencv

# Pangolin v0.6
COPY src/Pangolin /tmp/Pangolin
RUN cd /tmp/Pangolin && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_STANDARD=17 .. && \
    make -j"$(nproc)" && make install && \
    rm -rf /tmp/Pangolin


# # LibTorch 1.6.0 (GPU, CUDA 10.2, C++11 ABI – so verlangt es SUPERSLAM3)
# RUN cd /opt && \
#     curl -L "https://download.pytorch.org/libtorch/cu102/libtorch-cxx11-abi-shared-with-deps-1.6.0.zip" \
#         -o libtorch.zip && \
#     unzip libtorch.zip && \
#     rm libtorch.zip

# LibTorch: benutze exakt die lokale Version (2.1.2+cu121)
# COPY libtorch /opt/libtorch

# ENV Torch_DIR=/opt/libtorch/share/cmake/Torch
# ENV LD_LIBRARY_PATH=/opt/libtorch/lib:${LD_LIBRARY_PATH}

# LibTorch 2.1.2 + CUDA 12.1 (C++11-ABI, mit Dependencies)
RUN cd /opt && \
    curl -L "https://download.pytorch.org/libtorch/cu121/libtorch-cxx11-abi-shared-with-deps-2.1.2%2Bcu121.zip" \
        -o libtorch.zip && \
    unzip libtorch.zip && \
    rm libtorch.zip

# CMake soll Torch unter /opt/libtorch finden
ENV Torch_DIR=/opt/libtorch/share/cmake/Torch
ENV CMAKE_PREFIX_PATH=/opt/libtorch
ENV LD_LIBRARY_PATH=/opt/libtorch/lib:${LD_LIBRARY_PATH}



# ORB-SLAM3 Download
COPY src/SUPER_SLAM3 /ORB_SLAM3
WORKDIR /ORB_SLAM3

RUN grep -rl --include=CMakeLists.txt "std=c++11" . | xargs sed -i 's/std=c++11/std=c++17/g' || true && \
    grep -rl --include=CMakeLists.txt "CMAKE_CXX_STANDARD 11" . | xargs sed -i 's/CMAKE_CXX_STANDARD 11/CMAKE_CXX_STANDARD 17/g' || true && \
    grep -rl --include=CMakeLists.txt "CMAKE_CXX_STANDARD 14" . | xargs sed -i 's/CMAKE_CXX_STANDARD 14/CMAKE_CXX_STANDARD 17/g' || true

RUN grep -rl "monotonic_clock" /ORB_SLAM3/Examples | xargs sed -i 's/monotonic_clock/steady_clock/g'

# Thirdparty/DBoW2
RUN cd Thirdparty/DBoW2 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j"$(nproc)"

# Thirdparty/g2o
RUN cd Thirdparty/g2o && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j"$(nproc)"

# Thirdparty/Sophus
RUN cd Thirdparty/Sophus && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j"$(nproc)"

# Vocabulary
RUN cd Vocabulary && \
    tar -xf ORBvoc.txt.tar.gz

# ORB-SLAM3 Build
RUN rm -rf build && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_CXX_FLAGS="-w" \
        -DTorch_DIR=/opt/libtorch/share/cmake/Torch && \
    make -j4


    # -DCMAKE_PREFIX_PATH=/opt/libtorch -DTorch_DIR=/opt/libtorch/share/cmake/Torch