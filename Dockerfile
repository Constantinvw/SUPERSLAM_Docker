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
          -DCMAKE_CXX_FLAGS=-std=c++11 .. && \
    make -j"$(nproc)" && make install && \
    rm -rf /tmp/Pangolin


COPY include/libtorch /opt/libtorch

# ORB-SLAM3 Download
COPY src/SUPER_SLAM3 /ORB_SLAM3
WORKDIR /ORB_SLAM3

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
RUN mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release  -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda -DCMAKE_CXX_FLAGS="-w" && \
    make -j4

    # -DCMAKE_PREFIX_PATH=/opt/libtorch -DTorch_DIR=/opt/libtorch/share/cmake/Torch