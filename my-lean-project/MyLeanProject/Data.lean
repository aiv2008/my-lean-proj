/-!
# Data：结构体、归纳类型、命名空间

覆盖：`structure`、`inductive`、`namespace`、`section` / `variable`、`deriving`
-/

/-- 结构体：命名字段 + 自动生成构造器 `Point.mk` -/
structure Point where
  x : Int
  y : Int
  deriving Repr, BEq

namespace Point

def origin : Point := ⟨0, 0⟩

def add (p q : Point) : Point :=
  { x := p.x + q.x, y := p.y + q.y }

def manhattan (p : Point) : Nat :=
  p.x.natAbs + p.y.natAbs

end Point

/-- 归纳类型：迷你算术表达式 -/
inductive Expr where
  | const : Int → Expr
  | add  : Expr → Expr → Expr
  | mul   : Expr → Expr → Expr
  deriving Repr

namespace Expr

/-- 结构递归：对每个构造器写一个分支 -/
def eval : Expr → Int
  | const n => n
  | add a b => a.eval + b.eval
  | mul a b => a.eval * b.eval

/-- 把表达式“打印”成字符串（再练一遍 match） -/
def toString : Expr → String
  | const n => s!"{n}"
  | add a b => s!"({a.toString} + {b.toString})"
  | mul a b => s!"({a.toString} * {b.toString})"

end Expr

-- `section` + `variable`：在作用域内共享参数
section Config
  variable (scale : Nat)

  def scaled (n : Nat) : Nat := n * scale
end Config

#eval scaled 3 10  -- 第一个参数是 section 里的 scale

#eval Point.origin
#eval Point.add ⟨1, 2⟩ ⟨3, 4⟩
#eval Expr.eval (.add (.const 2) (.mul (.const 3) (.const 4)))
