-- 解法 2：给 NaturalNumber 定义一个和 Nat 等价的 OfNat 实例（书上说需要"更高级的功能"）
def NaturalNumber : Type := Nat

instance (n : Nat) : OfNat NaturalNumber n := ⟨(n : Nat)⟩

def thirtyEight : NaturalNumber := 38

#check thirtyEight
#eval thirtyEight

-- 对比：def 的名字自己不带 OfNat，所以必须显式给实例；abbrev 则不需要
#check (38 : NaturalNumber)
