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


スクリーンショット
==================

本モジュールをEmacsで利用した場合のスクリーンショットです。

![demo1](image/demo1.png)


デモ
====

本モジュールをEmacsで利用した場合に可能になる、コーディングのデモです。

http://www.youtube.com/watch?v=Q8XDhxqmaXs

Emacsでの利用に関して、詳しくは以下を参照して下さい。

https://github.com/aki2o/emacs-plsense/blob/master/README-ja.md


インストール
============

### CPANからインストール

2013/07/24  CPANにアップロードするための申請中ですが、一向に申請が通る気配がありません。

### cpanmでインストール

    # git clone https://github.com/aki2o/plsense.git
    # cd plsense
    # cpanm PlSense-?.??.tar.gz

### 手動でインストール

    # git clone https://github.com/aki2o/plsense.git
    # cd plsense
    # perl Makefile.PL
    # make
    # make manifest
    # make test
    # make instal

手動の場合、依存モジュールがインストールされていないとエラーになると思います。  
都度、インストールして頂くか、Makefile.PLを参照して下さい。

### インストール確認

本モジュールのインストールにより、plsenseコマンドが提供されます。  
ターミナルから`plsense -v`を実行してみて下さい。  
本モジュールのバージョン情報が表示されるはずです。


設定
====

### 全般

本モジュールには、全般的な動作を決定する以下の設定項目があります。

* cachedir ... ソースコードの解析結果を保存するディレクトリパス
* maxtasks ... 同時実行するタスクの最大数
* port1, port2, port3 ... サーバプロセスが待ち受けるポート番号
* logfile ... ログ出力先ファイル
* loglevel ... ログ出力レベル

※ cachedirに保存する情報は継続して利用可能なので、/tmpなどの一時領域でない方が良いです。  
※ 頻繁にI/Oが発生するので、cachedirに指定するパスは高速なデバイスの方が良いです。  
※ cachedirに必要な容量、maxtasksの指定数に関しては、消費リソースを参照して下さい。  
※ 本モジュールはサーバ/クライアントモデルで動作し、サーバプロセスが3つ実行されます。  
※ ログファイルが未指定の場合、ログ出力しません。  
※ ログ出力には Log::Handler を利用しています。指定できるログレベル名については、 Log::Handler のヘルプを参照して下さい。  

#### 設定ファイル

上記の設定項目は`plsense --cachedir=...`のようにコマンドライン指定できます。  
また、ユーザのホームディレクトリに .plsense というファイルで設定を記述することで、コマンドライン指定を省略できます。

    # cat ~/.plsense
    cachedir=/home/user1/.plsense.d
    logfile=/tmp/plsense.log
    loglevel=info
    maxtasks=20
    port1=33333
    port2=33334
    port3=33335

※ 上記ファイルは、事前に作成しなくても、plsenseコマンド実行時に作成できます。  
※ コマンドライン引数の指定は、上記ファイルの記述より優先されます。  

### プロジェクト固有

プロジェクト固有のライブラリがある場合など、複数ファイルを相互に参照するケースでは、
プロジェクトツリーのルートに .plsense というファイルでプロジェクト情報を記述する必要があります。

    # cat /var/dev/sample/.plsense 
    name=SampleProj
    lib-path=lib

* name ... プロジェクト名。[a-zA-Z0-9_]+
* lib-path ... プロジェクト固有ライブラリへの相対パス。上記の場合、 /var/dev/sample/lib になる。


消費リソース
============

解析したモジュール数や、そのモジュールのサイズによって大分変わりますが、一応の目安を示します。

約200のモジュールを解析した場合、

* cachedirに保存される容量は、約20MB
* サーバプロセスが常時使用するメモリが、合計で約100MB

その他に、不定期にサーバプロセスから起動される、ライブラリ検索やソース解析のタスクのプロセスが
消費するメモリが平均25MBです。

maxtasksは、そのタスクの最大同時実行数なので、お使いのマシンの搭載メモリに合わせて、適宜設定して下さい。  
デフォルトは20です。つまり、上記の場合、一時的に最大600MB程消費することになります。

また、モジュールの解析は、再帰的に行われます。  
例えば、対象のソースコードがuse/requireしているモジュール数が少なくても、
そのモジュールが大量のuse/requireをしていた場合は、解析するモジュール数は多くなります。


所要時間
========

補完/ヘルプ情報の提供は、即座に可能ですが、その結果が最適化されるためには、
未解析の全てのモジュールを解析する必要があり、その完了までにはある程度の時間が必要です。

これも、対象のソースコードから参照される未解析の総モジュール数に依存しますが、一応の目安として、

約200のモジュールをmaxtasksが20の設定で解析した場合、完了までに約15分が必要でした。


解析における制限事項
====================

### リテラル

解析処理は、大雑把に言えば、代入式とreturn式の収集です。

```perl
sub hoge () {
    my $hoge = shift;  # 代入式
    return $hoge;      # return式
}
```

それらに渡される値によって、変数やメソッド戻り値などの型を特定していきますが、
型の特定において最も優先されるのが、リテラル式です。

    my $hoge = "hoge";                # SCALAR
    my @hoge = ("ho", "ge");          # ARRAY
    my %hoge = ( name => "hoge", );   # HASH
    my $hoge = [ "ho", "ge" ];        # REFERENCE of ARRAY
    my $hoge = { name => "hoge", };   # REFERENCE of HASH

以下のように、解決された型が複数あると、正常に判別できる保障がなくなります。

    my $hoge = [ "hoge" ];
    my $fuga = {};
    if ( $hoge ) { $fuga = $hoge; }  # 複数の型が代入されているので、$fugaが正常に特定できない

### bless

newという名称のメソッドは、自動的に戻り値がその所属するクラスのインスタンスになります。  
その他のメソッドで、blessされたリファレンスを返しても、それが正常に判別される保障はありません。

    package Hoge;
    sub new { return; }                                                           # 戻り値は無条件にHogeになる
    sub get_instance { Fuga->new(); }                                             # 判別可能
    sub get_instance { my $cls = shift; my $r = {}; bless $r, $cls; return $r; }  # 保障できない

つまり、自身のインスタンスを返すメソッドはnewじゃないとだめで、  
ファクトリー的なクラスは、それが生成するインスタンスを確実に判別できる保障はありません。

### 配列

配列の場合、要素番号は無視し、要素は全て同じ型であると判断します。

    $hoge[0] = Hoge->new();
    $hoge[1] = \%fuga;
    $hoge[0]->    # Hogeのメソッドは補完されない

### ハッシュ

ハッシュの場合、キーがリテラルかつ、'[a-zA-Z0-9_\-]+'にマッチした時のみ、その値の判別が可能です。

    $hoge{hoge} = Hoge->new();
    $hoge{"fuga"} = \%fuga;
    my ($foo, $bar) = ("foo", "bar");
    $hoge{$foo} = Foo->new();
    $hoge{$bar} = Bar->new(); # 区別できないキーの値は全てBarのインスタンスであると判断する
    
    $hoge{hoge}->      # Hogeのメソッドが補完できる
    $hoge{'fuga'}->{   # %fugaのキーが補完できる
    $hoge{$foo}->      # Fooのメソッドは補完されない

### 変数のスコープ

変数を区別できるのは、subの中までです。

    package Hoge;
    my $some = Fuga->new();

    sub get_hoge {
        my $some = Foo->new();
        foreach my $e ( "foo", "bar" ) {
            my $some = $e;
        }
        $some->  # もはやFooでない
    }

    $some->   # Fugaのメソッドが補完される

### 2項演算子

    my $hoge = Hoge->new() || Fuga->new(); # Hogeのインスタンスとみなされる
    my $fuga = Hoge->new() && Fuga->new(); # Fugaのインスタンスとみなされる

### 3項演算子

一番最初の要素を採用します。

    my $some = $hoge ? Hoge->new()
             : $fuga ? Fuga->new()
             :         Bar->new();
    $some->  # Hogeのインスタンスとみなされる

### リテラルへの変数/メソッド埋め込み

配列、ハッシュのキーの値のみ判別可能です。

    my @hoge = ( @fuga, @bar );         # @fuga/@barの要素が判別できれば、@hogeの要素も判別できる
    my %hoge = ( fuga => get_fuga() );  # get_fuga()が判別できれば、$hoge{fuga}も判別できる
    my $hoge = { %fuga };               # 判別できない
    my $hoge = [ @fuga, @bar ];         # 判別できない

### メソッドの呼び出し方法

    my $hoge = new Hoge;   # 前置呼び出しは判別できない
    my $hoge = Hoge->new;  # これはOK

    my $hoge = myfunc $fuga;  # $fugaはmyfuncの引数とはみなされない
    my $hoge = myfunc($fuga); # $fugaはmyfuncの引数とみなされる

    my $hoge = shift @fuga; # 組込み関数の場合は、括弧がなくてもOK

対応していない組込み関数は、引数も戻り値も判別できません。  
現在対応しているのは、以下です。

* bless
* eval (BLOCKの引数の場合のみ)
* grep
* first
* pop
* push
* reverse
* shift
* sort
* undef
* unshift
* values

また、外部モジュールの関数で対応しているものには以下があります。

* List::Util::first, List::AllUtils::first
* List::MoreUtils::uniq, List::AllUtils::uniq

ここでいう、対応とは、通常の解析処理以外に、
関数が受け取る引数の判別や、戻す値に関する処理が実装されていることを示します。  
詳しくは、拡張性を参照して下さい。

### メソッドの引数

メソッドの引数は、通常、そのメソッド呼び出しの記述が見つかるまで、判別できません。

    sub hoge {
        my $hoge = shift;
        $hoge->  # 型は不明
    }

    hoge( Hoge->new() );  # この記述が見つかれば、上記の$hogeの型も判明する

ただし、そのクラスがnewメソッドを持つ場合には、そのクラスのメソッドの第一引数は自身のインスタンスと判断します。

    package Hoge;

    sub new { my $r = {}; bless $r; return $r; }

    sub hoge {
        my $hoge = shift;
        my $fuga = shift;
        $hoge->  # 無条件でHogeのインスタンスだと判断する
    }

その場合、メソッド呼び出しで渡される引数は順番がずれます。

    package main;
    use Hoge;
    Hoge->hoge( $arg );  # 上記の$fugaは$argであると判断する

本来なら、アロー演算子の前置部分が引数となるのでしょうが、本モジュールでは影響しません。

### モジュールが提供する記述

本モジュールの解析は、Perlがデフォルトで提供している記述に基づき実施され、
それ以外の記述の意味は判断できません。  
つまり、外部モジュールが提供する特別な記述による効果を反映できません。

例えば、Mooseを使い、以下のように記述しても、

    package Hoge;
    use Moose;
    has 'fuga' => ( is => 'rw', isa => 'Fuga' );

    package main;
    my $hoge = Hoge->new();
    $hoge->fuga->  # Fugaのインスタンスである

とは、判断できません。

ただし、以下のモジュールについては、そのモジュールが提供する記述方式を認識することができます。

* Class::Std

通常の解析処理の他に、上記モジュールのために、その記述を解析する処理が実装されています。
詳しくは、拡張性を参照して下さい。


拡張性
======

上記制限事項で述べたとおり、解析できないソースコードもあります。  
本モジュールでは、Module::Pluggableを利用しており、いくつかの拡張ポイントがあります。  
もじ、あなたに上記制限に対するアイデアがあれば、プラグインを作成することで、
本モジュールの解析/補完における機能を追加することができます。  
詳しくは、以下を参照して下さい。

https://github.com/aki2o/plsense/blob/master/DevelopmentGuide-ja.md


使い方
======

本モジュールのインストールにより、提供されるplsenseコマンドを通して、サーバとやり取りします。  
plsenseコマンドが備えているサブコマンドについて、以下に記します。  

本モジュールは、EmacsやVimなどの高機能エディタから利用されることを前提に設計しているため、
エンドユーザが通常意識する必要はありません。

plsenseコマンドには、都度実行を完了する方法と、対話的に実行する方法があります。

    # plsense help assist
    Do assist for given Code.

    Assist is a optimized completion.
    ...

    # plsense -i
    > help assist
    Do assist for given Code.
    
    Assist is a optimized completion.
    ...
    
    > exit
    # 

### help コマンド名

サブコマンドのヘルプを表示します。

### svstart/serverstart

サーバプロセスを開始します。

### svstop/serverstop

サーバプロセスを停止します。

### svstat/serverstatus

サーバプロセスの状態を表示します。

### refresh

起動中に蓄積された不要なキャッシュなどを消去し、サーバプロセスをリフレッシュします。

### o/open モジュール名/ファイルパス

指定されたモジュール/ファイルが未解析の場合、解析を開始します。  
解析は未解析のモジュールに対して、再帰的に実施されます。

### u/update モジュール名/ファイルパス

指定されたモジュール/ファイルが解析済みでも、解析を開始します。  
解析は未解析のモジュールに対して、再帰的に実施されます。

### remove モジュール名/ファイルパス

指定されたモジュール/ファイルの解析結果を削除します。

### removeall

全ての解析結果を削除します。

### ready モジュール名/ファイルパス

指定されたモジュール/ファイルが解析済みであるかどうかを表示します。  
引数が指定されない場合、解析済みのモジュールを表示します。

### ps

サーバプロセスから起動され、実行中のタスクプロセスを表示します。

### queue

サーバプロセス上の実行待ちのタスクを表示します。

### mhelp/modhelp モジュール名

モジュールのヘルプを表示します。

### fhelp/subhelp メソッド名 モジュール名

メソッドのヘルプを表示します。モジュールに属す場合は、モジュール名が必要です。

### vhelp/varhelp 変数名 モジュール名

変数のヘルプを表示します。モジュールに属す場合は、モジュール名が必要です。

### chelp/codehelp Perlコード

与えられたコードから特定されるコンテキストについてのヘルプを表示します。

### ahelp/assisthelp 候補

最後に実行したassistの結果の補完候補についてのヘルプを表示します。

### a/assist Perlコード

与えられたコードに続くことが可能な候補を表示します。

### subinfo Perlコード

与えられたコードから特定されるメソッドについての情報を表示します。

### onfile ファイルパス

ファイルパスを現在のロケーションに設定します。

### onmod モジュール名

モジュールを現在のロケーションに設定します。

### onsub メソッド名

メソッドを現在のロケーションに設定します。

### loc/location

現在のロケーションを表示します。  
ロケーションは、Perlコードを与えるコマンドにおいて、その実行結果に影響します。

### c/codeadd Perlコード

与えられたコードを現在のロケーションに追加します。  
解析の再実行は、ファイルが更新された場合に必要になりますが、そのコストは軽くないため、
ファイルを保存するまでのコード変更による解析結果の変動をリアルタイムに取り込むためのコマンドです。

### config

設定ファイルを更新します。

### debugmod モジュール名/ファイルパス

モジュール/ファイルに関する解析結果を表示します。

### debugsubst 正規表現

解析で得られた代入情報の内、正規表現にマッチするものを表示します。

### debugrt 正規表現

解析で得られたルーティングの内、正規表現にマッチするものを表示します。  
ルーティングについては、以下を参照して下さい。

https://github.com/aki2o/plsense/blob/master/DevelopmentGuide-ja.md

### debuglex Perlコード

与えられたコードから得られるPPIドキュメントを表示します。  
PPIドキュメントについては、以下を参照して下さい。

https://github.com/aki2o/plsense/blob/master/DevelopmentGuide-ja.md


動作確認
========

* WindowsXP Pro SP3 32bit
* Cygwin 1.7.20-1
* Perl 5.14.2


**Enjoy!!!**

