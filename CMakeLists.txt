cmake_minimum_required(VERSION 3.8)
project(mivia_rover_nav2_bringup)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# ----------------------------
# Dependencies
# ----------------------------
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)

# ----------------------------
# Targets (from src/)
# ----------------------------
# Esempio: nodo adattatore Twist -> TwistStamped
# Se non hai ancora il file, puoi commentare questo blocco e abilitarlo quando lo aggiungi.
add_executable(twist_adapter_node
  src/twist_adapter_node.cpp
)
ament_target_dependencies(twist_adapter_node
  rclcpp
  geometry_msgs
)

install(TARGETS
  twist_adapter_node
  DESTINATION lib/${PROJECT_NAME}
)

# ----------------------------
# Install resources (launch/, config/)
# ----------------------------
install(
  DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

install(
  DIRECTORY config
  DESTINATION share/${PROJECT_NAME}
)

# ----------------------------
# Testing
# ----------------------------
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  set(ament_cmake_copyright_FOUND TRUE)
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()