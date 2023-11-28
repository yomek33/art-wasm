const colors = require("colors"); //colorsモジュールの読み込み
const fs = require("fs");
const bytes = fs.readFileSync(__dirname + "/store_data.wasm");

const memory = new WebAssembly.Memory({ initial: 1 }); //WebAssembly.Memoryオブジェクトの作成。64kのメモリブロックを確保
const mem_i32 = new Uint32Array(memory.buffer); //メモリの内容をUint32Arrayで取得. memoryのオブジェクトの内容にアクセスできるビューを作成
const data_addr = 32; //バイト単位のインデックス
const data_i32_index = data_addr / 4; //開始データインデックス 8
const data_count = 16; //設定する32ビット整数の数

//wasmがインポートするオブジェクト
const importObject = {
  env: {
    mem: memory,
    data_addr: data_addr,
    data_count: data_count,
  },
};

(async () => {
  let obj = await WebAssembly.instantiate(new Uint8Array(bytes), importObject); //wasmモジュールのインスタンス化
  for (let i = 0; i < data_i32_index + data_count + 4; i++) {
    //0-27
    let data = mem_i32[i];

    //dataが0以外の場合は赤色で表示
    if (data !== 0) {
      console.log(`data[${i}]=${data}`.red.bold);
    } else {
      console.log(`data[${i}]=${data}`);
    }
  }
})();
