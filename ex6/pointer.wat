(module
	(memory 1) ;; 1 ページのメモリを確保
	(global $pointer i32 (i32.const 128)) ;;メモリ位置128をさすグローバル変数

;;$pointer が指すメモリ位置に値 99 を格納する init 関数を定義
	(func $init 
		(i32.store
			(global.get $pointer) ;;pointerの位置に格納
			(i32.const 99) ;;99を格納
		)
	)

;;$pointer が指すメモリ位置の値を返す get_ptr 関数を定義
	(func (export "get_ptr") (result i32)
		(i32.load (global.get $pointer)) 
	)

   
	(start $init)  ;; init関数をモジュールの初期化関数として宣言する
)