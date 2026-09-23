-- 你这个版本的提示：set_option trace.Meta.synthInstance true —— 看实例搜索为什么失败
def NaturalNumber : Type := Nat

set_option trace.Meta.synthInstance true in
def thirtyEight : NaturalNumber := 38
