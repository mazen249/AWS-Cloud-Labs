import json
import os
import boto3

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):
    detail = event.get("detail", {})
    event_name = detail.get("eventName")

    # نتعامل فقط مع حدث إضافة قواعد دخول
    if event_name != "AuthorizeSecurityGroupIngress":
        return {"status": "ignored", "reason": "Not an ingress authorization event"}

    request_parameters = detail.get("requestParameters", {})
    group_id = request_parameters.get("groupId")

    if not group_id:
        print("Could not find Security Group ID in event")
        return {"status": "ignored", "reason": "Missing Security Group ID"}

    # نقرأ القواعد الحالية من EC2
    response = ec2.describe_security_groups(GroupIds=[group_id])
    security_groups = response.get("SecurityGroups", [])

    removed_rules = []

    for security_group in security_groups:
        for permission in security_group.get("IpPermissions", []):
            protocol = permission.get("IpProtocol")
            from_port = permission.get("FromPort")
            to_port = permission.get("ToPort")

            # نبحث عن TCP port 22 المفتوح إلى IPv4 من أي مكان
            is_ssh = (
                protocol == "tcp"
                and from_port == 22
                and to_port == 22
            )

            has_open_ipv4 = any(
                ip_range.get("CidrIp") == "0.0.0.0/0"
                for ip_range in permission.get("IpRanges", [])
            )

            if is_ssh and has_open_ipv4:
                # نمرر الإذن المطابق كما أعاده EC2 لإلغاء هذه القاعدة فقط
                ec2.revoke_security_group_ingress(
                    GroupId=group_id,
                    IpPermissions=[permission]
                )
                removed_rules.append(permission)

    if removed_rules:
        message = (
            f"Auto-remediation removed public SSH ingress from Security Group "
            f"{group_id}. Removed rules: {json.dumps(removed_rules, default=str)}"
        )

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="AWS Security Group Auto-Remediation",
            Message=message
        )

        return {
            "status": "remediated",
            "group_id": group_id,
            "removed_rules": len(removed_rules)
        }

    return {
        "status": "no_action",
        "group_id": group_id,
        "reason": "No public SSH rule found"
    }