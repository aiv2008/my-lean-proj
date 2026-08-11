import MyLeanProject.Data

/-!
# Classes：类型类与实例

覆盖：`class` / `instance`、多态打印、对自定义类型挂实例
-/

/-- 自定义类型类：把值变成可读字符串 -/
class Display (α : Type) where
  display : α → String

export Display (display)

instance : Display Nat where
  display n := s!"Nat({n})"

instance : Display String where
  display s := s!"\"{s}\""

instance : Display Point where
  display p := s!"Point({p.x}, {p.y})"

/-- 依赖类型类约束的函数：`[Display α]` 是实例参数 -/
def shout {α : Type} [Display α] (x : α) : String :=
  ">> " ++ display x

/-- 列表的 `Display`：需要元素也可 `Display` -/
instance {α : Type} [Display α] : Display (List α) where
  display
    | [] => "[]"
    | xs => "[" ++ String.intercalate ", " (xs.map display) ++ "]"

#eval display (7 : Nat)
#eval display Point.origin
#eval shout "lean"
#eval display [Point.origin, ⟨1, 2⟩]
