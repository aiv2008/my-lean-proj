-- 「numerals are polymorphic」到底是什么意思：同一个 38 可以给很多类型用
#check (38 : Nat)
#check (38 : Int)
#check (38 : Float)
#check (38 : UInt8)
#check (38 : Fin 40)        -- 上界由类型给出

-- 自定义类型也能有字面量：给 Vec2 定义 OfNat
structure Vec2 where
  x : Nat
  y : Nat

instance (n : Nat) : OfNat Vec2 n := ⟨n, n⟩

#check (3 : Vec2)
#eval (3 : Vec2)

-- 顺便看看 def 和 abbrev 在 #print 里的区别（abbrev 就是 @[reducible] def）
def NaturalNumber : Type := Nat
abbrev N : Type := Nat
#print NaturalNumber
#print N
