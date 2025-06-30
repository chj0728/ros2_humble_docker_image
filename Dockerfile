# 使用Ubuntu 22.04作为基础镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更新包列表并安装基础工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg2 \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 添加ROS2 GPG密钥
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# 添加ROS2仓库
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 更新包列表
RUN apt-get update

# 安装ROS2 Humble Desktop版本（包含GUI工具）
RUN apt-get install -y ros-humble-desktop

# 安装开发工具
RUN apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-argcomplete \
    python3-vcstool \
    build-essential \
    cmake \
    git \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 初始化rosdep
RUN rosdep init && rosdep update

# 创建ROS2工作空间
RUN mkdir -p /ros2_ws/src

# 设置工作目录
WORKDIR /ros2_ws

# 设置ROS2环境
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

# 创建启动脚本
RUN echo '#!/bin/bash\n\
source /opt/ros/humble/setup.bash\n\
exec "$@"' > /ros_entrypoint.sh && \
    chmod +x /ros_entrypoint.sh

# 设置入口点
ENTRYPOINT ["/ros_entrypoint.sh"]

# 默认命令
CMD ["bash"] 