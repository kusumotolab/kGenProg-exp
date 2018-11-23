# 基本

### 使い方

永続データ用のディレクトリ作成（10Gくらい使うので注意）
```shell
$ sudo mkdir -p /opt/apr-data
```

クローン
```shell
$ git clone git@github.com:kusumotolab/kGenProg-exp.git kgp-exp
$ cd kgp-exp
```

docker起動
```shell
$ bash run.sh apr
```

docker上でビルド
```shell
root@360a1f066293:~# source util.sh;
root@360a1f066293:~# build kgp
root@360a1f066293:~# build astor
root@360a1f066293:~# build d4j
root@360a1f066293:~# checkout math $(seq 1 106)
```

各種APR実行
```shell
root@360a1f066293:~# run kgp math 85 kgp 1
root@360a1f066293:~# run kgp math 73 astor 1
```


----
# aws

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
```shell
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
echo 'export APR=astor'  >> ~/.bashrc
echo 'export SEED=1' >> ~/.bashrc
echo 'PS1="\e[37m\e[41m[aws $APR-$SEED]\e[0m\]$ "' >> ~/.bashrc
source ~/.bashrc
```

tmuxの設定
```shell
echo 'set -g prefix C-u' > ~/.tmux.conf
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
# source util.sh ;
# build kgp; build astor; build d4j; checkout math $(seq 1 104);
```

実験実行
```shell
# source util.sh ;
# for i in {1..104}; do run math $i; done
```


### 細かいメモ

awsインスタンスのip
```shell
genp=(
    13.230.213.7
    13.230.160.85
    18.179.207.88
    13.231.119.253
    13.231.97.56
    13.231.157.145
    54.238.109.252
    54.178.17.35
    13.114.16.117
    13.115.43.0
    )
kgp=(
    52.194.236.208
    54.238.203.4
    13.112.136.252
    18.182.39.76
    13.115.253.105
    54.249.63.120
    52.68.33.92
    52.194.236.124
    54.64.0.228
    54.199.204.111
    )
```


実験結果の取り出し
```shell
$ /d/apr-exp/out/
$ for m in ${genp[@]}; do scp -i ~/.ssh/apr.pem ec2-user@$m:/opt/apr-data/out/* out; done
$ for m in ${kgp[@]};  do scp -i ~/.ssh/apr.pem ec2-user@$m:/opt/apr-data/out/* out; done
```


javaプロセスkill
```shell
ps -aux | grep java | grep apr-data | awk '{print $2}' | xargs sudo kill
```

全VMのapr実行をkill
```shell
for m in ${genp[@]}; do ssh -i ~/.ssh/apr.pem ec2-user@$m 'ps aux | grep java | grep apr-data | awk '\''{print $2}'\'' | xargs sudo kill ' ; done
```

docker kill all
```shell
docker kill $(docker ps -q)
```

前の実験結果クリア
```shell
sudo rm -rf /opt/apr-data/out/
```

(find /opt/apr-data/out/ -type f | sort | while read line
do
  printf "$(basename $line) "
  cat $line | grep '^real'
done
) | tee /tmp/x
