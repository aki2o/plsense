これは何？
==========

Perlソースコードのコンテキストに合った補完/ヘルプ情報を提供するPerlモジュールです。  
EmacsやVimなどの高機能エディタから利用されることを前提に設計しています。


特徴
====

### 補完/ヘルプ/メソッド情報の表示

指定されたソースコードのコンテキストを特定し、適切な補完/ヘルプ/メソッド情報を表示します。

### 特定可能なコンテキスト

* 変数
* インスタンスメソッド
* クラスのイニシャライザ
* use/requireモジュール
* use/requireするモジュールに渡すLIST要素
* ハッシュキー


デモ
====

本モジュールをEmacsで利用した場合に可能になる、コーディングのデモです。

http://www.youtube.com/watch?v=Q8XDhxqmaXs

詳しくは、以下を参照して下さい。

https://github.com/aki2o/emacs-plsense/blob/master/README-ja.md


インストール
============


### CPANからインストール

2013/07/24  CPANにアップロードするための申請中ですが、一向に申請が通る気配がありません。

### cpanmでインストール

cpanmが利用できるなら、上記ソース置き場からzipを取得、解凍し、PlSense-X.XX.tar.gzを指定。

### 手動でインストール

    # git clone https://github.com/aki2o/plsense.git
    # cd plsense
    # perl Makefile.PL
    # make
    # make manifest
    # make test
    # make instal


設定
====

### 全般



### プロジェクト固有

