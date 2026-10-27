#!/bin/bash
# private 서버에서 인터넷으로 나가 보고(NAT 경유), 밖에서 보인 IP를 콘솔 로그에 남깁니다.
# 확인: aws ec2 get-console-output --instance-id <ID> --latest --output text | grep TF4D
for i in $(seq 1 30); do
  IP=$(curl -s -m 5 https://checkip.amazonaws.com) && [ -n "$IP" ] && break
  sleep 10
done
echo "TF4D-NAT-CHECK egress_ip=${IP:-FAIL}" | tee /dev/console
