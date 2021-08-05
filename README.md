README
=========

VCI書き換え実験用スクリプト。詳しくは下記を参照。

- [デモサイト](https://vci-slide-generator-dnb6froqha-uc.a.run.app/)
- [バーチャルキャストのVCIをRubyで解析してみた](https://zenn.dev/koduki/articles/7596fadeaff328)
- [UnityなしでVCIの作成にチャレンジ!](https://zenn.dev/koduki/articles/d4332883491f7a)

## Run
```bash
docker run -it -v $(pwd):/app -p 5000:5000 koduki/vci-slide-generator
```

## CLI for debug

```
DESCRIPTION
     - VCI generator utilities for debug

SYNOPSIS
    cli COMMAND SUBCOMMAND

COMMANDS
    + export
        - json: export meta data from VCI. e.g) ./cli export json test001.vci
        - image: export slide image from VCI. e.g) ./cli export image test001.vci "Slide-all" test001.png
    + generate
        - pdf: generate generate sample PDF for test e.g) ./cli generate pdf testslide 25
```