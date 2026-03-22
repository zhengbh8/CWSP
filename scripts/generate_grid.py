#!/usr/bin/env python3
import os
import argparse
import random

def get_direction(r1, c1, r2, c2):
    """
    返回方向:
    0: 上 (North)
    1: 右 (East)
    2: 下 (South)
    3: 左 (West)
    """
    if r2 == r1 - 1 and c2 == c1: return 0
    if r2 == r1 and c2 == c1 + 1: return 1
    if r2 == r1 + 1 and c2 == c1: return 2
    if r2 == r1 and c2 == c1 - 1: return 3
    return -1

def main():
    parser = argparse.ArgumentParser(description="生成带有转弯惩罚的 NxN 定制网格数据集")
    parser.add_argument("-N", type=int, default=5, help="网格大小 N (默认: 5)")
    parser.add_argument("--out-dir", type=str, default="../data", help="数据保存目录")
    parser.add_argument("--seed", type=int, default=42, help="随机种子")
    
    args = parser.parse_args()
    N = args.N
    random.seed(args.seed)
    
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    # 处理相对路径问题，确保写入到正确的 data 目录
    out_dir = os.path.normpath(os.path.join(SCRIPT_DIR, args.out_dir))
    os.makedirs(out_dir, exist_ok=True)
    
    edges_file = os.path.join(out_dir, f"grid_{N}x{N}.edges")
    penalties_file = os.path.join(out_dir, f"grid_{N}x{N}.penalties")
    
    # 动态参数配置 (可根据实验需要扩展)
    BASE_WEIGHT_MIN = 1
    BASE_WEIGHT_MAX = 5
    
    # 转弯惩罚 (Penalties)
    PENALTY_STRAIGHT = 0    # 直行代价
    PENALTY_RIGHT = 2       # 右转代价
    PENALTY_LEFT = 5        # 左转代价 (通常左转更耗时)
    PENALTY_UTURN = 100     # 掉头代价 (相当于禁止或极高惩罚)
    
    edges = []
    
    # 1. 生成节点与边
    # 节点编号: node_id = r * N + c
    with open(edges_file, 'w') as fe:
        fe.write(f"# N={N}, Total Nodes={N*N}\n")
        fe.write("# Format: u v base_weight\n")
        for r in range(N):
            for c in range(N):
                u = r * N + c
                # 遍历四个可能的邻居
                neighbors = [
                    (r-1, c), # 上
                    (r, c+1), # 右
                    (r+1, c), # 下
                    (r, c-1)  # 左
                ]
                for nr, nc in neighbors:
                    if 0 <= nr < N and 0 <= nc < N:
                        v = nr * N + nc
                        weight = random.randint(BASE_WEIGHT_MIN, BASE_WEIGHT_MAX)
                        edges.append((u, v, r, c, nr, nc))
                        fe.write(f"{u} {v} {weight}\n")
                        
    # 2. 生成转弯惩罚 (1-加性代价：表示为三元组 u -> v -> w)
    with open(penalties_file, 'w') as fp:
        fp.write("# Format: u v w penalty\n")
        # 寻找所有长度为2的路径 (u -> v -> w)
        for u, v, u_r, u_c, v_r, v_c in edges:
            for v2, w, v_r2, v_c2, w_r, w_c in edges:
                if v == v2: # 路径连通
                    dir_in = get_direction(u_r, u_c, v_r, v_c)
                    dir_out = get_direction(v_r, v_c, w_r, w_c)
                    
                    # 计算转向变化
                    diff = (dir_out - dir_in) % 4
                    
                    if diff == 0:
                        penalty = PENALTY_STRAIGHT
                    elif diff == 1:
                        penalty = PENALTY_RIGHT
                    elif diff == 2:
                        penalty = PENALTY_UTURN
                    elif diff == 3:
                        penalty = PENALTY_LEFT
                    else:
                        penalty = 0
                        
                    fp.write(f"{u} {v} {w} {penalty}\n")

    print(f"✅ 成功生成 {N}x{N} 带有转弯惩罚的网格数据集！")
    print(f"📁 基础边文件: {edges_file}")
    print(f"📁 转弯惩罚文件: {penalties_file}")

if __name__ == "__main__":
    main()
