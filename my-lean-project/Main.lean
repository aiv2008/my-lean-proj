import MyLeanProject

/-!
可执行入口：练 `IO` 与 `do` 记法。
运行：`lake exe myleanproject`
-/


def demoExpr : Expr :=
  .add (.const 2) (.mul (.const 3) (.const 4))
  

def main : IO Unit := do  
  IO.println "=== MyLeanProject mini tour ==="
  IO.println s!"hello = {hello}"
  IO.println s!"factorial 5 = {factorial 5}"
  IO.println s!"Point.add = {repr (Point.add ⟨1, 2⟩ ⟨3, 4⟩)}"
  IO.println s!"expr = {demoExpr.toString}"
  IO.println s!"eval  = {demoExpr.eval}"
  IO.println s!"display list = {display [Point.origin, ⟨1, 2⟩]}"
  -- 证明在编译期检查；这里只是引用一下，确保链接进可执行文件
  let _ : 0 + 7 = 7 := zero_add 7
  IO.println "zero_add 7 : checked"
  IO.println "done."
