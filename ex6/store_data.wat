(module
	(import "env" "mem" (memory 1)) ;;線形メモリを組み込み環境からインポート
	(global $data_addr (import "env" "data_addr") i32) ;;JSから読み込んだデータのアドレスをインポート　32
	(global $data_count (import "env" "data_count") i32) ;;JSから読み込んだデータの個数(モジュールの初期化時に格納するi32型の整数値の個数)をインポート

    ;; $indexと$valueを受け取り、$data_addr + $index * 4のアドレスに$valueを格納する関数
    ;; i32は4bytesなので、配列やデータ構造内の要素を格納する場合は、要素間のオフセットを計算するために4をかける
	(func $store_data (param $index i32) (param $value i32);;
		(i32.store
			(i32.add
				(global.get $data_addr) 
				(i32.mul (i32.const 4) (local.get $index)) 
			)
			(local.get $value) 
		)
	)

    ;; ループでデータを初期化する関数
	(func $init
		(local $index i32)
        
        ;;　16回回す
		(loop $data_loop
			local.get $index 
			local.get $index
			i32.const 5
			i32.mul ;;スタックの上から２つの値を取り出し、掛け算を行い、結果をスタックにプッシュ
			call $store_data ;;$store_data関数を呼び出す　パラメータは$index, $index*5

             ;; $index++
			local.get $index 
			i32.const 1
			i32.add
			local.tee $index

			global.get $data_count ;;16

			i32.lt_u ;;index<data_count
			br_if $data_loop
		)
		(call $store_data (i32.const 0) (i32.const 1)) ;;data[8]=1
	)
	(start $init) ;;モジュールの初期化時に$init関数を実行する
)



;; data[0]=0
;; data[1]=0
;; data[2]=0
;; data[3]=0
;; data[4]=0
;; data[5]=0
;; data[6]=0
;; data[7]=0
;; data[8]=1
;; data[9]=5
;; data[10]=10
;; data[11]=15
;; data[12]=20
;; data[13]=25
;; data[14]=30
;; data[15]=35
;; data[16]=40
;; data[17]=45
;; data[18]=50
;; data[19]=55
;; data[20]=60
;; data[21]=65
;; data[22]=70
;; data[23]=75
;; data[24]=0
;; data[25]=0
;; data[26]=0
;; data[27]=0