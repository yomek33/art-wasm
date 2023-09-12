(module
    (import "env" "str_pos_len" (func $str_pos_len (param i32 i32)))
    (import "env" "buffer" (memory 1))

    (data (i32.const 256) "Know the length of this string")
    (data (i32.const 384) "Also know the length of this string")

    (func (export "main")
        (call $str_pos_len (i32.const 256) (i32.const 30))
        (call $str_pos_len (i32.const 384) (i32.const 35))
    )
)