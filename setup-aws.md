ベース作成
```shell
sudo yum update -y
sudo yum install -y git
sudo yum install -y tmux
sudo amazon-linux-extras install docker -y
sudo service docker start
```

NVMeストレージのマウント
```shell
sudo mkfs -t ext4 /dev/nvme1n1
sudo mkdir /opt/apr-data
sudo mount /dev/nvme1n1 /opt/apr-data
```


dockerのパーミッション
```shell
sudo usermod -a -G docker ec2-user
exit
```

再ログイン
```
ssh ec2-user@...
```

astorのためのタイムゾーン設定
```shell
sudo timedatectl set-timezone Asia/Tokyo
```

dockerの設定
```shell
mkdir -p ~/.docker
echo '{"detachKeys": "ctrl-q"}' > ~/.docker/config.json
```

マシン固有の実験設定
```shell
echo 'export APR=kgp'  >> ~/.bashrc
echo 'export SEED=1' >> ~/.bashrc
echo 'PS1="\e[37m\e[41m[aws $APR-$SEED]\e[0m\]$ "' >> ~/.bashrc
```

tmuxの設定
```shell
echo 'set -g prefix C-j' > ~/.tmux.conf
```

aprの実験準備
```shell
git clone https://github.com/kusumotolab/kGenProg-exp apr-exp
cd apr-exp
tmux
./run.sh
```

docker上で準備
```shell
# source util.sh ; build kgp; build astor; build d4j; checkout math $(seq 1 104);
```

実験実行
```shell
# source util.sh ; for i in {1..104}; do run math $1 astor 1; done

```


### 細かいコマンド
astor
ssh ec2-user@54.250.186.120 -i apr.pem
ssh ec2-user@13.230.253.238 -i apr.pem

kgp
ssh ec2-user@52.193.6.47    -i apr.pem
ssh ec2-user@13.113.253.73  -i apr.pem

astor-1=13.230.160.85
astor-2=18.179.207.88
astor-3=13.231.119.253
astor-4=13.231.97.56
astor-5=13.231.157.145
astor-6=54.238.109.252
astor-7=54.178.17.35
astor-8=13.114.16.117
astor-9=13.115.43.0
astor-10=13.230.213.7


ps -aux | grep java | grep apr-data | awk '{print $2}' | xargs sudo kill


(find /opt/apr-data/out/ -type f | sort | while read line
do
  printf "$(basename $line) "
  cat $line | grep '^real'
done
) | tee /tmp/x
