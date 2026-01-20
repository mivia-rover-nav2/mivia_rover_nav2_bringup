#include <cstdint>
#include <memory>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "geometry_msgs/msg/twist.hpp"
#include "geometry_msgs/msg/twist_stamped.hpp"

namespace
{
enum class AdapterMode : std::uint8_t
{
  kTwistToStamped = 0U,
  kStampedToTwist = 1U
};

AdapterMode parse_mode(const std::string & mode_str)
{
  if (mode_str == "twist_to_stamped")
  {
    return AdapterMode::kTwistToStamped;
  }
  if (mode_str == "stamped_to_twist")
  {
    return AdapterMode::kStampedToTwist;
  }

  // Defensive default (keeps node operational)
  return AdapterMode::kTwistToStamped;
}
}  // namespace

class TwistAdapterNode final : public rclcpp::Node
{
public:
  explicit TwistAdapterNode(const rclcpp::NodeOptions & options)
  : rclcpp::Node("twist_adapter", options),
    mode_(AdapterMode::kTwistToStamped),
    stamp_with_now_(true)
  {
    const std::string mode_str =
      this->declare_parameter<std::string>("mode", "twist_to_stamped");

    input_topic_ =
      this->declare_parameter<std::string>("input_topic", "/cmd_vel");
    output_topic_ =
      this->declare_parameter<std::string>("output_topic", "/cmd_vel_stamped");

    frame_id_ =
      this->declare_parameter<std::string>("frame_id", "");
    stamp_with_now_ =
      this->declare_parameter<bool>("stamp_with_now", true);

    mode_ = parse_mode(mode_str);

    // cmd_vel QoS: typically best effort, keep last
    const rclcpp::QoS qos = rclcpp::QoS(rclcpp::KeepLast(1)).best_effort();

    if (mode_ == AdapterMode::kTwistToStamped)
    {
      pub_stamped_ = this->create_publisher<geometry_msgs::msg::TwistStamped>(output_topic_, qos);

      sub_twist_ = this->create_subscription<geometry_msgs::msg::Twist>(
        input_topic_,
        qos,
        std::bind(&TwistAdapterNode::on_twist, this, std::placeholders::_1));

      RCLCPP_INFO(
        this->get_logger(),
        "TwistAdapter (mode=twist_to_stamped): '%s' -> '%s' (frame_id='%s', stamp_with_now=%s)",
        input_topic_.c_str(),
        output_topic_.c_str(),
        frame_id_.c_str(),
        stamp_with_now_ ? "true" : "false");
    }
    else
    {
      pub_twist_ = this->create_publisher<geometry_msgs::msg::Twist>(output_topic_, qos);

      sub_stamped_ = this->create_subscription<geometry_msgs::msg::TwistStamped>(
        input_topic_,
        qos,
        std::bind(&TwistAdapterNode::on_stamped, this, std::placeholders::_1));

      RCLCPP_INFO(
        this->get_logger(),
        "TwistAdapter (mode=stamped_to_twist): '%s' -> '%s'",
        input_topic_.c_str(),
        output_topic_.c_str());
    }
  }

private:
  void on_twist(const geometry_msgs::msg::Twist::SharedPtr msg)
  {
    geometry_msgs::msg::TwistStamped out;

    if (stamp_with_now_)
    {
      out.header.stamp = this->now();
    }
    else
    {
      // Leave stamp at zero time if user explicitly requests it.
      out.header.stamp = rclcpp::Time(0, 0, this->get_clock()->get_clock_type());
    }

    out.header.frame_id = frame_id_;
    out.twist = *msg;

    pub_stamped_->publish(out);
  }

  void on_stamped(const geometry_msgs::msg::TwistStamped::SharedPtr msg)
  {
    // Forward only the twist content; header is discarded by design.
    pub_twist_->publish(msg->twist);
  }

  AdapterMode mode_;

  std::string input_topic_;
  std::string output_topic_;
  std::string frame_id_;
  bool stamp_with_now_;

  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr sub_twist_;
  rclcpp::Subscription<geometry_msgs::msg::TwistStamped>::SharedPtr sub_stamped_;

  rclcpp::Publisher<geometry_msgs::msg::TwistStamped>::SharedPtr pub_stamped_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr pub_twist_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<TwistAdapterNode>(rclcpp::NodeOptions()));
  rclcpp::shutdown();
  return 0;
}