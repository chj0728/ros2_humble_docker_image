#!/bin/bash

# ROS2 Humble 容器管理脚本

show_help() {
    echo "ROS2 Humble 容器管理工具"
    echo ""
    echo "使用方法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  build    - 构建Docker镜像"
    echo "  start    - 启动容器（映射当前目录到 /workspace）"
    echo "  stop     - 停止容器"
    echo "  restart  - 重启容器"
    echo "  enter    - 进入容器（自动配置ROS2环境）"
    echo "  status   - 查看容器状态"
    echo "  clean    - 清理容器和镜像"
    echo "  help     - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build   # 构建镜像"
    echo "  $0 start   # 启动容器"
    echo "  $0 enter   # 进入容器"
    echo "  $0 stop    # 停止容器"
}

check_container_status() {
    # 使用docker inspect更稳妥地判断容器是否在运行
    docker inspect -f '{{.State.Running}}' ros2-humble-container 2>/dev/null | grep -q true
}

build_image() {

    IMAGE_NAME=${1:-"ros2-humble:latest"}
    echo "🔨 构建ROS2 Humble Docker镜像..."
    
    # 创建必要的目录
    mkdir -p workspace home
    
    # 构建Docker镜像
    docker build -t "$IMAGE_NAME" .
    
    if [ $? -eq 0 ]; then
        echo "✅ Docker镜像构建成功！"
        echo "镜像名称: $IMAGE_NAME"
    else
        echo "❌ Docker镜像构建失败！"
        exit 1
    fi
}

start_container() {
    IMAGE_NAME=${1:-"ros2-humble:latest"}
    echo "🚀 基于镜像 $IMAGE_NAME 启动ROS2 Humble容器..."
    
    # 检查镜像是否存在
    if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        echo "❌ 镜像不存在，请先运行 ./manage.sh build $IMAGE_NAME 构建镜像"
        echo "▶️  或者运行 docker image ls 查看可用镜像"
        exit 1
    fi
    
    # 获取当前目录的绝对路径
    CURRENT_DIR=$(pwd)
    echo "当前工作目录: $CURRENT_DIR"
    
    # 检查容器是否已经在运行
    if check_container_status; then
        echo "⚠️  容器已在运行中"
        echo "如需重启，请先运行 ./manage.sh stop"
        return 0
    fi
    
    # 创建必要的目录
    mkdir -p workspace home

    # 允许X11连接
    xhost +local:docker
    
    # 启动容器，将当前目录映射到容器内的/workspace
    echo "启动容器，映射当前目录到 /workspace..."
    docker run -d \
        --rm \
        --name ros2-humble-container \
        --network host \
        --privileged \
        -e DISPLAY=$DISPLAY \
        -e ROS_DOMAIN_ID=0 \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v "$CURRENT_DIR:/workspace" \
        -v "$CURRENT_DIR/home:/home/ros" \
        -w /workspace \
        "$IMAGE_NAME" \
        tail -f /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ 容器启动成功！"
        echo ""
        echo "容器信息:"
        echo "- 容器名称: ros2-humble-container"
        echo "- 工作目录: $CURRENT_DIR -> /workspace"
        echo "- 网络模式: host"
        echo "- GUI支持: 已启用"
        echo ""
        echo "进入容器: ./manage.sh enter"
        echo "停止容器: ./manage.sh stop"
    else
        echo "❌ 容器启动失败！"
        exit 1
    fi
}

stop_container() {
    echo "🛑 停止ROS2 Humble容器..."
    
    # 检查容器是否在运行
    if check_container_status; then
        echo "正在停止容器..."
        docker stop ros2-humble-container
        docker rm ros2-humble-container
        echo "✅ 容器已停止"
    else
        echo "⚠️  容器未在运行或不存在"
    fi
    
    echo ""
    echo "查看所有容器状态:"
    docker ps -a | grep ros2-humble || echo "没有找到ros2-humble容器"
}

enter_container() {
    echo "🚪 进入ROS2 Humble容器..."
    
    # 检查容器是否在运行
    if ! check_container_status; then
        echo "❌ 容器未在运行，请先运行 ./manage.sh start 启动容器"
        exit 1
    fi
    
    echo "正在进入容器..."
    echo "当前目录已映射到容器内的 /workspace"
    echo "ROS2环境已自动配置"
    echo ""
    
    # 进入容器，自动source ROS2环境
    docker exec -it ros2-humble-container bash -c "
echo '欢迎使用ROS2 Humble容器！'
echo '当前工作目录: \$(pwd)'
echo 'ROS2环境已自动加载'
echo '可用命令: ros2, colcon, rosdep等'
echo '----------------------------------------'
source /opt/ros/humble/setup.bash
cd /workspace
exec bash
"
}

case "$1" in
    "build")
        image_name="$2"
        build_image $image_name
        ;;
    "start")
        image_name="$2"
        start_container $image_name
        ;;
    "stop")
        stop_container
        ;;
    "restart")
        echo "🔄 重启ROS2 Humble容器..."
        stop_container > /dev/null 2>&1
        sleep 2
        start_container
        ;;
    "enter")
        enter_container
        ;;
    "status")
        echo "📊 容器状态:"
        if check_container_status; then
            echo "✅ 容器正在运行"
            docker ps | grep ros2-humble
        else
            echo "❌ 容器未运行"
        fi
        echo ""
        echo "镜像状态:"
        docker images | grep ros2-humble || echo "❌ 镜像不存在"
        ;;
    "clean")
        echo "🧹 清理容器和镜像..."
        stop_container > /dev/null 2>&1
        docker rm -f ros2-humble-container 2>/dev/null || true
        docker rmi ros2-humble:latest 2>/dev/null || true
        echo "✅ 清理完成"
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 
