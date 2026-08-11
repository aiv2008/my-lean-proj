/-!
# Proofs：命题、定理与战术

覆盖：`Prop` vs 数据、`theorem` / `example`、战术 `rfl` `rw` `simp` `cases` `induction` `exact`
-/

/-- 命题是 `Prop` 类型；这里是一个可判定的等式命题 -/
def twoPlusTwo : Prop := 2 + 2 = 4

/-- `rfl`：等式两边定义上相等 -/
theorem two_plus_two : 2 + 2 = 4 := by
  rfl

/-- `Nat` 加法在第二个参数上递归，所以 `n + 0 = n` 是定义相等 -/
theorem add_zero (n : Nat) : n + 0 = n := by
  rfl

/-- `0 + n = n` 需要归纳；练 `induction` -/
theorem zero_add (n : Nat) : 0 + n = n := by
  induction n with
  | zero =>
      rfl
  | succ n ih =>
      -- `0 + (n+1) = (0 + n) + 1`，再用归纳假设
      rw [Nat.add_succ, ih]

/-- 自定义列表长度 -/
def myLength {α : Type} : List α → Nat
  | [] => 0
  | _ :: xs => myLength xs + 1

theorem myLength_nil {α : Type} : myLength ([] : List α) = 0 := by
  rfl

theorem myLength_cons {α : Type} (x : α) (xs : List α) :
    myLength (x :: xs) = myLength xs + 1 := by
  rfl

/-- `cases` 拆开 `Option` -/
example (o : Option Nat) : o = none ∨ ∃ n, o = some n := by
  cases o with
  | none =>
      exact Or.inl rfl
  | some n =>
      exact Or.inr ⟨n, rfl⟩

/-- 证明项可以直接当函数用（不写战术） -/
theorem modus_ponens {P Q : Prop} (hPQ : P → Q) (hP : P) : Q :=
  hPQ hP

/-- 战术版：`exact` 填入证明项 -/
theorem modus_ponens_tac {P Q : Prop} (hPQ : P → Q) (hP : P) : Q := by
  exact hPQ hP

/-- `simp`：用简化引理改写目标 -/
theorem add_assoc_example (a b c : Nat) : a + b + c = a + (b + c) := by
  simp [Nat.add_assoc]

#check two_plus_two
#check zero_add
