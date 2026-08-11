/-!
# Basics：定义、函数、模式匹配、Option

覆盖：`def` / `abbrev`、显式与隐式参数、`match`、递归、`Option`、`#check` / `#eval`
-/

/-- 最简单的定义 -/
def hello : String := "Lean"

/-- 类型别名（可展开） -/
abbrev NatPair := Nat × Nat

/-- 显式参数 + 返回类型标注 -/
def add (a b : Nat) : Nat := a + b

/-- 隐式参数：`{α : Type}` 通常由调用处推断 -/
def identity {α : Type} (x : α) : α := x

/-- 模式匹配：阶乘（递归函数） -/
def factorial : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

/-- 安全取列表头；学 `Option` -/
def head? {α : Type} : List α → Option α
  | [] => none
  | x :: _ => some x

/-- 用 `match` 处理 `Option` -/
def headOrDefault {α : Type} (xs : List α) (default : α) : α :=
  match head? xs with
  | some x => x
  | none => default

/-- 管道风格组合（`|>`） -/
def sumFirstThree (xs : List Nat) : Nat :=
  xs.take 3 |>.foldl (· + ·) 0

#check add
#check identity
#eval factorial 5
#eval headOrDefault ([] : List Nat) 42
#eval sumFirstThree [10, 20, 30, 40]
