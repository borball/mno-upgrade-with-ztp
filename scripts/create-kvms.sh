ssh 192.168.58.14 kcli stop vm mno-master0 mno-master1 mno-master2 mno-worker0 mno-worker1 mno-worker2
ssh 192.168.58.14 kcli delete vm mno-master0 mno-master1 mno-master2 mno-worker0 mno-worker1 mno-worker2 -y
ssh 192.168.58.14 'kcli create vm -P uuid=11111111-0000-0000-0000-000000000080 -P start=False -P memory=20480 -P numcpus=16 -P disks=[122] -P nets=["{\"name\":\"br-vlan58\",\"nic\":\"eth0\",\"mac\":\"de:ad:be:ee:20:00\"}"] mno-master0'
ssh 192.168.58.14 'kcli create vm -P uuid=11111111-0000-0000-0000-000000000081 -P start=False -P memory=20480 -P numcpus=16 -P disks=[122] -P nets=["{\"name\":\"br-vlan58\",\"nic\":\"eth0\",\"mac\":\"de:ad:be:ee:20:01\"}"] mno-master1'
ssh 192.168.58.14 'kcli create vm -P uuid=11111111-0000-0000-0000-000000000082 -P start=False -P memory=20480 -P numcpus=16 -P disks=[122] -P nets=["{\"name\":\"br-vlan58\",\"nic\":\"eth0\",\"mac\":\"de:ad:be:ee:20:02\"}"] mno-master2'
ssh 192.168.58.14 'kcli create vm -P uuid=11111111-0000-0000-0000-000000000083 -P start=False -P memory=30702 -P numcpus=16 -P disks=[122,150] -P nets=["{\"name\":\"br-vlan58\",\"nic\":\"eth0\",\"mac\":\"de:ad:be:ee:20:03\"}"] mno-worker0'
ssh 192.168.58.14 'kcli create vm -P uuid=11111111-0000-0000-0000-000000000084 -P start=False -P memory=30702 -P numcpus=16 -P disks=[122,150] -P nets=["{\"name\":\"br-vlan58\",\"nic\":\"eth0\",\"mac\":\"de:ad:be:ee:20:04\"}"] mno-worker1'
ssh 192.168.58.14 'kcli create vm -P uuid=11111111-0000-0000-0000-000000000085 -P start=False -P memory=30702 -P numcpus=16 -P disks=[122,150] -P nets=["{\"name\":\"br-vlan58\",\"nic\":\"eth0\",\"mac\":\"de:ad:be:ee:20:05\"}"] mno-worker2'

ssh 192.168.58.14 kcli list vm
systemctl restart sushy-tools.service