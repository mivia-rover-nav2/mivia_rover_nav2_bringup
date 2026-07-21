#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration

from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    # ------------------------------------------------------------------
    # Share directories
    # ------------------------------------------------------------------
    nav2_share = get_package_share_directory("nav2_bringup")
    this_share = get_package_share_directory("mivia_rover_nav2_bringup")

    # ------------------------------------------------------------------
    # Default params file (SIM configuration)
    # ------------------------------------------------------------------
    default_params_file = os.path.join(
        this_share,
        "config",
        "rpp",
        "exp_rpp_setting_spinta.yaml",
    )

    # ------------------------------------------------------------------
    # Launch configurations
    # ------------------------------------------------------------------
    namespace = LaunchConfiguration("namespace")
    use_sim_time = LaunchConfiguration("use_sim_time")
    autostart = LaunchConfiguration("autostart")
    params_file = LaunchConfiguration("params_file")

    # ------------------------------------------------------------------
    # Declare arguments (Nav2-compatible)
    # ------------------------------------------------------------------
    declare_args = [
        DeclareLaunchArgument(
            "namespace",
            default_value="",
            description="Top-level namespace for Nav2",
        ),
        DeclareLaunchArgument(
            "use_sim_time",
            default_value="true",
            description="Use simulation (Gazebo) clock",
        ),
        DeclareLaunchArgument(
            "autostart",
            default_value="true",
            description="Automatically startup Nav2 lifecycle nodes",
        ),
        DeclareLaunchArgument(
            "params_file",
            default_value=default_params_file,
            description="Nav2 parameters file",
        ),
    ]

    # ------------------------------------------------------------------
    # Nav2 bringup (unchanged semantics)
    # ------------------------------------------------------------------
    nav2_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(nav2_share, "launch", "navigation_launch.py")
        ),
        launch_arguments={
            "namespace": namespace,
            "use_sim_time": use_sim_time,
            "autostart": autostart,
            "params_file": params_file,
        }.items(),
    )

    # ------------------------------------------------------------------
    # Twist Adapter node (C++)
    # ------------------------------------------------------------------
    twist_adapter_node = Node(
        package="mivia_rover_nav2_bringup",
        executable="twist_adapter_node",
        name="twist_adapter",
        output="screen",
        parameters=[
            {
                # Mode: Nav2 (Twist) -> downstream (TwistStamped)
                "mode": "twist_to_stamped",

                # Topics
                "input_topic": "/cmd_vel",
                "output_topic": "/cmd_vel_stamped",

                # Header handling
                "frame_id": "base_link",
                "stamp_with_now": True,

                # Time source consistency with Nav2
                "use_sim_time": use_sim_time,
            }
        ],
    )

    # ------------------------------------------------------------------
    # Final LaunchDescription
    # ------------------------------------------------------------------
    return LaunchDescription(
        declare_args
        + [
            nav2_launch,
            twist_adapter_node,
        ]
    )
