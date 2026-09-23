-- 解法 1：在右边注明是 Nat（因为 NaturalNumber 与 Nat 按定义相等）
def NaturalNumber : Type := Nat

def thirtyEight : NaturalNumber := (38 : Nat)

-- 证明「按定义相等」：rfl 能过，说明两者是同一个类型
example : NaturalNumber = Nat := rfl

#check thirtyEight
#eval thirtyEight
