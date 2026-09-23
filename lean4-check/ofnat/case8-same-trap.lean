-- 同一个坑还会出现在别的「类型类记法」上：不是字面量的问题，是实例搜索不展开 def
def NaturalNumber : Type := Nat
abbrev N : Type := Nat

section
-- 用 def 的名字：+ 也找不到实例（HAdd 和 OfNat 一样是类型类）
#check (fun (x y : NaturalNumber) => x + y)
end

section
-- 用 abbrev 的名字：一切照旧
#check (fun (x y : N) => x + y)
#check (fun (x y : N) => x ≤ y)
end

-- 但注意：def 名字在「按定义相等」的层面仍然就是 Nat，所以类型标注一给就通
example : NaturalNumber = Nat := rfl
example (x : NaturalNumber) : x = (x : Nat) := rfl
