README
=========

VCI書き換え実験用スクリプト。詳しくは下記を参照。

- [【Vキャス用】UnityなしでWebからVRスライドが作れるVCIスライドジェネレータを作ってみた](https://koduki.hatenablog.com/entry/2021/02/16/074554)
- [VCI Slide Generator デモ用](https://vci-slide-generator-dnb6froqha-uc.a.run.app/)
- [【技術解説】バーチャルキャストのVCIをRubyで解析してみた](https://zenn.dev/koduki/articles/7596fadeaff328)
- [【技術解説】UnityなしでVCIの作成にチャレンジ!](https://zenn.dev/koduki/articles/d4332883491f7a)


## VCIの解析 (JSON部とバイナリ部に分割)

```bash
$ ruby ./sample/export.rb dist/output.vci output
MAGIC: glTF, VERSION: 2, LENGTH: 4020076
CHUNK0_LENGTH: 5544, CHUNK_TYPE: JSON
CHUNK1_LENGTH: 4014504, CHUNK_TYPE: BIN
$ ls -l output.json output.data
-rw-r--r-- 1 koduki koduki 4014504 Feb 15 14:52 output.data
-rw-r--r-- 1 koduki koduki    5544 Feb 15 14:52 output.json
```

## ローカルで起動

```bash
$ docker run -it -p 5000:5000 -v `pwd`:/app koduki/vci-slide-generator
```

## デプロイ

```bash
$ gcloud builds submit
```