#!/usr/bin/env bash
#
# Set /velocity_smoother and /controller_server parameters at runtime
# via `ros2 param set`.
#
# Usage:
#   ./set_velocity_smoother_params.sh                      # apply to both nodes
#   ./set_velocity_smoother_params.sh velocity_smoother    # only velocity smoother
#   ./set_velocity_smoother_params.sh controller_server    # only controller server
#   ./set_velocity_smoother_params.sh --show               # only print current params
#
# Edit the values in the CONFIG sections, then re-run the script.

set -u

# Source the workspace's install/setup.bash: walk up from the script's own
# directory until we find it (no hardcoded paths).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_DIR="$SCRIPT_DIR"
while [[ "$WS_DIR" != "/" && ! -f "$WS_DIR/install/setup.bash" ]]; do
    WS_DIR="$(dirname "$WS_DIR")"
done
if [[ ! -f "$WS_DIR/install/setup.bash" ]]; then
    echo "Error: install/setup.bash not found in any parent directory of $SCRIPT_DIR" >&2
    exit 1
fi
# ROS setup scripts reference unset variables, so relax nounset while sourcing
set +u
# shellcheck disable=SC1091
source "$WS_DIR/install/setup.bash"
set -u

VS_NODE="/velocity_smoother"
CS_NODE="/controller_server"

# ------------------------ CONFIG: velocity_smoother -------------------------
# Array params are [x, y, theta]

VS_BOND_DISABLE_HEARTBEAT_TIMEOUT=true
VS_DEADBAND_VELOCITY="[0.0, 0.0, 0.0]"
VS_FEEDBACK="OPEN_LOOP"
VS_MAX_ACCEL="[1.4, 0.0, 2.5]"
VS_MAX_DECEL="[-10.0, 0.0, -10.0]"
VS_MAX_VELOCITY="[1.0, 0.0, 2.0]"
VS_MIN_VELOCITY="[0.0, 0.0, -2.0]"
VS_ODOM_DURATION=0.1
VS_ODOM_TOPIC="/odometry/filtered"
VS_SCALE_VELOCITIES=true
VS_SMOOTHING_FREQUENCY=20.0
VS_USE_SIM_TIME=false
VS_VELOCITY_TIMEOUT=1.0

# ------------------------ CONFIG: controller_server --------------------------

CS_BOND_DISABLE_HEARTBEAT_TIMEOUT=true
CS_CONTROLLER_FREQUENCY=20.0
CS_FAILURE_TOLERANCE=0.0
CS_MIN_THETA_VELOCITY_THRESHOLD=0.001
CS_MIN_X_VELOCITY_THRESHOLD=0.001
CS_MIN_Y_VELOCITY_THRESHOLD=0.5
CS_ODOM_TOPIC="/odometry/filtered"
CS_PUBLISH_ZERO_VELOCITY=true
CS_SPEED_LIMIT_TOPIC="speed_limit"
CS_USE_SIM_TIME=false

# FollowPath (RegulatedPurePursuitController)
FP_ALLOW_REVERSING=false
FP_APPROACH_VELOCITY_SCALING_DIST=1.0
FP_COST_SCALING_DIST=0.3
FP_COST_SCALING_GAIN=1.0
FP_DESIRED_LINEAR_VEL=0.52
FP_INFLATION_COST_SCALING_FACTOR=3.0
FP_LOOKAHEAD_DIST=0.6
FP_LOOKAHEAD_TIME=1.5
FP_MAX_ALLOWED_TIME_TO_COLLISION_UP_TO_CARROT=1.0
FP_MAX_ANGULAR_ACCEL=3.2
FP_MAX_LOOKAHEAD_DIST=0.9
FP_MAX_ROBOT_POSE_SEARCH_DIST=10.0
FP_MIN_APPROACH_LINEAR_VELOCITY=0.05
FP_MIN_LOOKAHEAD_DIST=0.3
FP_REGULATED_LINEAR_SCALING_MIN_RADIUS=0.9
FP_REGULATED_LINEAR_SCALING_MIN_SPEED=0.25
FP_ROTATE_TO_HEADING_ANGULAR_VEL=1.8
FP_ROTATE_TO_HEADING_MIN_ANGLE=0.785
FP_TRANSFORM_TOLERANCE=0.5
FP_USE_COLLISION_DETECTION=true
FP_USE_COST_REGULATED_LINEAR_VELOCITY_SCALING=false
FP_USE_INTERPOLATION=false
FP_USE_REGULATED_LINEAR_VELOCITY_SCALING=true
FP_USE_ROTATE_TO_HEADING=true
FP_USE_VELOCITY_SCALED_LOOKAHEAD_DIST=false

# goal_checker (SimpleGoalChecker)
GC_STATEFUL=true
GC_XY_GOAL_TOLERANCE=0.25
GC_YAW_GOAL_TOLERANCE=0.25

# progress_checker (SimpleProgressChecker)
PC_MOVEMENT_TIME_ALLOWANCE=10.0
PC_REQUIRED_MOVEMENT_RADIUS=0.5

# NOTE: plugin names/types (controller_plugins, FollowPath.plugin,
# goal_checker_plugins, progress_checker_plugin, ...) are only read at node
# configuration time, so they are intentionally not set here.
# -----------------------------------------------------------------------------

FAILED=0

set_param() {
    local node="$1" name="$2" value="$3"
    printf '%-50s -> %s ... ' "$name" "$value"
    if output=$(ros2 param set "$node" "$name" "$value" 2>&1); then
        echo "OK"
    else
        echo "FAILED"
        echo "    $output"
        FAILED=1
    fi
}

check_node() {
    if ! ros2 node list 2>/dev/null | grep -qx "$1"; then
        echo "Error: node $1 not found. Is Nav2 running?" >&2
        exit 1
    fi
}

apply_velocity_smoother() {
    check_node "$VS_NODE"
    echo "Setting parameters on $VS_NODE ..."
    echo
    set_param "$VS_NODE" "/bond_disable_heartbeat_timeout" "$VS_BOND_DISABLE_HEARTBEAT_TIMEOUT"
    set_param "$VS_NODE" "deadband_velocity"               "$VS_DEADBAND_VELOCITY"
    set_param "$VS_NODE" "feedback"                        "$VS_FEEDBACK"
    set_param "$VS_NODE" "max_accel"                       "$VS_MAX_ACCEL"
    set_param "$VS_NODE" "max_decel"                       "$VS_MAX_DECEL"
    set_param "$VS_NODE" "max_velocity"                    "$VS_MAX_VELOCITY"
    set_param "$VS_NODE" "min_velocity"                    "$VS_MIN_VELOCITY"
    set_param "$VS_NODE" "odom_duration"                   "$VS_ODOM_DURATION"
    set_param "$VS_NODE" "odom_topic"                      "$VS_ODOM_TOPIC"
    set_param "$VS_NODE" "scale_velocities"                "$VS_SCALE_VELOCITIES"
    set_param "$VS_NODE" "smoothing_frequency"             "$VS_SMOOTHING_FREQUENCY"
    set_param "$VS_NODE" "use_sim_time"                    "$VS_USE_SIM_TIME"
    set_param "$VS_NODE" "velocity_timeout"                "$VS_VELOCITY_TIMEOUT"
    echo
}

apply_controller_server() {
    check_node "$CS_NODE"
    echo "Setting parameters on $CS_NODE ..."
    echo
    set_param "$CS_NODE" "/bond_disable_heartbeat_timeout" "$CS_BOND_DISABLE_HEARTBEAT_TIMEOUT"
    set_param "$CS_NODE" "controller_frequency"            "$CS_CONTROLLER_FREQUENCY"
    set_param "$CS_NODE" "failure_tolerance"               "$CS_FAILURE_TOLERANCE"
    set_param "$CS_NODE" "min_theta_velocity_threshold"    "$CS_MIN_THETA_VELOCITY_THRESHOLD"
    set_param "$CS_NODE" "min_x_velocity_threshold"        "$CS_MIN_X_VELOCITY_THRESHOLD"
    set_param "$CS_NODE" "min_y_velocity_threshold"        "$CS_MIN_Y_VELOCITY_THRESHOLD"
    set_param "$CS_NODE" "odom_topic"                      "$CS_ODOM_TOPIC"
    set_param "$CS_NODE" "publish_zero_velocity"           "$CS_PUBLISH_ZERO_VELOCITY"
    set_param "$CS_NODE" "speed_limit_topic"               "$CS_SPEED_LIMIT_TOPIC"
    set_param "$CS_NODE" "use_sim_time"                    "$CS_USE_SIM_TIME"

    set_param "$CS_NODE" "FollowPath.allow_reversing"                              "$FP_ALLOW_REVERSING"
    set_param "$CS_NODE" "FollowPath.approach_velocity_scaling_dist"               "$FP_APPROACH_VELOCITY_SCALING_DIST"
    set_param "$CS_NODE" "FollowPath.cost_scaling_dist"                            "$FP_COST_SCALING_DIST"
    set_param "$CS_NODE" "FollowPath.cost_scaling_gain"                            "$FP_COST_SCALING_GAIN"
    set_param "$CS_NODE" "FollowPath.desired_linear_vel"                           "$FP_DESIRED_LINEAR_VEL"
    set_param "$CS_NODE" "FollowPath.inflation_cost_scaling_factor"                "$FP_INFLATION_COST_SCALING_FACTOR"
    set_param "$CS_NODE" "FollowPath.lookahead_dist"                               "$FP_LOOKAHEAD_DIST"
    set_param "$CS_NODE" "FollowPath.lookahead_time"                               "$FP_LOOKAHEAD_TIME"
    set_param "$CS_NODE" "FollowPath.max_allowed_time_to_collision_up_to_carrot"   "$FP_MAX_ALLOWED_TIME_TO_COLLISION_UP_TO_CARROT"
    set_param "$CS_NODE" "FollowPath.max_angular_accel"                            "$FP_MAX_ANGULAR_ACCEL"
    set_param "$CS_NODE" "FollowPath.max_lookahead_dist"                           "$FP_MAX_LOOKAHEAD_DIST"
    set_param "$CS_NODE" "FollowPath.max_robot_pose_search_dist"                   "$FP_MAX_ROBOT_POSE_SEARCH_DIST"
    set_param "$CS_NODE" "FollowPath.min_approach_linear_velocity"                 "$FP_MIN_APPROACH_LINEAR_VELOCITY"
    set_param "$CS_NODE" "FollowPath.min_lookahead_dist"                           "$FP_MIN_LOOKAHEAD_DIST"
    set_param "$CS_NODE" "FollowPath.regulated_linear_scaling_min_radius"          "$FP_REGULATED_LINEAR_SCALING_MIN_RADIUS"
    set_param "$CS_NODE" "FollowPath.regulated_linear_scaling_min_speed"           "$FP_REGULATED_LINEAR_SCALING_MIN_SPEED"
    set_param "$CS_NODE" "FollowPath.rotate_to_heading_angular_vel"                "$FP_ROTATE_TO_HEADING_ANGULAR_VEL"
    set_param "$CS_NODE" "FollowPath.rotate_to_heading_min_angle"                  "$FP_ROTATE_TO_HEADING_MIN_ANGLE"
    set_param "$CS_NODE" "FollowPath.transform_tolerance"                          "$FP_TRANSFORM_TOLERANCE"
    set_param "$CS_NODE" "FollowPath.use_collision_detection"                      "$FP_USE_COLLISION_DETECTION"
    set_param "$CS_NODE" "FollowPath.use_cost_regulated_linear_velocity_scaling"   "$FP_USE_COST_REGULATED_LINEAR_VELOCITY_SCALING"
    set_param "$CS_NODE" "FollowPath.use_interpolation"                            "$FP_USE_INTERPOLATION"
    set_param "$CS_NODE" "FollowPath.use_regulated_linear_velocity_scaling"        "$FP_USE_REGULATED_LINEAR_VELOCITY_SCALING"
    set_param "$CS_NODE" "FollowPath.use_rotate_to_heading"                        "$FP_USE_ROTATE_TO_HEADING"
    set_param "$CS_NODE" "FollowPath.use_velocity_scaled_lookahead_dist"           "$FP_USE_VELOCITY_SCALED_LOOKAHEAD_DIST"

    set_param "$CS_NODE" "goal_checker.stateful"           "$GC_STATEFUL"
    set_param "$CS_NODE" "goal_checker.xy_goal_tolerance"  "$GC_XY_GOAL_TOLERANCE"
    set_param "$CS_NODE" "goal_checker.yaw_goal_tolerance" "$GC_YAW_GOAL_TOLERANCE"

    set_param "$CS_NODE" "progress_checker.movement_time_allowance"  "$PC_MOVEMENT_TIME_ALLOWANCE"
    set_param "$CS_NODE" "progress_checker.required_movement_radius" "$PC_REQUIRED_MOVEMENT_RADIUS"
    echo
}

TARGET="${1:-all}"

case "$TARGET" in
    --show)
        check_node "$VS_NODE"
        check_node "$CS_NODE"
        ros2 param dump "$VS_NODE"
        ros2 param dump "$CS_NODE"
        exit 0
        ;;
    velocity_smoother)
        apply_velocity_smoother
        ;;
    controller_server)
        apply_controller_server
        ;;
    all)
        apply_velocity_smoother
        apply_controller_server
        ;;
    *)
        echo "Usage: $0 [all|velocity_smoother|controller_server|--show]" >&2
        exit 1
        ;;
esac

if [[ $FAILED -eq 0 ]]; then
    echo "All parameters applied."
else
    echo "Some parameters failed to apply (see above)." >&2
    exit 1
fi
