#!/usr/bin/env python3
import os

def main():
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.normpath(os.path.join(SCRIPT_DIR, "../data"))
    os.makedirs(out_dir, exist_ok=True)
    
    edges_file = os.path.join(out_dir, "airport_trap.edges")
    penalties_file = os.path.join(out_dir, "airport_trap.penalties")
    
    # 模拟一个机场滑行道网络 (Node 0: 停机坪, Node 4: 起飞跑道)
    #               (2)
    #              /   \
    # (0) --- (1)       (4)
    #              \   /
    #               (3)
    #
    # Dijkstra 只看边权重：
    # 0->1(5), 1->2(5), 2->4(5) ---> 距离 15
    # 0->1(5), 1->3(10), 3->4(5) --> 距离 20
    #
    # 物理限制（转弯惩罚）：
    # 途径节点2时，由于是锐角转弯给飞机，惩罚代价非常高 (1000)
    # 途径节点3时，是平滑的滑行道，惩罚代价 (0)
    
    with open(edges_file, 'w') as fe:
        fe.write("# Format: u v base_weight\n")
        fe.write("0 1 5.0\n")
        fe.write("1 2 5.0\n")
        fe.write("2 4 5.0\n")
        fe.write("1 3 10.0\n")
        fe.write("3 4 5.0\n")
        
    with open(penalties_file, 'w') as fp:
        fp.write("# Format: u v w penalty\n")
        # 无惩罚的路径组合
        fp.write("0 1 3 0.0\n")
        fp.write("1 3 4 0.0\n")
        # 高昂的锐角转弯惩罚（陷阱）
        fp.write("0 1 2 0.0\n")       
        fp.write("1 2 4 1000.0\n") # u=1, v=2, w=4 这个拐角禁止/极高惩罚
        
    print(f"✅ 生成机场转弯陷阱数据集成功！")
    print(f"边数据: {edges_file}")
    print(f"惩罚数据: {penalties_file}")

if __name__ == "__main__":
    main()
