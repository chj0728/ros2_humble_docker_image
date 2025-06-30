# ROS2 Humble Docker 镜像

这是一个基于 Ubuntu 22.04 并预装 ROS2 Humble 的 Docker 镜像。

## 系统要求

- Docker
- Docker Compose
- Ubuntu 22.04 或兼容的 Linux 发行版
- X11支持（用于GUI工具）

## 快速开始

### 方法一：使用统一管理脚本（推荐）

```bash
# 构建镜像
./manage.sh build

# 启动容器（映射当前目录到 /workspace）
./manage.sh start

# 进入容器
./manage.sh enter

# 停止容器
./manage.sh stop

# 查看状态
./manage.sh status
```

### 方法二：使用独立脚本

```bash
# 1. 构建镜像
chmod +x build.sh
./build.sh

# 2. 启动容器（映射当前目录）
chmod +x start.sh
./start.sh

# 3. 进入容器
chmod +x enter.sh
./enter.sh

# 4. 停止容器
chmod +x stop.sh
./stop.sh
```

### 方法三：使用 docker-compose

```bash
# 构建并启动
docker compose up -d

# 进入容器
docker compose exec ros2-humble bash -c 'source /opt/ros/humble/setup.bash && bash'

# 停止
docker compose down
```

## 脚本说明

### 统一管理脚本 (`manage.sh`)
- `./manage.sh build` - 构建Docker镜像
- `./manage.sh start` - 启动容器，将当前目录映射到 `/workspace`
- `./manage.sh stop` - 停止容器
- `./manage.sh restart` - 重启容器
- `./manage.sh enter` - 进入容器（自动配置ROS2环境）
- `./manage.sh status` - 查看容器和镜像状态
- `./manage.sh clean` - 清理容器和镜像
- `./manage.sh help` - 显示帮助信息

### 独立脚本
- `start.sh` - 启动容器，映射当前目录
- `stop.sh` - 停止容器
- `enter.sh` - 进入容器
- `build.sh` - 构建镜像
- `run.sh` - 使用docker-compose启动

## 目录映射

使用 `./manage.sh start` 时：
- **当前目录** → `/workspace` (容器内工作目录)
- **./home** → `/home/ros` (用户配置目录)
- **X11显示** → 支持GUI工具

## 容器特性

- **基础系统**: Ubuntu 22.04
- **ROS2版本**: Humble Hawksbill
- **包含组件**: 
  - ROS2 Desktop (包含GUI工具如rviz2, rqt等)
  - 开发工具 (colcon, rosdep等)
  - 构建工具 (cmake, build-essential等)
- **工作目录**: `/workspace` (映射当前目录)
- **时区**: Asia/Shanghai
- **GUI支持**: 完整的X11转发支持

## 目录结构

```
.
├── Dockerfile              # Docker镜像定义
├── docker-compose.yml      # Docker Compose配置
├── manage.sh              # 统一管理脚本（推荐）
├── start.sh               # 启动容器脚本
├── stop.sh                # 停止容器脚本
├── enter.sh               # 进入容器脚本
├── build.sh               # 构建脚本
├── run.sh                 # docker-compose运行脚本
├── README.md              # 说明文档
├── workspace/             # 挂载的ROS2工作空间
└── home/                  # 挂载的home目录
```

## 使用示例

### 进入容器后测试ROS2

```bash
# 进入容器
./manage.sh enter

# 测试ROS2安装
ros2 --help

# 查看可用的包
ros2 pkg list

# 运行一个简单的节点
ros2 run demo_nodes_cpp talker

# 在另一个终端运行监听器
ros2 run demo_nodes_cpp listener
```

### 创建ROS2包

```bash
# 进入容器
./manage.sh enter

# 进入工作目录（当前目录已映射）
cd /workspace

# 创建Python包
ros2 pkg create --build-type ament_python my_python_package

# 创建C++包
ros2 pkg create --build-type ament_cmake my_cpp_package

# 构建工作空间
colcon build
```

### 使用GUI工具

```bash
# 进入容器
./manage.sh enter

# 启动rviz2（3D可视化工具）
rviz2

# 启动rqt（通用GUI工具）
rqt

# 启动rqt_graph（节点图可视化）
rqt_graph

# 启动rqt_plot（数据绘图工具）
rqt_plot

# 启动rqt_console（日志查看器）
rqt_console
```

### 完整工作流程示例

```bash
# 1. 启动容器
./manage.sh start

# 2. 进入容器
./manage.sh enter

# 3. 在容器内启动一个ROS2节点
ros2 run demo_nodes_cpp talker

# 4. 在另一个终端进入容器并启动rviz2
./manage.sh enter
rviz2
```

## 网络配置

容器使用 `host` 网络模式，这意味着：
- 容器可以直接访问主机网络
- ROS2节点可以与其他ROS2节点通信
- 无需额外的端口映射

## GUI支持

容器完全支持GUI应用程序：
- ✅ 自动挂载X11显示
- ✅ 设置DISPLAY环境变量
- ✅ 支持所有ROS2 GUI工具
- ✅ 已测试的工具：rviz2, rqt, rqt_graph, rqt_plot, rqt_console

### GUI工具列表

| 工具 | 描述 | 状态 |
|------|------|------|
| rviz2 | 3D可视化工具 | ✅ 可用 |
| rqt | 通用GUI工具 | ✅ 可用 |
| rqt_graph | 节点图可视化 | ✅ 可用 |
| rqt_plot | 数据绘图工具 | ✅ 可用 |
| rqt_console | 日志查看器 | ✅ 可用 |
| rqt_top | 系统监控 | ✅ 可用 |

## 故障排除

### 权限问题
如果遇到权限问题，确保Docker用户有适当的权限：
```bash
sudo usermod -aG docker $USER
```

### GUI显示问题
如果GUI工具无法显示，确保X11转发已启用：
```bash
xhost +local:docker
```

### 网络问题
如果ROS2节点间无法通信，检查：
- 容器是否使用host网络模式
- 防火墙设置
- ROS_DOMAIN_ID设置

### 容器状态问题
如果容器状态检测异常，可以手动检查：
```bash
docker ps | grep ros2-humble
docker inspect ros2-humble-container
```

## 测试

### 手动测试
```bash
# 测试容器状态
./manage.sh status

# 测试ROS2环境
./manage.sh enter
ros2 --help

# 测试GUI工具
./manage.sh enter
rviz2 --help
```

## 清理

```bash
# 使用管理脚本清理
./manage.sh clean

# 或手动清理
./manage.sh stop
docker rm -f ros2-humble-container
docker rmi ros2-humble:latest
docker system prune -a
```

## 许可证

本项目基于MIT许可证开源。 