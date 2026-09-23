-- -- <| 运算符实测
-- def inc (n : Nat) : Nat := n + 1
-- def double (n : Nat) : Nat := n * 2
-- def show' (n : Nat) : String := s!"<{n}>"

-- -- 1) head 位置
-- #eval inc <| 5

-- -- 2) 尾随实参：sum 的参数被 |>.map 的结果填满，再 append 给 tail
-- #eval [1, 2, 3] |>.map (· * 10) |>.append <| [7, 8]

-- -- 3) 链式：省掉一堆括号
-- #eval show' <| double <| inc <| double 3
-- #eval show' (double (inc (double 3)))

-- 4) 和 do 块/缩进块配合
def greet : IO Unit :=
  IO.println <| s!"hello {1 + 1}"

-- -- 5) 优先级实验：2^3^2 = 2^(3^2) = 512，如果 <| 插进幂运算里就会变
-- #eval show' <| 2 ^ 3 ^ 2

-- -- 6) 与 |> 混用：<| 是右结合、|> 是左结合
-- #eval show' <| [1, 2, 3] |>.length

def main : IO Unit := greet

-- #eval String.append "A" (String.append "B" "C")
-- #eval String.append (String.append "A" "B") "C"

structure Point where
  x : Float
  y : Float

def origin : Point := {x := 0.0,y:=0.0}
def p1 : Point := {x := 3.0, y:=4.0}

def dist (p1 p2 : Point) := 
  Float.sqrt ((p1.x-p2.x)^2+(p1.y-p2.y)^2)

#eval dist origin p1
