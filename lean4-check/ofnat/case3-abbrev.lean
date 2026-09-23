-- 解法 3：用 abbrev 而不是 def（abbrev 总是展开的，重载解析能看见 Nat）
abbrev N : Type := Nat

def thirtyNine : N := 39

#check thirtyNine
#eval thirtyNine
