(module
;; JSで定義したimportObjectをインポート
(global $cnvs_size (import "env" "cnvs_size") i32)
(global $no_hit_color (import "env" "no_hit_color") i32)
(global $hit_color (import "env" "hit_color") i32)
(global $obj_start (import "env" "obj_start") i32)
(global $obj_size (import "env" "obj_size") i32)
(global $obj_cnt (import "env" "obj_cnt") i32)
(global $x_offset (import "env" "x_offset") i32)
(global $y_offset (import "env" "y_offset") i32)
(global $xv_offset (import "env" "xv_offset") i32)
(global $yv_offset (import "env" "yv_offset") i32) 
(import "env" "buffer" (memory 80)) 

;; キャンパス全体をクリアする関数
;; フレームをレンダリングする旅にキャンパスをクリアする必要がある
;; 各オブジェクトの痕跡がメモリバッファに残ってしまうため
(func $clear_canvas 
    (local $i i32) ;; ループカウンタ
    (local $pixel_bytes i32) ;; キャンパスの全ピクセルの合計バイト数

    global.get $cnvs_size
    global.get $cnvs_size
    i32.mul ;; $cnvs_size * $cnvs_size キャンバスの総ピクセル数

    i32.const 4 ;; 4バイトのピクセル
    i32.mul
    local.set $pixel_bytes ;; $pixel_bytes = $cnvs_size * $cnvs_size * 4

    ;; 各ピクセルをループで処理
    (loop $pixel_loop
        (i32.store (local.get $i) (i32.const 0xff_00_00_00)) ;;0xff_00_00_00(黒)を格納

        (i32.add (local.get $i) (i32.const 4));; 次のピクセルのアドレスに移動
        local.set $i  ;; $i += 4

        (i32.lt_u (local.get $i) (local.get $pixel_bytes)) ;;$i < $pixel_bytes の場合はループを続ける
        br_if $pixel_loop 
    )
)

;; 絶対値を返す関数
;; オブジェクトが正方形なので、衝突検出における距離を計算するのに使う
(func $abs 
    (param $value i32) 
    (result i32)

    (i32.lt_s (local.get $value) (i32.const 0)) ;; $value < 0
    if ;; if $value < 0 正の値に変換
        i32.const 0
        local.get $value
        i32.sub
        return
    end
    local.get $value
)


;;座標＄x, $yのピクセルをカラーコード＄cでセットする関数
;;p.174, 175　x, y座標の線形メモリアドレスは $y * 4 + $x
(func $set_pixel
    (param $x i32) ;;x座標
    (param $y i32) ;;y座標
    (param $c i32) ;;カラーコード

;; ピクセルがキャンパスの範囲内にあるかどうかをチェック
    (i32.ge_u (local.get $x) (global.get $cnvs_size)) 
    if 
        return
    end

    (i32.ge_u (local.get $y) (global.get $cnvs_size)) 
    if 
        return
    end

;;$y *  $cnvs_size * 4 + $x
;;$y * $cnvs_size はメモリ内の開始位置
    local.get $y
    global.get $cnvs_size
    i32.mul
    local.get $x
    i32.add 
    i32.const 4
    i32.mul

;;$cをメモリに格納
    local.get $c
    i32.store
)


;; 4*4のオブジェクトを描画する関数
(func $draw_obj 
    (param $x i32) ;; x座標
    (param $y i32) ;; y座標
    (param $c i32) ;; カラーコード

    (local $max_x i32)
    (local $max_y i32)

    (local $xi i32)
    (local $yi i32)

;; 開始x座標に4ピクセルを加えて最大x座標を計算
    local.get $x
    local.tee $xi ;; スタックのトップにある値を取得し、$xiに格納
    global.get $obj_size ;;4
    i32.add
    local.set $max_x

;; 開始y座標に4ピクセルを加えて最大y座標を計算
    local.get $y
    local.tee $yi
    global.get $obj_size
    i32.add
    local.set $max_y

    (block $break (loop $draw_loop 
        ;; $xi, $yiにあるピクセルを$cでセット
        local.get $xi
        local.get $yi
        local.get $c
        call $set_pixel

        ;; $xi++
        local.get $xi
        i32.const 1
        i32.add
        local.tee $xi

        ;; $xi >= $max_xかどうか
        local.get $max_x
        i32.ge_u 

        ;; x座標がmax_xに達したら,
        ;; x座標を開始位置に戻してy座標をインクリメント
        if
            ;; x座標を開始位置に戻す
            local.get $x
            local.set $xi

            ;; $y++
            local.get $yi
            i32.const 1
            i32.add
            local.tee $yi 

            ;; $yi >= $max_yならば終了
            local.get $max_y
            i32.ge_u
            br_if $break
        end
        br $draw_loop
    ))
)

;; オブジェクト番号、属性オフセット、属性の値に基づいて
;; 線形メモリ内のオブジェクトの属性を設定
(func $set_obj_attr
    (param $obj_number i32) ;; オブジェクト番号
    (param $attr_offset i32) ;; 属性オフセット
    (param $value i32) ;; 属性の値

    ;; $obj_number * 16
    ;; オブジェクトのメモリ内のオフセットを計算
    local.get $obj_number
    i32.const 16
    i32.mul

    ;; $obj_startと$attr_offsetを加算してメモリ位置を計算
    global.get $obj_start
    i32.add
    local.get $attr_offset
    i32.add

    ;; 属性の値をメモリに格納
    local.get $value
    i32.store 
)


;; オブジェクト番号、属性オフセットに基づいて
;; 線形メモリ内のオブジェクトの属性を取得
(func $get_obj_attr
    (param $obj_number i32)
    (param $attr_offset i32)

    (result i32)

    ;;オブジェクトのメモリ内のオフセットを計算
    ;;$obj_number * 16(ストライド値)
    local.get $obj_number
    i32.const 16
    i32.mul 

    ;; ($obj_number * 16) + $obj_start + $attr_offset
    global.get $obj_start
    i32.add 
    local.get $attr_offset
    i32.add 

    ;;このメモリから属性の値を取得
    i32.load 
)

;; メイン関数
;; JSから呼び出される
(func $main (export "main")

    ;; ループカウンタ
    (local $i i32) 
    (local $j i32)

    ;;ループのオブジェクトへのポインタ
    (local $outer_ptr i32)
    (local $inner_ptr i32)

    (local $x1 i32) 
    (local $x2 i32)
    (local $y1 i32)
    (local $y2 i32)

    ;;２つのオブジェクトのx, y座標の距離
    (local $xdist i32) 
    (local $ydist i32)

    ;;衝突したら1、しなかったら0
    (local $i_hit i32) 

    ;;x, yの速度
    (local $xv i32
    (local $yv i32)

    ;; キャンパスをクリア
    (call $clear_canvas) 


    ;; 各オブジェクトの位置を更新をする
    (loop $move_loop
    ;; $iオブジェクトの$x, $y, $xv, $yv属性を取得
        ;; x属性を取得
        (call $get_obj_attr (local.get $i) (global.get $x_offset)) ;; js: const x_offset = 0;
        local.set $x1

        ;; y属性を取得
        (call $get_obj_attr (local.get $i) (global.get $y_offset))  ;; js: const y_offset = 4;
        local.set $y1

        ;; xの速度属性を取得
        (call $get_obj_attr (local.get $i) (global.get $xv_offset)) 
        local.set $xv

        ;; yの速度属性を取得
        (call $get_obj_attr (local.get $i) (global.get $yv_offset)) 
        local.set $yv


        ;; xに速度を加算して、キャンパス内にとどまらせる
        (i32.add (local.get $xv) (local.get $x1))
        i32.const 0x1ff ;; 0x1ff = 511
        i32.and 
        local.set $x1

        ;; yに速度を加算して、キャンパス内にとどまらせる
        (i32.add (local.get $yv) (local.get $y1))
        i32.const 0x1ff
        i32.and 
        local.set $y1
        

        ;;新しいx座標をオブジェクト$iのx座標属性として設定
        (call $set_obj_attr 
            (local.get $i) 
            (global.get $x_offset)
            (local.get $x1)
        )

        ;; 新しいy座標をオブジェクト$iのy座標属性として設定
        (call $set_obj_attr 
            (local.get $i) 
            (global.get $y_offset)
            (local.get $y1)
        )

        
        local.get $i
        i32.const 1
        i32.add
        local.tee $i ;;$i++
        
        ;;$i < $obj_cntならばループを続ける、そうでなければループを抜ける
        global.get $obj_cnt
        i32.lt_u 
        if 
        br $move_loop
    end
    )
    
    ;; 次のループのために$iを0にリセット
    i32.const 0
    local.set $i
    ;;各オブジェクトに対して他のオブジェクトとの衝突をチェック
    ;;全てのオブジェクトのペアに対して衝突をチェックするために2つのループを使用
    (loop $outer_loop (block $outer_break
        ;;$jを0に設定
        i32.const 0
        local.tee $j

        local.set $i_hit ;;ブールフラグ。まずは0(衝突していない)に設定

        ;; オブジェクト$iのx属性を取得
        (call $get_obj_attr (local.get $i) (global.get $x_offset))
        local.set $x1
        ;; オブジェクト$iのy属性を取得
        (call $get_obj_attr (local.get $i) (global.get $y_offset))
        local.set $y1

        ;;2つのオブジェクトの衝突を検出するためのループ
        (loop $inner_loop (block $inner_break
            local.get $i
            local.get $j

            i32.eq
             ;; $i == $jは自己衝突なのでNG
            ;; $i == $jならば$jをインクリメントして次のオブジェクトに移動
            if 
                local.get $j
                i32.const 1
                i32.add
                local.set $j
            end

            ;; $j >= $obj_cntならば内側のループを抜ける
            local.get $j
            global.get $obj_cnt
            i32.ge_u
            if
                br $inner_break
            end

            ;;$jのx属性を取得して$x2に格納
            (call $get_obj_attr (local.get $j)(global.get $x_offset)) 
            local.set $x2 
            ;;$i, $jのx座標の距離を計算し、absで絶対値を取得したものを$xdistに格納
            (i32.sub (local.get $x1) (local.get $x2))
            call $abs 
            local.tee $xdist

            ;;$xdist >= $obj_sizeならば$jをインクリメントして次のオブジェクトに移動
            global.get $obj_size
            i32.ge_u 
            if 
                local.get $j
                i32.const 1
                i32.add
                local.set $j
                br $inner_loop
            end


            ;; $jのy属性を取得して$y2に格納、その絶対値を$ydistに格納
            (call $get_obj_attr (local.get $j)(global.get $y_offset))
            local.set $y2
            (i32.sub (local.get $y1) (local.get $y2))
            call $abs
            local.tee $ydist

            ;; $ydist >= $obj_sizeならば$jをインクリメントして次のオブジェクトに移動
            global.get $obj_size
            i32.ge_u 
            if
                local.get $j
                i32.const 1
                i32.add
                local.set $j
                br $inner_loop
            end

            ;; ここまででループの先頭に戻っていないならば、衝突している
            ;; 衝突フラグを1に設定
            i32.const 1
            local.set $i_hit
        ))

        local.get $i_hit
        i32.const 0
        i32.eq
        ;; if $i_hit == 0 (no hit) 衝突していない
        if
            (call $draw_obj
            (local.get $x1) (local.get $y1) (global.get $no_hit_color)) ;;$x1, $y1の位置にno_hit_colorを描画

        ;; if $i_hit == 1 (hit) 衝突した
        else 
            (call $draw_obj
            (local.get $x1) (local.get $y1) (global.get $hit_color)) ;;$x1, $y1の位置にhit_colorを描画
        end

        local.get $i
        i32.const 1
        i32.add
        local.tee $i ;;$i++

        ;; $i < $obj_cntならば外側のループに戻る
        global.get $obj_cnt
        i32.lt_u
        if
            br $outer_loop
        end
        )) 
     ) 
)