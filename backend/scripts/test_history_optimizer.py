#!/usr/bin/env python3
"""
测试学习助手对话历史优化器
用于验证优化效果和Token节省
"""
import sys
sys.path.append('..')

from app.services.learning_assistant_history_optimizer import ConversationHistoryOptimizer


def test_optimizer():
    """测试优化器功能"""
    
    print("=" * 80)
    print("学习助手对话历史优化器测试")
    print("=" * 80)
    
    # 创建优化器
    optimizer = ConversationHistoryOptimizer(recent_user_questions=5)
    
    # 模拟10轮对话（20条消息）
    mock_messages = []
    
    for i in range(1, 11):
        # 用户问题
        mock_messages.append({
            'role': 'user',
            'content': f'学生第{i}个问题：{"如何使用Python？" if i % 2 == 1 else "ESP32如何烧录固件？"}' + 'x' * 50
        })
        # AI回复（通常更长）
        mock_messages.append({
            'role': 'assistant',
            'content': f'AI回复{i}：' + 'x' * 300
        })
    
    print(f"\n📊 原始对话数据:")
    print(f"   总消息数: {len(mock_messages)}条")
    print(f"   用户问题: {len([m for m in mock_messages if m['role'] == 'user'])}个")
    print(f"   AI回复: {len([m for m in mock_messages if m['role'] == 'assistant'])}个")
    
    # 优化历史
    optimized = optimizer.optimize_history(mock_messages)
    
    print(f"\n✅ 优化后数据:")
    print(f"   保留消息数: {len(optimized)}条")
    print(f"   全部为用户问题")
    
    # 计算Token
    stats = optimizer.get_token_estimate(mock_messages)
    
    print(f"\n💰 Token节省统计:")
    print(f"   原始Token: {stats['original_tokens']}")
    print(f"   优化Token: {stats['optimized_tokens']}")
    print(f"   节省Token: {stats['saved_tokens']}")
    print(f"   节省比例: {stats['save_percentage']}%")
    
    print(f"\n🎯 优化后的消息内容:")
    for i, msg in enumerate(optimized, 1):
        content_preview = msg['content'][:50] + '...' if len(msg['content']) > 50 else msg['content']
        print(f"   [{i}] {content_preview}")
    
    print("\n" + "=" * 80)
    print("✅ 测试完成！")
    print("=" * 80)


def test_different_configs():
    """测试不同配置的效果"""
    
    print("\n" + "=" * 80)
    print("不同配置对比测试")
    print("=" * 80)
    
    # 模拟20轮对话
    mock_messages = []
    for i in range(1, 21):
        mock_messages.append({'role': 'user', 'content': 'x' * 80})
        mock_messages.append({'role': 'assistant', 'content': 'x' * 300})
    
    configs = [3, 5, 8, 10]
    
    print(f"\n对话总量: {len(mock_messages)}条消息（{len(mock_messages)//2}轮对话）\n")
    print(f"{'配置':<10} {'优化后':<10} {'原始Token':<15} {'优化Token':<15} {'节省比例'}")
    print("-" * 80)
    
    for config in configs:
        optimizer = ConversationHistoryOptimizer(recent_user_questions=config)
        stats = optimizer.get_token_estimate(mock_messages)
        
        print(f"{config}个问题   {stats['optimized_count']}条       "
              f"{stats['original_tokens']:<15} {stats['optimized_tokens']:<15} "
              f"{stats['save_percentage']}%")
    
    print("\n💡 建议: ")
    print("   - 如果学生多为独立问题 → 选择3个问题（最省Token）")
    print("   - 如果需要平衡记忆和成本 → 选择5个问题（推荐）")
    print("   - 如果需要更长的问题脉络 → 选择8个问题")


if __name__ == "__main__":
    test_optimizer()
    test_different_configs()

