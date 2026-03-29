# 迷宫生成系统 - 算法与架构

> 迷宫是游戏的舞台。它需要：可探索性、随机性、分层复杂度、动态元素。

---

## 1. 核心算法：递归回溯 + 房间插入

### 1.1 为什么选择这个算法？

| 算法 | 完美迷宫 | 自然感 | 房间支持 | 性能 | 适用性 |
|------|----------|--------|----------|------|--------|
| 递归回溯 | ✓ | ★★★ | 易添加 | O(N) | ⭐⭐⭐⭐⭐ |
| Prim算法 | ✓ | ★★ | 难添加 | O(N log N) | ★★★ |
| Kruskal | ✓ | ★★★ | 难添加 | O(N α(N)) | ★★★ |
| 细胞自动机 | ✗ | ★★★★ | 自然生成 | O(N) | ★★ |
| 分形 | ✓ | ★★★★★ | 难控制 | O(N log N) | ★★ |

**结论:** 递归回溯最适合我们的需求：
- 生成完美迷宫（必有解）
- 易于理解和实现
- 方便添加房间和特殊区域
- 性能优秀

### 1.2 递归回溯算法详解

```typescript
function recursiveBacktracker(width: number, height: number): Maze {
  // 初始化：全部为墙
  const maze = createGrid(width, height, WALL);
  
  // 从随机点开始
  const startX = random(1, width - 2, 2);  // 奇数位置
  const startY = random(1, height - 2, 2);
  
  const stack: Point[] = [{x: startX, y: startY}];
  maze[startY][startX] = PATH;
  
  while (stack.length > 0) {
    const current = stack[stack.length - 1];
    const neighbors = getUnvisitedNeighbors(current, maze, 2); // 间隔2格
    
    if (neighbors.length > 0) {
      const next = randomChoice(neighbors);
      // 打通墙壁
      const wallX = (current.x + next.x) / 2;
      const wallY = (current.y + next.y) / 2;
      maze[wallY][wallX] = PATH;
      maze[next.y][next.x