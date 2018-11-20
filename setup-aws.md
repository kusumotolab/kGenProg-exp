ベース作成
```shell
sudo yum update -y
sudo yum install -y git
sudo yum install -y tmux
sudo amazon-linux-extras install docker -y
sudo service docker start
```

パーミッション
```shell
sudo usermod -a -G docker ec2-user
exit
```

再ログイン
```
ssh ec2-user@...
```


aprの実験準備
```shell
git clone https://github.com/kusumotolab/kGenProg-exp apr-exp
cd apr-exp
sudo mkdir /opt/apr-data
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