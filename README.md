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
root@360a1f066293:~# build kgp
root@360a1f066293:~# build astor
root@360a1f066293:~# build d4j
root@360a1f066293:~# checkout math 1 106
```

各種APR実行
```shell
root@360a1f066293:~# run kgp math 85
root@360a1f066293:~# run kgp math 73
```
