# wasm

[入門 WebAssembly](https://www.shoeisha.co.jp/book/detail/9784798173597)の勉強会　簡単メモ

## ex1

wasm を使う主な目的：高速化、セキュアネス、移植性
WASI(WebAssembly System Interface):WASM モジュールが、OS の機能にアクセスできるようにするための API を提供

WAT : wasm の仮想マシンのアセンブリ言語のようなもの。wasm バイナリのテキスト表現
WAT の書き方：線形命令リスト、S 式

## ex2

ページ：線形メモリに一度に割り当てられるメモリブロックの最小単位。wasm のページサイズは 64KB
