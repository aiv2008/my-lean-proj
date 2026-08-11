# MyLeanProject

比 Hello World 稍完整的 Lean 4 小教程项目（仅依赖标准库，无需 Mathlib）。

工具链：Lean 4.31.0（见 `lean-toolchain`）。

## 运行

```bash
cd my-lean-project
lake build
lake exe myleanproject
```

预期输出大致为：

```text
=== MyLeanProject mini tour ===
hello = Lean
factorial 5 = 120
Point.add = { x := 4, y := 6 }
expr = (2 + (3 * 4))
eval  = 14
display list = [Point(0, 0), Point(1, 2)]
zero_add 7 : checked
done.
```

## 项目结构

```text
my-lean-project/
├── lakefile.toml          # Lake 包配置（库 + 可执行文件）
├── lean-toolchain         # Lean 版本锁定
├── Main.lean              # 可执行入口（IO / do）
├── MyLeanProject.lean     # 库根：汇总 import
└── MyLeanProject/
    ├── Basic.lean         # 定义、函数、Option
    ├── Data.lean          # 结构体、归纳类型
    ├── Proofs.lean        # 定理与战术
    └── Classes.lean       # 类型类
```

建议阅读顺序：`Basic` → `Data` → `Proofs` → `Classes` → `Main`。

## 知识点地图

| 文件 | 覆盖内容 |
|------|----------|
| `Basic.lean` | `def` / `abbrev`、显式与隐式参数、`match`、递归、`Option`、`#check` / `#eval` |
| `Data.lean` | `structure`、`inductive`、`namespace`、`section` / `variable`、`deriving` |
| `Proofs.lean` | `Prop`、`theorem` / `example`、战术 `rfl` / `rw` / `simp` / `cases` / `induction` / `exact` |
| `Classes.lean` | `class` / `instance`、实例参数 `[Display α]` |
| `Main.lean` | `IO`、`do` 记法、可执行入口 |

## 各模块说明

### 1. Basic — 定义与函数

- `def`：绑定值或函数
- `abbrev`：可展开的类型别名（如 `NatPair`）
- `{α : Type}`：隐式参数，通常由调用处推断
- `match` / 方程编译：模式匹配与递归（如 `factorial`、`head?`）
- `Option`：用 `some` / `none` 表示可能失败的结果
- `#check` / `#eval`：在编辑器里查看类型与求值结果

### 2. Data — 数据建模

- `structure Point`：命名字段；可用 `⟨x, y⟩` 或 `{ x := ..., y := ... }` 构造
- `deriving Repr, BEq`：自动生成打印、相等比较相关实例
- `inductive Expr`：迷你算术表达式（`const` / `add` / `mul`）
- `namespace`：把相关定义收进同一命名空间（如 `Point.add`、`Expr.eval`）
- `section` + `variable`：在作用域内共享参数（如 `scaled`）

### 3. Proofs — 命题与证明

- `Prop`：命题类型；`theorem` 给出证明
- `rfl`：两边定义上相等时直接成立（如 `n + 0 = n`）
- `induction`：对 `Nat` 等归纳类型做归纳（如 `0 + n = n`）
- `rw`：按等式改写目标
- `cases`：按构造器分情况（如拆开 `Option`）
- `exact`：直接填入证明项
- `simp`：用简化引理改写（如 `Nat.add_assoc`）
- 也可不写战术，直接写证明项：`hPQ hP`

### 4. Classes — 类型类

- `class Display`：定义接口
- `instance`：为具体类型实现接口（`Nat`、`String`、`Point`、`List α`）
- `[Display α]`：实例参数，由类型类解析自动寻找
- `export Display (display)`：把字段名导出到当前命名空间，便于直接写 `display x`

### 5. Main — 可执行程序

- `def main : IO Unit`：程序入口
- `do` 记法：顺序执行多个 `IO` 动作
- `IO.println` / 字符串插值 `s!"..."`：打印演示结果
- 证明在编译期检查（如 `let _ := zero_add 7`）

## 常见命令

| 命令 | 作用 |
|------|------|
| `lake build` | 编译库与可执行文件 |
| `lake exe myleanproject` | 运行入口程序 |
| `lake clean` | 清理构建产物 |

在 VS Code / Cursor 中安装 **Lean 4** 扩展后，打开 `.lean` 文件即可看到 `#check` / `#eval` 的信息与证明目标。
