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
sudo mkfs -t ext4 /dev/nvme0n1
sudo mkdir /opt/apr-data


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

dockerの設定
```shell
mkdir -p ~/.docker
echo '{"detachKeys": "ctrl-q"}' > ~/.docker/config.json
```


aprの実験準備
```shell
git clone https://github.com/kusumotolab/kGenProg-exp apr-exp
cd apr-exp
./run.sh
```

docker上で準備
```shell
root@98d6c76f51a5:~# source util.sh ; build kgp; build astor; build d4j; checkout math $(seq 1 104);
```

実験実行
```shell
root@98d6c76f51a5:~# source util.sh ; for i in {1..104}; do run astor math $i; done

```

ssh ec2-user@54.250.186.120 -i apr.pem
ssh ec2-user@13.230.253.238 -i apr.pem
