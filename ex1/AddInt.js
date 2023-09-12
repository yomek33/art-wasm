const fs = require("fs"); // fsモジュール(ローカルストレージからファイルを読みこむ)

const bytes = fs.readFileSync(__dirname + "/AddInt.wasm");
const value_1 = parseInt(process.argv[2]);
const value_2 = parseInt(process.argv[3]);
//console.log(process.argv[0]); -> /usr/local/bin/node
//console.log(process.argv[1]); -> /Users/name/learning/wasm/ex1/AddInt.js

//非同期IIFE(Immediatly Invoked Function Expression：即時実行関数式)でwasmモジュールをインスタンス化、wasm関数呼び出し
(async () => {
  const obj = await WebAssembly.instantiate(new Uint8Array(bytes));
  let add_value = obj.instance.exports.AddInt(value_1, value_2);
  console.log(`${value_1} + ${value_2} = ${add_value}`);
})();
